/*
**  RingDotNet bridge - the managed side of the RingDotNet extension.
**
**  The native extension (ring_dotnet.dll) hosts the runtime and calls Bridge.Invoke with one
**  request. A request/response is a sequence of "items":   <tag><byte length>:<data>
**
**      s  string (UTF-8 bytes)         n  number (invariant decimal text)
**      b  boolean ("1" or "0")         z  null (length 0)
**      o  object handle (decimal id)   l  list (data = nested items)
**      e  error (message, response only)
**
**  A request is:  s<operation> item item ...      A response is exactly one item.
**  Objects never cross the boundary: .NET objects live in a handle table and Ring holds the ids.
*/

using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq.Expressions;
using System.Runtime.CompilerServices;
using System.Threading;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;

namespace RingDotNet
{
	/* A handle to a type: members are then looked up as static members */
	internal sealed class TypeRef
	{
		public Type Type;
		public TypeRef(Type t) { Type = t; }
	}

	/* A Ring function that .NET code can call back (arrives as item tag 'c') */
	internal sealed class CallbackRef
	{
		public string Name;
		public CallbackRef(string name) { Name = name; }
	}

	public static unsafe class Bridge
	{
		/* Native function that runs a Ring callback: (request, size, out buffer, capacity) -> result size;
		   called with request = NULL it copies the result that did not fit */
		private static delegate* unmanaged<byte*, int, byte*, int, int> NativeCallback;
		private static int Depth;
		private static int RingThread;

		private static readonly Dictionary<long, object> Handles = new Dictionary<long, object>();
		private static readonly object Sync = new object();
		private static long NextHandle = 1;
		private static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

		/* ---------------------------------------------------------------- native entry points */

		[UnmanagedCallersOnly]
		public static byte* Invoke(byte* request, int length, int* outLength)
		{
			byte[] response;
			bool outer = Depth == 0;
			if (outer)
			{
				RingThread = Environment.CurrentManagedThreadId;
			}
			Depth++;
			try
			{
				List<object> items = Decode(new ReadOnlySpan<byte>(request, length));
				object result;
				lock (Sync)
				{
					result = Dispatch(items);
				}
				response = EncodeToBytes(result);
			}
			catch (Exception ex)
			{
				response = EncodeError(Unwrap(ex));
			}
			finally
			{
				Depth--;
			}
			byte* buffer = (byte*)NativeMemory.Alloc((nuint)Math.Max(response.Length, 1));
			response.AsSpan().CopyTo(new Span<byte>(buffer, response.Length));
			*outLength = response.Length;
			return buffer;
		}

		[UnmanagedCallersOnly]
		public static void SetCallback(IntPtr function)
		{
			NativeCallback = (delegate* unmanaged<byte*, int, byte*, int, int>)function;
		}

		[UnmanagedCallersOnly]
		public static void Free(byte* buffer)
		{
			NativeMemory.Free(buffer);
		}

		/* ---------------------------------------------------------------- wire format */

		private static List<object> Decode(ReadOnlySpan<byte> data)
		{
			List<object> items = new List<object>();
			int pos = 0;
			while (pos < data.Length)
			{
				char tag = (char)data[pos++];
				int len = 0;
				while (pos < data.Length && data[pos] != (byte)':')
				{
					len = len * 10 + (data[pos++] - (byte)'0');
				}
				pos++; /* skip ':' */
				if (pos + len > data.Length)
				{
					throw new ArgumentException("Malformed request");
				}
				ReadOnlySpan<byte> body = data.Slice(pos, len);
				pos += len;
				switch (tag)
				{
					case 's': items.Add(Encoding.UTF8.GetString(body)); break;
					case 'n': items.Add(double.Parse(Encoding.ASCII.GetString(body), NumberStyles.Float, Inv)); break;
					case 'b': items.Add(body.Length > 0 && body[0] == (byte)'1'); break;
					case 'z': items.Add(null); break;
					case 'o': items.Add(Lookup(long.Parse(Encoding.ASCII.GetString(body), Inv))); break;
					case 'l': items.Add(Decode(body).ToArray()); break;
					case 'c': items.Add(new CallbackRef(Encoding.UTF8.GetString(body))); break;
					case 'e': throw new InvalidOperationException("Ring error: " + Encoding.UTF8.GetString(body));
					default: throw new ArgumentException("Unknown item tag '" + tag + "'");
				}
			}
			return items;
		}

		private static void WriteItem(MemoryStream ms, char tag, byte[] body)
		{
			ms.WriteByte((byte)tag);
			byte[] len = Encoding.ASCII.GetBytes(body.Length.ToString(Inv));
			ms.Write(len, 0, len.Length);
			ms.WriteByte((byte)':');
			ms.Write(body, 0, body.Length);
		}

		private static void Encode(MemoryStream ms, object value)
		{
			switch (value)
			{
				case null: WriteItem(ms, 'z', Array.Empty<byte>()); return;
				case string s: WriteItem(ms, 's', Encoding.UTF8.GetBytes(s)); return;
				case char c: WriteItem(ms, 's', Encoding.UTF8.GetBytes(c.ToString())); return;
				case bool b: WriteItem(ms, 'b', new[] { (byte)(b ? '1' : '0') }); return;
				case byte[] raw: WriteItem(ms, 's', raw); return;
				case Enum e: WriteItem(ms, 'n', Encoding.ASCII.GetBytes(Convert.ToInt64(e, Inv).ToString(Inv))); return;
				case decimal m: WriteItem(ms, 'n', Encoding.ASCII.GetBytes(((double)m).ToString("R", Inv))); return;
				case double d: WriteItem(ms, 'n', Encoding.ASCII.GetBytes(d.ToString("R", Inv))); return;
				case float f: WriteItem(ms, 'n', Encoding.ASCII.GetBytes(((double)f).ToString("R", Inv))); return;
				case sbyte or byte or short or ushort or int or uint or long or ulong:
					WriteItem(ms, 'n', Encoding.ASCII.GetBytes(Convert.ToString(value, Inv))); return;
				case List<object> list:
					{
						MemoryStream inner = new MemoryStream();
						foreach (object item in list) { Encode(inner, item); }
						WriteItem(ms, 'l', inner.ToArray());
						return;
					}
				default:
					WriteItem(ms, 'o', Encoding.ASCII.GetBytes(Register(value).ToString(Inv)));
					return;
			}
		}

		private static byte[] EncodeToBytes(object value)
		{
			MemoryStream ms = new MemoryStream();
			Encode(ms, value);
			return ms.ToArray();
		}

		private static byte[] EncodeError(Exception ex)
		{
			MemoryStream ms = new MemoryStream();
			WriteItem(ms, 'e', Encoding.UTF8.GetBytes(ex.GetType().FullName + ": " + ex.Message));
			return ms.ToArray();
		}

		private static Exception Unwrap(Exception ex)
		{
			while (ex is TargetInvocationException && ex.InnerException != null)
			{
				ex = ex.InnerException;
			}
			return ex;
		}

		/* ---------------------------------------------------------------- handle table */

		private static long Register(object value)
		{
			long id = NextHandle++;
			Handles[id] = value;
			return id;
		}

		private static object Lookup(long id)
		{
			if (!Handles.TryGetValue(id, out object value))
			{
				throw new ArgumentException("Invalid or released .NET object handle: " + id);
			}
			return value;
		}

		/* ---------------------------------------------------------------- operations */

		private static object Dispatch(List<object> items)
		{
			if (items.Count == 0 || !(items[0] is string op))
			{
				throw new ArgumentException("Missing operation");
			}
			object[] a = items.GetRange(1, items.Count - 1).ToArray();
			switch (op)
			{
				case "version":
					return RuntimeInformation.FrameworkDescription;
				case "load":
					return Assembly.LoadFrom(Str(a, 0)).FullName;
				case "loadname":
					return Assembly.Load(Str(a, 0)).FullName;
				case "type":
					return new TypeRef(ResolveType(Str(a, 0)));
				case "new":
					return CreateInstance(TypeOf(a, 0), Rest(a, 1));
				case "call":
					return CallMethod(a[0], Str(a, 1), Rest(a, 2));
				case "get":
					return GetMember(a[0], Str(a, 1));
				case "set":
					SetMember(a[0], Str(a, 1), a[2]);
					return null;
				case "release":
					Handles.Remove(Convert.ToInt64(a[0] is double d ? d : 0, Inv));
					return null;
				case "tostring":
					return Plain(a[0]).ToString();
				case "typename":
					return a[0] is TypeRef tr ? tr.Type.FullName : a[0]?.GetType().FullName;
				case "tolist":
					return ToList(a[0]);
				case "setevent":
					SetEvent(a[0], Str(a, 1), a[2]);
					return null;
				case "clearevent":
					SetEvent(a[0], Str(a, 1), null);
					return null;
				case "describe":
					return Describe(TypeOf(a, 0));
				case "isnull":
					return a[0] == null;
				default:
					throw new ArgumentException("Unknown operation: " + op);
			}
		}

		private static string Str(object[] a, int i)
		{
			if (i >= a.Length || !(a[i] is string s))
			{
				throw new ArgumentException("Expected a string parameter at position " + (i + 1));
			}
			return s;
		}

		private static object[] Rest(object[] a, int from)
		{
			object[] r = new object[Math.Max(a.Length - from, 0)];
			Array.Copy(a, from, r, 0, r.Length);
			return r;
		}

		/* A TypeRef travels as the Type when it is used as a plain value */
		private static object Plain(object v)
		{
			return v is TypeRef tr ? tr.Type : v;
		}

		private static Type TypeOf(object[] a, int i)
		{
			if (i < a.Length && a[i] is TypeRef tr)
			{
				return tr.Type;
			}
			if (i < a.Length && a[i] is string name)
			{
				return ResolveType(name);
			}
			throw new ArgumentException("Expected a type at position " + (i + 1));
		}

		/* Find a type by name, loading the framework assembly named by the namespace when needed */
		private static Type ResolveType(string name)
		{
			Type t = ResolveSimple(name);
			if (t == null && name.IndexOfAny(new[] { '`', '[' }) > 0)
			{
				/* Closed generic types (List`1[[System.String]]): resolve each part with ResolveSimple */
				try
				{
					t = Type.GetType(name, null, (asm, n, ic) => asm != null ? asm.GetType(n, false, ic) : ResolveSimple(n));
				}
				catch (Exception) { }
			}
			if (t == null)
			{
				throw new TypeLoadException("Can't find the .NET type: " + name);
			}
			return t;
		}

		/* Find a type by name, loading the framework assembly named by the namespace when needed */
		private static Type ResolveSimple(string name)
		{
			Type t = null;
			try { t = Type.GetType(name, false); } catch (Exception) { }
			if (t != null)
			{
				return t;
			}
			foreach (Assembly asm in AppDomain.CurrentDomain.GetAssemblies())
			{
				t = asm.GetType(name, false);
				if (t != null)
				{
					return t;
				}
			}
			/* System.Console -> try the assemblies System.Console, System (type forwarders included) */
			int generic = name.IndexOfAny(new[] { '`', '[' });
			string prefix = generic > 0 ? name.Substring(0, generic) : name;
			int dot;
			do
			{
				try
				{
					Assembly asm = Assembly.Load(prefix);
					t = asm.GetType(name, false);
					if (t != null)
					{
						return t;
					}
				}
				catch (Exception) { }
				dot = prefix.LastIndexOf('.');
				if (dot > 0)
				{
					prefix = prefix.Substring(0, dot);
				}
			} while (dot > 0);
			return null;
		}

		/* ---------------------------------------------------------------- events */

		/* The handlers set from Ring, per object and event name (one handler per event, like RingQt) */
		private static readonly ConditionalWeakTable<object, Dictionary<string, Delegate>> EventHandlers =
			new ConditionalWeakTable<object, Dictionary<string, Delegate>>();

		private static void SetEvent(object target, string name, object callback)
		{
			Type t = target is TypeRef tr ? tr.Type : target?.GetType();
			object instance = target is TypeRef ? null : target;
			if (t == null)
			{
				throw new NullReferenceException("Can't use the event '" + name + "' of a null object");
			}
			BindingFlags flags = (target is TypeRef ? BindingFlags.Static : BindingFlags.Instance) | BindingFlags.Public;
			EventInfo ev = t.GetEvent(name, flags) ?? t.GetEvent(name, flags | BindingFlags.IgnoreCase);
			if (ev == null)
			{
				throw new MissingMemberException("No public event " + t.FullName + "." + name);
			}
			object key = target is TypeRef ? (object)t : target;
			Dictionary<string, Delegate> map = EventHandlers.GetOrCreateValue(key);
			if (map.TryGetValue(ev.Name, out Delegate old))
			{
				ev.RemoveEventHandler(instance, old);
				map.Remove(ev.Name);
			}
			if (callback is CallbackRef cb)
			{
				Delegate handler = MakeDelegate(ev.EventHandlerType, cb.Name);
				ev.AddEventHandler(instance, handler);
				map[ev.Name] = handler;
			}
			else if (callback != null)
			{
				throw new ArgumentException("The event handler must be created with dnCallback()");
			}
		}

		/* ---------------------------------------------------------------- Ring callbacks */

		private static Delegate MakeDelegate(Type delegateType, string ringFunction)
		{
			MethodInfo invoke = delegateType.GetMethod("Invoke");
			ParameterInfo[] ps = invoke.GetParameters();
			ParameterExpression[] pe = new ParameterExpression[ps.Length];
			Expression[] boxed = new Expression[ps.Length];
			for (int i = 0; i < ps.Length; i++)
			{
				if (ps[i].ParameterType.IsByRef)
				{
					throw new NotSupportedException("Ring callbacks can't use ref/out parameters");
				}
				pe[i] = Expression.Parameter(ps[i].ParameterType, ps[i].Name);
				boxed[i] = Expression.Convert(pe[i], typeof(object));
			}
			Expression call = Expression.Call(typeof(Bridge).GetMethod(nameof(RaiseCallback), BindingFlags.NonPublic | BindingFlags.Static),
				Expression.Constant(ringFunction), Expression.Constant(invoke.ReturnType, typeof(Type)),
				Expression.NewArrayInit(typeof(object), boxed));
			Expression body = invoke.ReturnType == typeof(void)
				? call
				: (Expression)Expression.Convert(call, invoke.ReturnType);
			return Expression.Lambda(delegateType, body, pe).Compile();
		}

		/* Called by the generated delegates: run the Ring function and convert its result */
		private static object RaiseCallback(string ringFunction, Type returnType, object[] args)
		{
			if (NativeCallback == null || Depth == 0 || Environment.CurrentManagedThreadId != RingThread)
			{
				Console.Error.WriteLine("RingDotNet: the callback '" + ringFunction + "' was ignored (Ring callbacks only run on the Ring thread during a call)");
				return returnType.IsValueType && returnType != typeof(void) ? Activator.CreateInstance(returnType) : null;
			}
			MemoryStream ms = new MemoryStream();
			WriteItem(ms, 's', Encoding.UTF8.GetBytes(ringFunction));
			foreach (object arg in args)
			{
				Encode(ms, arg);
			}
			byte[] request = ms.ToArray();
			byte[] response = new byte[4096];
			int size;
			fixed (byte* req = request)
			fixed (byte* resp = response)
			{
				size = NativeCallback(req, request.Length, resp, response.Length);
			}
			if (size > response.Length)
			{
				response = new byte[size];
				fixed (byte* resp = response)
				{
					NativeCallback(null, 0, resp, response.Length);
				}
			}
			List<object> items = Decode(new ReadOnlySpan<byte>(response, 0, size));
			if (returnType == typeof(void))
			{
				return null;
			}
			object value = items.Count > 0 ? items[0] : null;
			if (!TryConvert(value, returnType, out object converted, out int _))
			{
				throw new InvalidCastException("Can't convert the Ring callback result to " + returnType.FullName);
			}
			return converted;
		}

		private static string TName(Type t)
		{
			return t.FullName ?? t.Name;
		}

		private static bool Usable(MethodBase m)
		{
			if (m.ContainsGenericParameters)
			{
				return false;
			}
			foreach (ParameterInfo p in m.GetParameters())
			{
				if (p.ParameterType.IsByRef || p.ParameterType.IsPointer || p.ParameterType.IsByRefLike)
				{
					return false;
				}
			}
			return true;
		}

		private static List<object> ParamTypes(MethodBase m)
		{
			List<object> list = new List<object>();
			foreach (ParameterInfo p in m.GetParameters())
			{
				list.Add(TName(p.ParameterType));
			}
			return list;
		}

		/* Public API of a type, used by the Ring class generator:
		   [fullName, isStaticClass, [ctor:[paramTypes]], [method:[name,isStatic,returnType,[paramTypes]]],
		    [member:[name,canRead,canWrite,isStatic,type]]] */
		private static List<object> Describe(Type t)
		{
			List<object> ctors = new List<object>();
			if (!t.IsAbstract)
			{
				foreach (ConstructorInfo c in t.GetConstructors(BindingFlags.Public | BindingFlags.Instance))
				{
					if (Usable(c)) ctors.Add(ParamTypes(c));
				}
			}
			List<object> methods = new List<object>();
			foreach (BindingFlags f in new[] { BindingFlags.Public | BindingFlags.Instance, BindingFlags.Public | BindingFlags.Static })
			{
				foreach (MethodInfo m in t.GetMethods(f))
				{
					if (m.IsSpecialName || !Usable(m)) continue;
					methods.Add(new List<object> { m.Name, m.IsStatic, TName(m.ReturnType), ParamTypes(m) });
				}
			}
			List<object> members = new List<object>();
			foreach (BindingFlags f in new[] { BindingFlags.Public | BindingFlags.Instance, BindingFlags.Public | BindingFlags.Static })
			{
				foreach (PropertyInfo p in t.GetProperties(f))
				{
					if (p.GetIndexParameters().Length > 0) continue;
					bool canRead = p.GetMethod != null && p.GetMethod.IsPublic;
					bool canWrite = p.SetMethod != null && p.SetMethod.IsPublic;
					members.Add(new List<object> { p.Name, canRead, canWrite, (p.GetMethod ?? p.SetMethod).IsStatic, TName(p.PropertyType) });
				}
				foreach (FieldInfo fi in t.GetFields(f))
				{
					members.Add(new List<object> { fi.Name, true, !fi.IsInitOnly && !fi.IsLiteral, fi.IsStatic, TName(fi.FieldType) });
				}
			}
			/* Indexer (like List[i] or Dictionary[key]): [indexType, valueType, canWrite] */
			List<object> indexer = new List<object>();
			foreach (PropertyInfo p in t.GetProperties(BindingFlags.Public | BindingFlags.Instance))
			{
				ParameterInfo[] ips = p.GetIndexParameters();
				if (ips.Length == 1 && p.GetMethod != null && p.GetMethod.IsPublic)
				{
					indexer = new List<object> { TName(ips[0].ParameterType), TName(p.PropertyType), p.SetMethod != null && p.SetMethod.IsPublic };
					break;
				}
			}
			/* Events: [name, isStatic, handlerType] */
			List<object> events = new List<object>();
			foreach (BindingFlags f in new[] { BindingFlags.Public | BindingFlags.Instance, BindingFlags.Public | BindingFlags.Static })
			{
				foreach (EventInfo ev in t.GetEvents(f))
				{
					events.Add(new List<object> { ev.Name, f.HasFlag(BindingFlags.Static), TName(ev.EventHandlerType) });
				}
			}
			return new List<object> { TName(t), t.IsAbstract && t.IsSealed, ctors, methods, members, indexer, events };
		}

		private static List<object> ToList(object target)
		{
			if (!(Plain(target) is IEnumerable en) || target is string)
			{
				throw new ArgumentException("The object is not enumerable");
			}
			List<object> list = new List<object>();
			foreach (object item in en)
			{
				list.Add(item);
			}
			return list;
		}

		/* ---------------------------------------------------------------- reflection helpers */

		private const BindingFlags InstanceFlags = BindingFlags.Public | BindingFlags.Instance;
		private const BindingFlags StaticFlags = BindingFlags.Public | BindingFlags.Static | BindingFlags.FlattenHierarchy;

		private static bool IsNumeric(Type t)
		{
			switch (Type.GetTypeCode(t))
			{
				case TypeCode.SByte: case TypeCode.Byte: case TypeCode.Int16: case TypeCode.UInt16:
				case TypeCode.Int32: case TypeCode.UInt32: case TypeCode.Int64: case TypeCode.UInt64:
				case TypeCode.Single: case TypeCode.Double: case TypeCode.Decimal:
					return true;
			}
			return false;
		}

		private static bool IsIntegral(Type t)
		{
			switch (Type.GetTypeCode(t))
			{
				case TypeCode.SByte: case TypeCode.Byte: case TypeCode.Int16: case TypeCode.UInt16:
				case TypeCode.Int32: case TypeCode.UInt32: case TypeCode.Int64: case TypeCode.UInt64:
					return true;
			}
			return false;
		}

		/* Convert a Ring value to a parameter type, score = how good the match is (higher is better) */
		private static bool TryConvert(object v, Type t, out object result, out int score)
		{
			result = null;
			score = 0;
			if (t.IsByRef || t.IsPointer)
			{
				return false;
			}
			v = Plain(v);
			Type ut = Nullable.GetUnderlyingType(t) ?? t;
			if (v is CallbackRef cb)
			{
				if (typeof(Delegate).IsAssignableFrom(ut) && ut != typeof(Delegate) && ut != typeof(MulticastDelegate))
				{
					result = MakeDelegate(ut, cb.Name);
					score = 3;
					return true;
				}
				return false;
			}
			if (v == null)
			{
				if (!t.IsValueType || ut != t)
				{
					score = 1;
					return true;
				}
				return false;
			}
			if (ut.IsInstanceOfType(v))
			{
				result = v;
				score = ut == typeof(object) ? 1 : (v.GetType() == ut ? 4 : 2);
				return true;
			}
			if (v is double d)
			{
				if (ut.IsEnum)
				{
					result = Enum.ToObject(ut, (long)d);
					score = 1;
					return true;
				}
				if (IsNumeric(ut))
				{
					if (IsIntegral(ut) && d != Math.Floor(d))
					{
						return false;
					}
					try
					{
						result = Convert.ChangeType(d, ut, Inv);
						score = ut == typeof(int) ? 3 : 2;
						return true;
					}
					catch (Exception) { return false; }
				}
				if (ut == typeof(bool))
				{
					result = d != 0;
					score = 1;
					return true;
				}
				if (ut == typeof(string))
				{
					result = d.ToString("R", Inv);
					score = 0;
					return true;
				}
				return false;
			}
			if (v is string s)
			{
				if (ut.IsEnum)
				{
					try { result = Enum.Parse(ut, s, true); score = 2; return true; }
					catch (Exception) { return false; }
				}
				if (ut == typeof(char) && s.Length == 1)
				{
					result = s[0];
					score = 2;
					return true;
				}
				if (ut == typeof(byte[]))
				{
					result = Encoding.Latin1.GetBytes(s);
					score = 1;
					return true;
				}
				if (ut == typeof(Guid) && Guid.TryParse(s, out Guid g))
				{
					result = g;
					score = 2;
					return true;
				}
				if (ut == typeof(Type))
				{
					try { result = ResolveType(s); score = 2; return true; }
					catch (Exception) { return false; }
				}
				return false;
			}
			if (v is bool b)
			{
				if (IsNumeric(ut))
				{
					result = Convert.ChangeType(b ? 1 : 0, ut, Inv);
					score = 1;
					return true;
				}
				return false;
			}
			if (v is object[] list && ut.IsArray)
			{
				Type et = ut.GetElementType();
				Array arr = Array.CreateInstance(et, list.Length);
				for (int i = 0; i < list.Length; i++)
				{
					if (!TryConvert(list[i], et, out object item, out int _))
					{
						return false;
					}
					arr.SetValue(item, i);
				}
				result = arr;
				score = 2;
				return true;
			}
			return false;
		}

		/* Choose the best overload; returns the converted arguments */
		private static T Pick<T>(IEnumerable<T> candidates, object[] args, out object[] converted) where T : MethodBase
		{
			T best = null;
			object[] bestArgs = null;
			int bestScore = -1;
			foreach (T m in candidates)
			{
				if (m.ContainsGenericParameters)
				{
					continue;
				}
				ParameterInfo[] ps = m.GetParameters();
				int required = 0;
				foreach (ParameterInfo p in ps)
				{
					if (!p.IsOptional) required++;
				}
				if (args.Length < required || args.Length > ps.Length)
				{
					continue;
				}
				object[] conv = new object[ps.Length];
				int total = 0;
				bool ok = true;
				for (int i = 0; i < ps.Length && ok; i++)
				{
					if (i < args.Length)
					{
						ok = TryConvert(args[i], ps[i].ParameterType, out conv[i], out int sc);
						total += sc;
					}
					else
					{
						conv[i] = ps[i].HasDefaultValue ? ps[i].DefaultValue : Type.Missing;
					}
				}
				if (ok && total > bestScore)
				{
					best = m;
					bestArgs = conv;
					bestScore = total;
				}
			}
			converted = bestArgs;
			return best;
		}

		private static IEnumerable<MethodInfo> MethodsNamed(Type t, string name, BindingFlags flags)
		{
			List<MethodInfo> found = new List<MethodInfo>();
			foreach (MethodInfo m in t.GetMethods(flags))
			{
				if (m.Name == name) found.Add(m);
			}
			if (found.Count == 0)
			{
				foreach (MethodInfo m in t.GetMethods(flags))
				{
					if (string.Equals(m.Name, name, StringComparison.OrdinalIgnoreCase)) found.Add(m);
				}
			}
			return found;
		}

		private static object CreateInstance(Type t, object[] args)
		{
			if (t.IsAbstract)
			{
				throw new InvalidOperationException("Can't create an instance of the abstract type " + t.FullName);
			}
			if (args.Length == 0 && t.IsValueType)
			{
				return Activator.CreateInstance(t);
			}
			ConstructorInfo ctor = Pick(t.GetConstructors(BindingFlags.Public | BindingFlags.Instance), args, out object[] conv);
			if (ctor == null)
			{
				throw new MissingMethodException("No public constructor of " + t.FullName + " matches the " + args.Length + " argument(s)");
			}
			return ctor.Invoke(conv);
		}

		private static object CallMethod(object target, string name, object[] args)
		{
			Type t;
			object instance = null;
			BindingFlags flags;
			if (target is TypeRef tr)
			{
				t = tr.Type;
				flags = StaticFlags;
			}
			else
			{
				if (target == null)
				{
					throw new NullReferenceException("Can't call '" + name + "' on a null object");
				}
				instance = target;
				t = target.GetType();
				flags = InstanceFlags;
			}
			MethodInfo m = Pick(MethodsNamed(t, name, flags), args, out object[] conv);
			if (m == null)
			{
				throw new MissingMethodException("No public method " + t.FullName + "." + name + " matches the " + args.Length + " argument(s)");
			}
			return m.Invoke(instance, conv);
		}

		private static object GetMember(object target, string name)
		{
			Type t = target is TypeRef tr ? tr.Type : target?.GetType();
			object instance = target is TypeRef ? null : target;
			if (t == null)
			{
				throw new NullReferenceException("Can't read '" + name + "' from a null object");
			}
			BindingFlags flags = target is TypeRef ? StaticFlags : InstanceFlags;
			foreach (BindingFlags f in new[] { flags, flags | BindingFlags.IgnoreCase })
			{
				PropertyInfo p = t.GetProperty(name, f);
				if (p != null && p.GetIndexParameters().Length == 0)
				{
					return p.GetValue(instance);
				}
				FieldInfo fi = t.GetField(name, f);
				if (fi != null)
				{
					return fi.GetValue(instance);
				}
			}
			throw new MissingMemberException("No public property or field " + t.FullName + "." + name);
		}

		private static void SetMember(object target, string name, object value)
		{
			Type t = target is TypeRef tr ? tr.Type : target?.GetType();
			object instance = target is TypeRef ? null : target;
			if (t == null)
			{
				throw new NullReferenceException("Can't write '" + name + "' on a null object");
			}
			BindingFlags flags = target is TypeRef ? StaticFlags : InstanceFlags;
			foreach (BindingFlags f in new[] { flags, flags | BindingFlags.IgnoreCase })
			{
				PropertyInfo p = t.GetProperty(name, f);
				if (p != null && p.CanWrite)
				{
					if (!TryConvert(value, p.PropertyType, out object conv, out int _))
					{
						throw new ArgumentException("Can't convert the value to " + p.PropertyType.FullName);
					}
					p.SetValue(instance, conv);
					return;
				}
				FieldInfo fi = t.GetField(name, f);
				if (fi != null)
				{
					if (!TryConvert(value, fi.FieldType, out object conv, out int _))
					{
						throw new ArgumentException("Can't convert the value to " + fi.FieldType.FullName);
					}
					fi.SetValue(instance, conv);
					return;
				}
			}
			throw new MissingMemberException("No writable public property or field " + t.FullName + "." + name);
		}
	}
}
