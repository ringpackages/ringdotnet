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
using System.Linq;
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

		/* Assemblies that are not part of the runtime (the packages of RingDotNet.Data) are found next to the bridge */
		static Bridge()
		{
			string folder = Path.GetDirectoryName(typeof(Bridge).Assembly.Location);
			AppDomain.CurrentDomain.AssemblyResolve += (sender, args) =>
			{
				string file = Path.Combine(folder, new AssemblyName(args.Name).Name + ".dll");
				return File.Exists(file) ? Assembly.LoadFrom(file) : null;
			};
		}

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
					case 's': items.Add(DecodeString(body)); break;
					case 'n': items.Add(double.Parse(Encoding.ASCII.GetString(body), NumberStyles.Float, Inv)); break;
					case 'b': items.Add(body.Length > 0 && body[0] == (byte)'1'); break;
					case 'd': items.Add(BitConverter.ToDouble(body)); break;
					case 'z': items.Add(null); break;
					case 'o': items.Add(Lookup(ParseHandle(body))); break;
					case 'l': items.Add(Decode(body).ToArray()); break;
					case 'c': items.Add(new CallbackRef(Encoding.UTF8.GetString(body))); break;
					case 'e': throw new InvalidOperationException("Ring error: " + Encoding.UTF8.GetString(body));
					default: throw new ArgumentException("Unknown item tag '" + tag + "'");
				}
			}
			return items;
		}

		/* An object item is "<id>" or "<id>|<type>|<base type>|..." (the form sent to Ring) */
		private static long ParseHandle(ReadOnlySpan<byte> body)
		{
			int bar = body.IndexOf((byte)'|');
			return long.Parse(Encoding.ASCII.GetString(bar < 0 ? body : body.Slice(0, bar)), Inv);
		}

		/* Type names Ring can wrap the object with: its type, then its base types */
		private static readonly System.Collections.Concurrent.ConcurrentDictionary<Type, string> TypeChains = new System.Collections.Concurrent.ConcurrentDictionary<Type, string>();

		private static string TypeChain(object value)
		{
			return TypeChains.GetOrAdd(value.GetType(), BuildTypeChain);
		}

		private static string BuildTypeChain(Type type)
		{
			StringBuilder sb = new StringBuilder();
			int count = 0;
			for (Type t = type; t != null && t != typeof(object) && count < 8; t = t.BaseType, count++)
			{
				sb.Append('|').Append(t.FullName ?? t.Name);
			}
			/* then the interfaces (a class that is not generated can still be wrapped as ICryptoTransform, IDisposable...) */
			foreach (Type i in type.GetInterfaces())
			{
				if (i.IsVisible && count++ < 40)
				{
					sb.Append('|').Append(i.FullName ?? i.Name);
				}
			}
			return sb.ToString();
		}

		private static readonly UTF8Encoding StrictUtf8 = new UTF8Encoding(false, true);

		/* Valid UTF-8 text becomes a string; anything else (binary data) stays a byte[] */
		private static object DecodeString(ReadOnlySpan<byte> body)
		{
			try
			{
				return StrictUtf8.GetString(body);
			}
			catch (ArgumentException)
			{
				return body.ToArray();
			}
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
				case Enum e: WriteItem(ms, 's', Encoding.UTF8.GetBytes(e.ToString())); return;
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
					WriteItem(ms, 'o', Encoding.UTF8.GetBytes(Register(value).ToString(Inv) + TypeChain(value)));
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
			WriteItem(ms, 'e', Encoding.UTF8.GetBytes(ex.GetType().FullName + ": " + ex.Message + (Environment.GetEnvironmentVariable("RINGDOTNET_TRACE") == "1" ? Environment.NewLine + ex.StackTrace : "")));
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
				case "callnamed":
					return CallMethodNamed(a[0], Str(a, 1), a.Length > 2 ? a[2] : null);
				case "newnamed":
					return CreateInstanceNamed(TypeOf(a, 0), a.Length > 1 ? a[1] : null);
				case "get":
					return GetMember(a[0], Str(a, 1));
				case "set":
					SetMember(a[0], Str(a, 1), a[2]);
					return null;
				case "releasemany":
					lock (Handles)
					{
						foreach (object handle in a)
						{
							Handles.Remove(Convert.ToInt64(handle is double h ? h : 0, Inv));
						}
					}
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
				case "listtypes":
					return ListTypes(Str(a, 0), Rest(a, 1));
				case "bridgefolder":
					return Path.GetDirectoryName(typeof(Bridge).Assembly.Location);
				case "keytokens":
					return KeyTokens(Str(a, 0));
				case "postkey":
					PostKeyToken(a[0], Str(a, 1));
					return null;
				case "listnamespaces":
					return ListNamespaces(Str(a, 0));
				case "enumnames":
					return new List<object>(Enum.GetNames(TypeOf(a, 0)));
				case "apidoc":
					return ApiDoc(ResolveType(Str(a, 0)));
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
				/* Microsoft.AspNetCore.DataProtection.IDataProtector is in the assembly ...DataProtection.Abstractions, ...DataProtectionProvider in ...Extensions */
				foreach (string suffix in new[] { ".Abstractions", ".Extensions" })
				{
					try
					{
						t = Assembly.Load(prefix + suffix).GetType(name, false);
						if (t != null)
						{
							return t;
						}
					}
					catch (Exception) { }
				}
				dot = prefix.LastIndexOf('.');
				if (dot > 0)
				{
					prefix = prefix.Substring(0, dot);
				}
			} while (dot > 0);
			/* types that live in an assembly whose name is not a prefix of their namespace */
			foreach (string extra in new[] { "System.IO.Compression.Brotli", "System.Collections.NonGeneric", "Microsoft.Extensions.Configuration.Json", "Microsoft.Extensions.Configuration.EnvironmentVariables", "Microsoft.Extensions.Configuration.Binder", "Microsoft.Extensions.Configuration.CommandLine", "Microsoft.Extensions.Configuration.Ini", "Microsoft.Extensions.Configuration.Xml", "Microsoft.Extensions.Configuration.FileExtensions", "Microsoft.Extensions.FileProviders.Physical", "System.Net.Http.Json", "System.Linq.Expressions", "System.Collections.Concurrent", "System.Threading.Channels", "System.Numerics.Vectors" })
			{
				try
				{
					t = Assembly.Load(extra).GetType(name, false);
					if (t != null)
					{
						return t;
					}
				}
				catch (Exception) { }
			}
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

		/* For other assemblies (RingDotNet.Data): run the Ring function of a callback made with dnCallback() */
		public static object CallRing(object callback, Type returnType, object[] args)
		{
			if (callback is CallbackRef cb) return RaiseCallback(cb.Name, returnType, args);
			throw new ArgumentException("The callback must be created with dnCallback() (got " + (callback == null ? "null" : callback.GetType().FullName) + ")");
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

		/* ---------------------------------------------------------------- keyboard (for tests)
		   Keys are posted to the window of a control of THIS program (PostMessage), so they go through the normal
		   Windows Forms key processing (dialog keys, PreviewKeyDown, KeyDown, KeyPress) and can never reach another application. */

		[DllImport("user32.dll")] private static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
		[DllImport("user32.dll")] private static extern uint MapVirtualKey(uint code, uint mapType);

		private const uint WM_KEYDOWN = 0x0100, WM_KEYUP = 0x0101, WM_CHAR = 0x0102;

		private static int KeyCode(string name)
		{
			Type keys = ResolveType("System.Windows.Forms.Keys, System.Windows.Forms");
			return (int)Convert.ChangeType(Enum.Parse(keys, name, true), typeof(int)) & 0xFFFF;
		}

		private static void PostKey(IntPtr hwnd, int vk, bool extended)
		{
			uint scan = MapVirtualKey((uint)vk, 0);
			long down = 1 | ((long)scan << 16) | (extended ? 1L << 24 : 0);
			long up = down | (1L << 30) | (1L << 31);
			PostMessage(hwnd, WM_KEYDOWN, (IntPtr)vk, (IntPtr)down);
			PostMessage(hwnd, WM_KEYUP, (IntPtr)vk, (IntPtr)up);
		}

		/* A key sequence as tokens: "{LEFT}", "a", " ", "{+}". Each token is posted alone and the form processes it before the next one,
		   because the message loop makes the WM_CHAR message of a key (like for the real keyboard) after the keys that are already queued. */
		private static List<object> KeyTokens(string sequence)
		{
			List<object> tokens = new List<object>();
			for (int i = 0; i < sequence.Length; i++)
			{
				if (sequence[i] == '{')
				{
					int close = sequence.IndexOf('}', i + 1);
					if (close < 0) close = Math.Min(i + 2, sequence.Length - 1);
					tokens.Add(sequence.Substring(i, close - i + 1));
					i = close;
				}
				else
				{
					tokens.Add(sequence[i].ToString());
				}
			}
			return tokens;
		}

		private static void PostKeyToken(object control, string token)
		{
			IntPtr hwnd = (IntPtr)control.GetType().GetProperty("Handle").GetValue(control);
			Dictionary<string, string> special = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
			{
				{ "LEFT", "Left" }, { "RIGHT", "Right" }, { "UP", "Up" }, { "DOWN", "Down" }, { "ENTER", "Return" }, { "ESC", "Escape" },
				{ "BACKSPACE", "Back" }, { "BS", "Back" }, { "TAB", "Tab" }, { "DELETE", "Delete" }, { "HOME", "Home" }, { "END", "End" },
				{ "PGUP", "PageUp" }, { "PGDN", "PageDown" }, { "SPACE", "Space" }
			};
			HashSet<string> extended = new HashSet<string> { "Left", "Right", "Up", "Down", "Delete", "Home", "End", "PageUp", "PageDown" };
			if (token.Length > 3 && token[0] == '{' || (token.Length == 3 && token[0] == '{' && char.IsLetterOrDigit(token[1])))
			{
				string name = token.Substring(1, token.Length - 2);
				string key = special.TryGetValue(name, out string mapped) ? mapped : name;
				PostKey(hwnd, KeyCode(key), extended.Contains(key));
			}
			else
			{
				char c = token.Length == 3 && token[0] == '{' ? token[1] : token[0];
				if (c == ' ')
				{
					PostKey(hwnd, KeyCode("Space"), false);
				}
				else if (char.IsLetterOrDigit(c) && c < 128)
				{
					int vk = char.ToUpperInvariant(c);
					PostMessage(hwnd, WM_KEYDOWN, (IntPtr)vk, (IntPtr)1);
					PostMessage(hwnd, WM_KEYUP, (IntPtr)vk, (IntPtr)(1L | (1L << 30) | (1L << 31)));
				}
				else
				{
					PostMessage(hwnd, WM_CHAR, (IntPtr)c, (IntPtr)1);
				}
			}
		}

		/* Namespaces that have public types in an assembly (a file path or an assembly name) */
		private static List<object> ListNamespaces(string assembly)
		{
			Assembly asm = File.Exists(assembly) ? Assembly.LoadFrom(assembly) : Assembly.Load(assembly);
			SortedSet<string> found = new SortedSet<string>(StringComparer.Ordinal);
			foreach (Type t in asm.GetExportedTypes())
			{
				if (t.Namespace != null) found.Add(t.Namespace);
			}
			return new List<object>(found);
		}

		/* Public classes and structs of a namespace that are worth wrapping in Ring */
		private static List<object> ListTypes(string ns, object[] assemblyNames)
		{
			List<string> found = new List<string>();
			List<Assembly> assemblies = new List<Assembly>();
			foreach (object n in assemblyNames)
			{
				if (n is string an)
				{
					try { assemblies.Add(Assembly.Load(an)); } catch (Exception) { }
				}
			}
			foreach (Assembly asm in assemblies)
			{
				Type[] types;
				try { types = asm.GetExportedTypes(); }
				catch (ReflectionTypeLoadException ex) { types = Array.FindAll(ex.Types, x => x != null); }
				catch (Exception) { continue; }
				foreach (Type t in types)
				{
					if (t.Namespace != ns || t.IsNested || t.IsEnum || t.IsGenericTypeDefinition || t.IsByRefLike)
					{
						continue;
					}
					if (typeof(Delegate).IsAssignableFrom(t) || typeof(Attribute).IsAssignableFrom(t) || typeof(Exception).IsAssignableFrom(t))
					{
						continue;
					}
					if (t.IsDefined(typeof(ObsoleteAttribute), false) || t.FullName == null || found.Contains(t.FullName))
					{
						continue;
					}
					found.Add(t.FullName);
				}
			}
			found.Sort(StringComparer.Ordinal);
			return new List<object>(found);
		}

		private static string TName(Type t)
		{
			return t.FullName ?? t.Name;
		}

		private static bool Usable(MethodBase m)
		{
			if (m.ContainsGenericParameters && !(m is MethodInfo gm && gm.IsGenericMethodDefinition))
			{
				return false;
			}
			foreach (ParameterInfo p in m.GetParameters())
			{
				Type pt = p.ParameterType.IsByRef ? p.ParameterType.GetElementType() : p.ParameterType;
				if (pt.IsPointer || pt.IsByRefLike || pt.IsByRef || (pt.IsGenericType && pt.GetGenericArguments().Any(g => g.IsByRefLike)))
				{
					return false;
				}
			}
			return true;
		}

		/* ---------------------------------------------------------------- API documentation (JSON) */

		private static string Pretty(Type t)
		{
			if (t.IsByRef) t = t.GetElementType();
			if (t == typeof(void)) return "void";
			if (t == typeof(string)) return "string";
			if (t == typeof(int)) return "int";
			if (t == typeof(long)) return "long";
			if (t == typeof(short)) return "short";
			if (t == typeof(byte)) return "byte";
			if (t == typeof(sbyte)) return "sbyte";
			if (t == typeof(uint)) return "uint";
			if (t == typeof(ulong)) return "ulong";
			if (t == typeof(ushort)) return "ushort";
			if (t == typeof(bool)) return "bool";
			if (t == typeof(double)) return "double";
			if (t == typeof(float)) return "float";
			if (t == typeof(decimal)) return "decimal";
			if (t == typeof(char)) return "char";
			if (t == typeof(object)) return "object";
			if (t.IsArray) return Pretty(t.GetElementType()) + "[]";
			Type nullable = Nullable.GetUnderlyingType(t);
			if (nullable != null) return Pretty(nullable) + "?";
			if (t.IsGenericParameter) return t.Name;
			if (t.IsGenericType)
			{
				string name = t.Name;
				int tick = name.IndexOf('`');
				if (tick >= 0) name = name.Substring(0, tick);
				return name + "<" + string.Join(", ", t.GetGenericArguments().Select(Pretty)) + ">";
			}
			return t.DeclaringType != null ? Pretty(t.DeclaringType) + "." + t.Name : t.Name;
		}

		private static bool SkipDeclaring(Type d)
		{
			return d == typeof(object) || d == typeof(ValueType) || d == typeof(Enum) || d == typeof(MarshalByRefObject);
		}

		private static List<object> ApiParams(MethodBase m)
		{
			List<object> list = new List<object>();
			foreach (ParameterInfo p in m.GetParameters())
			{
				Dictionary<string, object> d = new Dictionary<string, object>();
				d["t"] = Pretty(p.ParameterType);
				d["n"] = p.Name ?? "";
				if (p.IsOptional) d["o"] = 1;
				if (p.ParameterType.IsByRef) d["m"] = p.IsOut ? "out" : "ref";
				list.Add(d);
			}
			return list;
		}

		/* Everything about a type for the documentation, as JSON */
		private static string ApiDoc(Type t)
		{
			Dictionary<string, object> r = new Dictionary<string, object>();
			r["full"] = t.FullName ?? t.Name;
			r["name"] = Pretty(t);
			r["ns"] = t.Namespace ?? "";
			r["asm"] = t.Assembly.GetName().Name;
			string kind = t.IsEnum ? "enum" : t.IsInterface ? "interface" : t.IsValueType ? "struct" : typeof(Delegate).IsAssignableFrom(t) ? "delegate" : "class";
			r["kind"] = kind;
			if (t.IsAbstract && t.IsSealed) r["static"] = 1;
			else if (t.IsAbstract && !t.IsInterface) r["abstract"] = 1;
			else if (t.IsSealed && !t.IsValueType && !t.IsEnum) r["sealed"] = 1;
			if (t.BaseType != null && !SkipDeclaring(t.BaseType)) { r["base"] = Pretty(t.BaseType); r["basefull"] = t.BaseType.FullName ?? ""; }
			r["interfaces"] = t.GetInterfaces().Where(i => i.IsPublic && (i.Namespace ?? "").StartsWith("System") && !i.IsGenericType).Select(Pretty).Take(12).ToList();
			if (t.IsEnum) r["values"] = Enum.GetNames(t).ToList();
			List<object> ctors = new List<object>();
			if (!t.IsAbstract)
			{
				foreach (ConstructorInfo c in t.GetConstructors(BindingFlags.Public | BindingFlags.Instance))
				{
					if (Usable(c)) ctors.Add(ApiParams(c));
				}
			}
			r["ctors"] = ctors;
			List<object> methods = new List<object>();
			foreach (BindingFlags f in new[] { BindingFlags.Public | BindingFlags.Instance, BindingFlags.Public | BindingFlags.Static })
			{
				foreach (MethodInfo m in t.GetMethods(f))
				{
					if (m.IsSpecialName || !Usable(m) || SkipDeclaring(m.DeclaringType)) continue;
					Dictionary<string, object> d = new Dictionary<string, object>();
					d["n"] = m.Name;
					d["r"] = Pretty(m.ReturnType);
					d["p"] = ApiParams(m);
					if (m.IsStatic) d["s"] = 1;
					if (m.IsGenericMethodDefinition) d["g"] = string.Join(", ", m.GetGenericArguments().Select(x => x.Name));
					if (m.DeclaringType != t) d["from"] = Pretty(m.DeclaringType);
					methods.Add(d);
				}
			}
			r["methods"] = methods;
			List<object> props = new List<object>();
			List<object> fields = new List<object>();
			foreach (BindingFlags f in new[] { BindingFlags.Public | BindingFlags.Instance, BindingFlags.Public | BindingFlags.Static })
			{
				foreach (PropertyInfo p in t.GetProperties(f))
				{
					if (p.GetIndexParameters().Length > 0 || SkipDeclaring(p.DeclaringType)) continue;
					Dictionary<string, object> d = new Dictionary<string, object>();
					d["n"] = p.Name;
					d["t"] = Pretty(p.PropertyType);
					d["r"] = p.GetMethod != null && p.GetMethod.IsPublic ? 1 : 0;
					d["w"] = p.SetMethod != null && p.SetMethod.IsPublic ? 1 : 0;
					if ((p.GetMethod ?? p.SetMethod).IsStatic) d["s"] = 1;
					if (p.DeclaringType != t) d["from"] = Pretty(p.DeclaringType);
					props.Add(d);
				}
				foreach (FieldInfo fi in t.GetFields(f))
				{
					if (SkipDeclaring(fi.DeclaringType) || (t.IsEnum && fi.IsLiteral)) continue;
					Dictionary<string, object> d = new Dictionary<string, object>();
					d["n"] = fi.Name;
					d["t"] = Pretty(fi.FieldType);
					d["w"] = !fi.IsInitOnly && !fi.IsLiteral ? 1 : 0;
					if (fi.IsStatic) d["s"] = 1;
					if (fi.IsLiteral) d["c"] = 1;
					if (fi.DeclaringType != t) d["from"] = Pretty(fi.DeclaringType);
					fields.Add(d);
				}
			}
			r["props"] = props;
			r["fields"] = fields;
			List<object> indexers = new List<object>();
			foreach (PropertyInfo p in t.GetProperties(BindingFlags.Public | BindingFlags.Instance))
			{
				ParameterInfo[] ips = p.GetIndexParameters();
				if (ips.Length == 1 && p.GetMethod != null && p.GetMethod.IsPublic)
				{
					indexers.Add(new Dictionary<string, object> { { "i", Pretty(ips[0].ParameterType) }, { "n", ips[0].Name ?? "" }, { "t", Pretty(p.PropertyType) }, { "w", p.SetMethod != null && p.SetMethod.IsPublic ? 1 : 0 } });
					break;
				}
			}
			r["indexers"] = indexers;
			List<object> events = new List<object>();
			foreach (BindingFlags f in new[] { BindingFlags.Public | BindingFlags.Instance, BindingFlags.Public | BindingFlags.Static })
			{
				foreach (EventInfo ev in t.GetEvents(f))
				{
					Dictionary<string, object> d = new Dictionary<string, object>();
					d["n"] = ev.Name;
					d["t"] = Pretty(ev.EventHandlerType);
					if (f.HasFlag(BindingFlags.Static)) d["s"] = 1;
					if (ev.DeclaringType != t) d["from"] = Pretty(ev.DeclaringType);
					events.Add(d);
				}
			}
			r["events"] = events;
			return System.Text.Json.JsonSerializer.Serialize(r);
		}

		private static bool IsOutOnly(ParameterInfo p)
		{
			return p.ParameterType.IsByRef && p.IsOut && !p.IsIn;
		}

		private static int ByRefCount(MethodBase m)
		{
			int n = 0;
			foreach (ParameterInfo p in m.GetParameters())
			{
				if (p.ParameterType.IsByRef) n++;
			}
			return n;
		}

		/* Parameters the caller has to give (the others are optional) */
		private static int RequiredCount(MethodBase m)
		{
			int n = 0;
			foreach (ParameterInfo p in m.GetParameters())
			{
				if (!IsOutOnly(p) && !p.IsOptional) n++;
			}
			return n;
		}

		private static List<object> ParamTypes(MethodBase m)
		{
			List<object> list = new List<object>();
			foreach (ParameterInfo p in m.GetParameters())
			{
				if (IsOutOnly(p)) continue;
				list.Add(TName(p.ParameterType.IsByRef ? p.ParameterType.GetElementType() : p.ParameterType));
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
					if (!Usable(c)) continue;
					List<object> types = ParamTypes(c);
					ctors.Add(types);
					/* optional parameters: the constructor is also available with fewer parameters */
					for (int cut = types.Count - 1; cut >= RequiredCount(c); cut--)
					{
						ctors.Add(types.GetRange(0, cut));
					}
				}
			}
			List<object> methods = new List<object>();
			foreach (BindingFlags f in new[] { BindingFlags.Public | BindingFlags.Instance, BindingFlags.Public | BindingFlags.Static })
			{
				foreach (MethodInfo m in t.GetMethods(f))
				{
					if (m.IsSpecialName || !Usable(m)) continue;
					methods.Add(new List<object> { m.Name, m.IsStatic, TName(m.ReturnType), ParamTypes(m), ByRefCount(m), RequiredCount(m) });
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
			return new List<object> { TName(t), t.IsAbstract && t.IsSealed, ctors, methods, members, indexer, events, t.IsValueType, t.Assembly.GetName().Name, t.BaseType == null ? "" : TName(t.BaseType) };
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
					score = 12 - ut.GetMethod("Invoke").GetParameters().Length;
					return true;
				}
				if (ut == typeof(object))
				{
					/* a parameter of type object keeps the callback (an assembly that wraps Ring code calls it with Bridge.CallRing) */
					result = cb;
					score = 1;
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
			if (v is double num && IsNumeric(ut))
			{
				/* Ring numbers are doubles: prefer int for whole numbers (Write(7) is Write(int), not Write(double)) */
				bool whole = num == Math.Floor(num);
				if (IsIntegral(ut) && !whole)
				{
					return false;
				}
				try
				{
					result = Convert.ChangeType(num, ut, Inv);
				}
				catch (Exception) { return false; }
				switch (Type.GetTypeCode(ut))
				{
					case TypeCode.Int32: score = whole ? 6 : 1; break;
					case TypeCode.Int64: score = whole ? 5 : 1; break;
					case TypeCode.Double: score = whole ? 2 : 6; break;
					case TypeCode.Single: score = whole ? 1 : 5; break;
					case TypeCode.Decimal: score = whole ? 1 : 4; break;
					default: score = whole ? 3 : 1; break;
				}
				return true;
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
				return TryImplicit(v, ut, out result, out score);
			}
			if (v is string s)
			{
				if (ut.IsEnum)
				{
					/* TryParse: a text that is not a name of this enum is common while overloads are compared, and an exception is slow */
					if (Enum.TryParse(ut, s, true, out object parsed)) { result = parsed; score = 2; return true; }
					return false;
				}
				if (ut == typeof(char) && s.Length == 1)
				{
					result = s[0];
					score = 2;
					return true;
				}
				if (ut == typeof(byte[]))
				{
					result = Encoding.UTF8.GetBytes(s);
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
				return TryImplicit(v, ut, out result, out score);
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
			if (v is object[] items && ut.IsGenericType && ut.GetGenericArguments().Length == 1)
			{
				/* a Ring list for IEnumerable<T>, IList<T>, ICollection<T>, List<T>... */
				Type et = ut.GetGenericArguments()[0];
				Array arr = Array.CreateInstance(et, items.Length);
				for (int i = 0; i < items.Length; i++)
				{
					if (!TryConvert(items[i], et, out object item, out int _))
					{
						return false;
					}
					arr.SetValue(item, i);
				}
				if (ut.IsAssignableFrom(arr.GetType()))
				{
					result = arr;
					score = 2;
					return true;
				}
				Type listType = typeof(List<>).MakeGenericType(et);
				if (ut.IsAssignableFrom(listType))
				{
					result = Activator.CreateInstance(listType, arr);
					score = 2;
					return true;
				}
			}
			return TryImplicit(v, ut, out result, out score);
		}

		/* User defined implicit conversions (string --> XName, string --> PathString ...) */
		/* The op_Implicit methods of a type (with one parameter): found once, because GetMethods copies a big array on every call */
		private static readonly System.Collections.Concurrent.ConcurrentDictionary<Type, MethodInfo[]> ImplicitCache =
			new System.Collections.Concurrent.ConcurrentDictionary<Type, MethodInfo[]>();

		private static MethodInfo[] ImplicitOperators(Type owner)
		{
			return ImplicitCache.GetOrAdd(owner, type =>
			{
				List<MethodInfo> list = new List<MethodInfo>();
				foreach (MethodInfo m in type.GetMethods(BindingFlags.Public | BindingFlags.Static))
				{
					if (m.Name == "op_Implicit" && m.GetParameters().Length == 1) list.Add(m);
				}
				return list.ToArray();
			});
		}

		private static bool TryImplicit(object v, Type target, out object result, out int score)
		{
			result = null;
			score = 0;
			Type from = v.GetType();
			foreach (Type owner in new[] { target, from })
			{
				foreach (MethodInfo m in ImplicitOperators(owner))
				{
					if (!target.IsAssignableFrom(m.ReturnType)) continue;
					ParameterInfo[] ps = ShapeOf(m).Parameters;
					object arg = null;
					bool usable = ps[0].ParameterType.IsAssignableFrom(from);
					if (usable)
					{
						arg = v;
					}
					else if (v is double && IsNumeric(ps[0].ParameterType))
					{
						/* a Ring number for BigInteger / Complex / Half... : whole numbers use the integer conversions first */
						usable = TryConvert(v, ps[0].ParameterType, out arg, out int sc) && (sc >= 5 || !(((double)v) == Math.Floor((double)v)) || ps[0].ParameterType == typeof(double));
					}
					if (usable)
					{
						try { result = m.Invoke(null, new[] { arg }); score = 1; return true; }
						catch (Exception) { }
					}
				}
			}
			return false;
		}

		/* Choose the best overload; returns the converted arguments */
		/* The parameters of a method and how many of them an argument list has to fill: found once (GetParameters copies its array on every call) */
		private sealed class ParamShape
		{
			public ParameterInfo[] Parameters;
			public int Required;
			public int Inputs;
		}

		private static readonly System.Collections.Concurrent.ConcurrentDictionary<MethodBase, ParamShape> Shapes =
			new System.Collections.Concurrent.ConcurrentDictionary<MethodBase, ParamShape>();

		private static ParamShape ShapeOf(MethodBase m)
		{
			return Shapes.GetOrAdd(m, method =>
			{
				ParamShape shape = new ParamShape { Parameters = method.GetParameters() };
				foreach (ParameterInfo p in shape.Parameters)
				{
					if (IsOutOnly(p)) continue;
					shape.Inputs++;
					if (!p.IsOptional) shape.Required++;
				}
				return shape;
			});
		}

		private static MethodBase Pick(IEnumerable<MethodBase> candidates, object[] args, out object[] converted)
		{
			MethodBase best = null;
			object[] bestArgs = null;
			int bestScore = int.MinValue;
			foreach (MethodBase candidate in candidates)
			{
				MethodBase m = candidate;
				if (m is MethodInfo def && def.IsGenericMethodDefinition)
				{
					m = CloseGeneric(def, args);
					if (m == null)
					{
						continue;
					}
				}
				if (m.ContainsGenericParameters)
				{
					continue;
				}
				ParamShape shape = ShapeOf(m);
				ParameterInfo[] ps = shape.Parameters;
				if (args.Length < shape.Required || args.Length > shape.Inputs)
				{
					continue;
				}
				object[] conv = new object[ps.Length];
				int total = 0, next = 0;
				bool ok = true;
				for (int i = 0; i < ps.Length && ok; i++)
				{
					Type pt = ps[i].ParameterType.IsByRef ? ps[i].ParameterType.GetElementType() : ps[i].ParameterType;
					if (IsOutOnly(ps[i]))
					{
						conv[i] = pt.IsValueType ? Activator.CreateInstance(pt) : null;
					}
					else if (next < args.Length)
					{
						ok = TryConvert(args[next++], pt, out conv[i], out int sc);
						total += sc;
					}
					else
					{
						conv[i] = ps[i].HasDefaultValue ? ps[i].DefaultValue : Type.Missing;
					}
				}
				if (candidate != m)
				{
					total -= 3;	/* a closed generic method loses against a plain overload with the same arguments */
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

		/* Generic methods (LINQ): infer the type arguments from the values; callbacks and unknowns become object */
		/* does the type mention the generic parameter (List<T>, T[], Func<T, TKey>...)? */
		private static bool TypeUses(Type type, Type genericParameter)
		{
			if (type == genericParameter) return true;
			if (type.HasElementType) return TypeUses(type.GetElementType(), genericParameter);
			if (type.IsGenericType)
			{
				foreach (Type argument in type.GetGenericArguments())
				{
					if (TypeUses(argument, genericParameter)) return true;
				}
			}
			return false;
		}

		private static MethodInfo CloseGeneric(MethodInfo def, object[] args)
		{
			Dictionary<Type, Type> map = new Dictionary<Type, Type>();
			ParameterInfo[] ps = def.GetParameters();
			int next = 0;
			foreach (ParameterInfo p in ps)
			{
				if (IsOutOnly(p)) continue;
				if (next >= args.Length) break;
				object arg = Plain(args[next++]);
				if (arg != null && !(arg is CallbackRef))
				{
					Infer(p.ParameterType, arg.GetType(), map);
				}
			}
			Type[] gps = def.GetGenericArguments();
			Type[] closed = new Type[gps.Length];
			for (int i = 0; i < gps.Length; i++)
			{
				if (map.TryGetValue(gps[i], out Type found))
				{
					closed[i] = found;
					continue;
				}
				/* a type parameter that the arguments do not tell: object when a parameter uses it (OrderBy<T, TKey>(source, Func<T, TKey>));
				   when no parameter uses it at all (Lambda<TDelegate>(body, parameters)) the overload is skipped instead of guessed */
				bool used = false;
				foreach (ParameterInfo p in ps)
				{
					if (TypeUses(p.ParameterType, gps[i])) used = true;
				}
				if (!used) return null;
				closed[i] = typeof(object);
			}
			try { return def.MakeGenericMethod(closed); }
			catch (ArgumentException) { return null; }
		}

		private static void Infer(Type param, Type arg, Dictionary<Type, Type> map)
		{
			if (param.IsByRef) { Infer(param.GetElementType(), arg, map); return; }
			if (param.IsGenericParameter)
			{
				if (!map.ContainsKey(param)) map[param] = arg;
				return;
			}
			if (param.IsArray)
			{
				if (arg.IsArray) Infer(param.GetElementType(), arg.GetElementType(), map);
				return;
			}
			if (!param.IsGenericType) return;
			Type def = param.GetGenericTypeDefinition();
			List<Type> sources = new List<Type> { arg };
			sources.AddRange(arg.GetInterfaces());
			for (Type b = arg.BaseType; b != null; b = b.BaseType) sources.Add(b);
			foreach (Type t in sources)
			{
				if (t.IsGenericType && t.GetGenericTypeDefinition() == def)
				{
					Type[] pa = param.GetGenericArguments();
					Type[] aa = t.GetGenericArguments();
					for (int i = 0; i < pa.Length && i < aa.Length; i++) Infer(pa[i], aa[i], map);
					return;
				}
			}
		}

		/* The methods of a type that have a name: found once (the reflection arrays are copied on every call) */
		private static readonly System.Collections.Concurrent.ConcurrentDictionary<(Type, string, BindingFlags), MethodInfo[]> MethodCache =
			new System.Collections.Concurrent.ConcurrentDictionary<(Type, string, BindingFlags), MethodInfo[]>();

		private static IEnumerable<MethodInfo> MethodsNamed(Type t, string name, BindingFlags flags)
		{
			return MethodCache.GetOrAdd((t, name, flags), key => FindMethodsNamed(key.Item1, key.Item2, key.Item3));
		}

		private static MethodInfo[] FindMethodsNamed(Type t, string name, BindingFlags flags)
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
			return found.ToArray();
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
			ConstructorInfo ctor = Pick(t.GetConstructors(BindingFlags.Public | BindingFlags.Instance), args, out object[] conv) as ConstructorInfo;
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
			MethodInfo m = Pick(MethodsNamed(t, name, flags), args, out object[] conv) as MethodInfo;
			if (m == null)
			{
				throw new MissingMethodException("No public method " + t.FullName + "." + name + " matches the " + args.Length + " argument(s)");
			}
			return InvokeResult(m, instance, conv);
		}

		/* Run a method and shape its result: methods with out/ref parameters return a list [return value (if any), out/ref values...] */
		private static object InvokeResult(MethodInfo m, object instance, object[] conv)
		{
			object returned = m.Invoke(instance, conv);
			if (ByRefCount(m) == 0)
			{
				return returned;
			}
			List<object> results = new List<object>();
			if (m.ReturnType != typeof(void))
			{
				results.Add(returned);
			}
			ParameterInfo[] mps = m.GetParameters();
			for (int i = 0; i < mps.Length; i++)
			{
				if (mps[i].ParameterType.IsByRef) results.Add(conv[i]);
			}
			return results;
		}

		/* ---------------------------------------------------------------- named arguments */

		/* [ [name, value], ... ] --> names and values */
		private static void SplitPairs(object pairs, out string[] names, out object[] values)
		{
			object[] list = Plain(pairs) as object[] ?? new object[0];
			names = new string[list.Length];
			values = new object[list.Length];
			for (int i = 0; i < list.Length; i++)
			{
				object[] pair = Plain(list[i]) as object[];
				if (pair == null || pair.Length != 2 || !(Plain(pair[0]) is string))
				{
					throw new ArgumentException("Named arguments must be a list of [name, value] pairs: [ :name = value, ... ]");
				}
				names[i] = (string)Plain(pair[0]);
				values[i] = pair[1];
			}
		}

		/* Choose the overload whose parameter names include all the given names and all the required parameters */
		/* for each parameter the index of the argument with its name (-1: not given), or null when a name matches no parameter */
		private static int[] MatchNames(ParameterInfo[] ps, string[] names)
		{
			int[] given = new int[ps.Length];
			for (int i = 0; i < given.Length; i++) given[i] = -1;
			for (int k = 0; k < names.Length; k++)
			{
				int found = -1;
				for (int i = 0; i < ps.Length; i++)
				{
					if (!IsOutOnly(ps[i]) && string.Equals(ps[i].Name, names[k], StringComparison.OrdinalIgnoreCase)) { found = i; break; }
				}
				if (found < 0 || given[found] >= 0) return null;
				given[found] = k;
			}
			return given;
		}

		private static MethodBase PickNamed(IEnumerable<MethodBase> candidates, string[] names, object[] values, out object[] converted)
		{
			MethodBase best = null;
			object[] bestArgs = null;
			int bestScore = int.MinValue;
			foreach (MethodBase candidate in candidates)
			{
				MethodBase m = candidate;
				if (m is MethodInfo def && def.IsGenericMethodDefinition)
				{
					/* a generic method (Enumerable.Contains<T>(source, value)): match the names, then close it with the types of the values */
					int[] openGiven = MatchNames(def.GetParameters(), names);
					if (openGiven == null) continue;
					object[] ordered = new object[openGiven.Length];
					for (int i = 0; i < ordered.Length; i++) ordered[i] = openGiven[i] >= 0 ? values[openGiven[i]] : null;
					m = CloseGeneric(def, ordered);
					if (m == null) continue;
				}
				if (m.ContainsGenericParameters) continue;
				ParameterInfo[] ps = m.GetParameters();
				int[] given = MatchNames(ps, names);
				if (given == null) continue;
				bool ok = true;
				object[] conv = new object[ps.Length];
				int total = 0;
				for (int i = 0; i < ps.Length && ok; i++)
				{
					Type pt = ps[i].ParameterType.IsByRef ? ps[i].ParameterType.GetElementType() : ps[i].ParameterType;
					if (IsOutOnly(ps[i]))
					{
						conv[i] = pt.IsValueType ? Activator.CreateInstance(pt) : null;
					}
					else if (given[i] >= 0)
					{
						ok = TryConvert(values[given[i]], pt, out conv[i], out int sc);
						total += sc;
					}
					else if (ps[i].IsOptional)
					{
						conv[i] = ps[i].HasDefaultValue ? ps[i].DefaultValue : Type.Missing;
					}
					else ok = false;
				}
				/* fewer parameters left unset is a better match */
				total -= ps.Count(p => !IsOutOnly(p)) - names.Length;
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

		private static string Describe(string[] names)
		{
			return names.Length == 0 ? "no arguments" : string.Join(", ", names);
		}

		/* oObject.callMethodNamed("Round", [ ["value", 3.14159], ["digits", 2] ]): the parameter names choose the overload */
		private static object CallMethodNamed(object target, string name, object pairs)
		{
			SplitPairs(pairs, out string[] names, out object[] values);
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
				if (target == null) throw new NullReferenceException("Can't call '" + name + "' on a null object");
				instance = target;
				t = target.GetType();
				flags = InstanceFlags;
			}
			object[] conv;
			MethodInfo m = PickNamed(MethodsNamed(t, name, flags), names, values, out conv) as MethodInfo;
			if (m == null && instance != null)
			{
				/* an object also gives access to the static methods of its class (Process.Start(startInfo)) */
				m = PickNamed(MethodsNamed(t, name, StaticFlags), names, values, out conv) as MethodInfo;
				instance = null;
			}
			if (m == null)
			{
				throw new MissingMethodException("No public method " + t.FullName + "." + name + " has the parameters (" + Describe(names) + ")");
			}
			return InvokeResult(m, instance, conv);
		}

		private static object CreateInstanceNamed(Type t, object pairs)
		{
			SplitPairs(pairs, out string[] names, out object[] values);
			if (t.IsAbstract) throw new InvalidOperationException("Can't create an instance of the abstract type " + t.FullName);
			if (names.Length == 0 && t.IsValueType) return Activator.CreateInstance(t);
			ConstructorInfo ctor = PickNamed(t.GetConstructors(BindingFlags.Public | BindingFlags.Instance), names, values, out object[] conv) as ConstructorInfo;
			if (ctor == null)
			{
				throw new MissingMethodException("No public constructor of " + t.FullName + " has the parameters (" + Describe(names) + ")");
			}
			return ctor.Invoke(conv);
		}

		/* A property by name; a property that hides one of a base class (CheckedListBox.Items) is the one of the most derived type */
		private static PropertyInfo FindProperty(Type t, string name, BindingFlags f)
		{
			try
			{
				return t.GetProperty(name, f);
			}
			catch (AmbiguousMatchException)
			{
				PropertyInfo best = null;
				foreach (PropertyInfo p in t.GetProperties(f))
				{
					if (p.Name != name && !(f.HasFlag(BindingFlags.IgnoreCase) && string.Equals(p.Name, name, StringComparison.OrdinalIgnoreCase))) continue;
					if (p.GetIndexParameters().Length > 0) continue;
					if (best == null || best.DeclaringType.IsAssignableFrom(p.DeclaringType)) best = p;
				}
				return best;
			}
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
				PropertyInfo p = FindProperty(t, name, f);
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
				PropertyInfo p = FindProperty(t, name, f);
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
