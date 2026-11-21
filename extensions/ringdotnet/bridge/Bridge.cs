/*
**  RingDotNet bridge - the managed side of the RingDotNet extension.
**
**  The native extension (ring_dotnet.dll) hosts the runtime and calls Bridge.Invoke with one
**  request. A request/response is a sequence of "items":   <tag><byte length>:<data>
**
**      s  string (UTF-8 bytes, or any bytes: a byte[] is a string item)
**      n  number (invariant decimal text)       d  double (the 8 bytes of the number)
**      b  boolean ("1" or "0")                  z  null (length 0)
**      o  object handle (decimal id)            l  list (data = nested items)
**      c  Ring callback (Ring code, or the name of a Ring function; request only)
**      e  error (message, response only)
**
**  A request is:  s<operation> item item ...      A response is exactly one item.
**  Objects never cross the boundary: .NET objects live in a handle table and Ring holds the ids. A byte[] does cross it (as a
**  copy, in both directions), except inside a ByteBuffer: that object holds a live byte[] for the methods that fill an array.
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
	/* A byte[] that Ring can keep. A byte[] that .NET returns becomes a Ring text (a copy), and a Ring text becomes a new array when it is
	   passed in, so a method that FILLS an array (Stream.Read, Socket.Receive...) would fill a copy that Ring never sees. A ByteBuffer
	   is a normal .NET object: Ring holds its handle, a parameter of type byte[] (or object) gets the live array inside it, and
	   GetBytes(count) copies what was written into a Ring text. */
	public sealed class ByteBuffer
	{
		public byte[] Data;
		public ByteBuffer(int size) { Data = new byte[size]; }
		public ByteBuffer(byte[] data) { Data = (byte[])data.Clone(); }
		public int Length { get { return Data.Length; } }
		public byte[] GetBytes(int count) { byte[] part = new byte[Math.Min(count, Data.Length)]; Array.Copy(Data, part, part.Length); return part; }
	}

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
			/* Native libraries of a package (SkiaSharp, for example) are in runtimes/<system>-<architecture>/native next to its DLL after dotnet publish.
			   A program that is not started from its own folder does not look there, so this finds them. */
			System.Runtime.Loader.AssemblyLoadContext.Default.ResolvingUnmanagedDll += FindNativeLibrary;
		}

		private static IntPtr FindNativeLibrary(Assembly assembly, string name)
		{
			string location = assembly.Location;
			if (string.IsNullOrEmpty(location)) return IntPtr.Zero;
			string folder = Path.GetDirectoryName(location);
			string system = RuntimeInformation.IsOSPlatform(OSPlatform.Windows) ? "win" : RuntimeInformation.IsOSPlatform(OSPlatform.OSX) ? "osx" : "linux";
			string architecture = RuntimeInformation.ProcessArchitecture.ToString().ToLowerInvariant();
			string[] folders = { folder, Path.Combine(folder, "runtimes", system + "-" + architecture, "native"), Path.Combine(folder, "runtimes", system, "native") };
			string[] names = { name, name + ".dll", name + ".so", "lib" + name + ".so", name + ".dylib", "lib" + name + ".dylib" };
			foreach (string dir in folders)
			{
				foreach (string candidate in names)
				{
					string file = Path.Combine(dir, candidate);
					if (File.Exists(file) && NativeLibrary.TryLoad(file, out IntPtr handle)) return handle;
				}
			}
			return IntPtr.Zero;
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
				/* a closed generic type is also known by its definition (List`1): the generated class of the definition wraps it */
				if (t.IsGenericType) sb.Append('|').Append(t.GetGenericTypeDefinition().FullName);
			}
			/* then the interfaces (a class that is not generated can still be wrapped as ICryptoTransform, IDisposable...).
			   The most specific interface comes first: the one named after the class by the usual rule (XLWorksheet --> IXLWorksheet),
			   then the ones that inherit the most interfaces. GetInterfaces gives no useful order, and a class that is not public
			   (it is returned as the interface) would be wrapped as the first interface that has a wrapper, often a general one. */
			string conventional = "I" + type.Name;
			Type[] interfaces = type.GetInterfaces().OrderBy(i => i.Name == conventional ? 0 : 1).ThenByDescending(i => i.GetInterfaces().Length).ToArray();
			foreach (Type i in interfaces)
			{
				if (i.IsVisible && count++ < 40)
				{
					sb.Append('|').Append(i.FullName ?? i.Name);
					if (i.IsGenericType) sb.Append('|').Append(i.GetGenericTypeDefinition().FullName);
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
				case List<object> list when RingList.IsResult(list):
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

		/* The arrays that were pinned for the pointer parameters of a request: they are valid during the call and freed after it */
		[ThreadStatic] private static List<GCHandle> pinned;
		[ThreadStatic] private static int requestDepth;

		private static object Dispatch(List<object> items)
		{
			requestDepth++;
			try { return DispatchCore(items); }
			finally
			{
				/* a callback can make a request while a request runs: the pins are freed when the outer one ends */
				if (--requestDepth == 0 && pinned != null)
				{
					foreach (GCHandle handle in pinned) handle.Free();
					pinned.Clear();
				}
			}
		}

		private static object DispatchCore(List<object> items)
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
				case "handlecount":
					return (double)Handles.Count;          /* the objects that Ring holds (for tests of the release of handles) */
				case "load":
					return Initialize(Assembly.LoadFrom(Str(a, 0))).FullName;
				case "loadname":
					return Initialize(Assembly.Load(Str(a, 0))).FullName;
				case "type":
					return new TypeRef(ResolveType(Str(a, 0)));
				case "new":
					return CreateInstance(TypeOf(a, 0), Rest(a, 1));
				case "call":
					return CallMethod(a[0], Str(a, 1), Rest(a, 2));
				case "operator":
					return CallOperator(a[0], Str(a, 1), a.Length > 2 ? a[2] : null);
				case "convert":
					return ConvertValue(a[0], TypeOf(a, 1));
				case "callgeneric":
					return CallMethodGeneric(a[0], Str(a, 1), a[2], Rest(a, 3));
				case "callnamed":
					return CallMethodNamed(a[0], Str(a, 1), a.Length > 2 ? a[2] : null);
				case "newnamed":
					return CreateInstanceNamed(TypeOf(a, 0), a.Length > 1 ? a[1] : null);
				/* the same, answering with the handle of the new object as a number (0 for a value such as an Int32 that has no object): the
				   generated classes only need the handle, so the object is not described and wrapped for Ring */
				case "newhandle":
					return NewHandle(CreateInstance(TypeOf(a, 0), Rest(a, 1)));
				case "newnamedhandle":
					return NewHandle(CreateInstanceNamed(TypeOf(a, 0), a.Length > 1 ? a[1] : null));
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
				case "registerext":
					return RegisterExtensions(Str(a, 0));
				case "extensionclasses":
					return ExtensionClassesOf(a);
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
					return new RingList(Enum.GetNames(TypeOf(a, 0)));
				case "apidoc":
					return ApiDoc(ResolveType(Str(a, 0)));
				case "auditassembly":
					/* the audit of the public API of an assembly (a file path or a name): see Audit.cs */
					return Audit.Assembly(File.Exists(Str(a, 0)) ? System.Reflection.Assembly.LoadFrom(Str(a, 0)) : System.Reflection.Assembly.Load(Str(a, 0)));
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

		/* A loaded assembly runs its module initializer at once (RingDotNet.Data uses it to find the native SQLite library of the system) */
		private static Assembly Initialize(Assembly assembly)
		{
			System.Runtime.CompilerServices.RuntimeHelpers.RunModuleConstructor(assembly.ManifestModule.ModuleHandle);
			return assembly;
		}

		/* The type of a name: a plain name ("System.IO.File", "System.IO.File, System.Runtime") or a closed generic type; raises an error when
		   there is no such type */
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

		/* The type of a name without generic arguments: the name is tried as it is, then in the assemblies of its namespace, which are
		   loaded when needed; null when there is none */
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
			foreach (string extra in new[] { "System.IO.Compression.Brotli", "System.IO.FileSystem.DriveInfo", "System.IO.FileSystem.Watcher", "System.Collections.NonGeneric", "Microsoft.Extensions.Configuration.Json", "Microsoft.Extensions.Configuration.EnvironmentVariables", "Microsoft.Extensions.Configuration.Binder", "Microsoft.Extensions.Configuration.CommandLine", "Microsoft.Extensions.Configuration.Ini", "Microsoft.Extensions.Configuration.Xml", "Microsoft.Extensions.Configuration.FileExtensions", "Microsoft.Extensions.FileProviders.Physical", "System.Net.Http.Json", "System.Linq.Expressions", "System.Collections.Concurrent", "System.Threading.Channels", "System.Numerics.Vectors" })
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
			List<object> tokens = new RingList();
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
			return new RingList(found);
		}

		/* Public classes and structs of a namespace that are worth wrapping in Ring */
		/* The public static classes with extension methods of assemblies (the generator describes only these to find the extension methods) */
		private static List<object> ExtensionClassesOf(object[] assemblyNames)
		{
			List<string> found = new List<string>();
			foreach (object n in assemblyNames)
			{
				if (!(n is string an)) continue;
				Assembly asm;
				try { asm = Assembly.Load(an); } catch (Exception) { continue; }
				Type[] types;
				try { types = asm.GetExportedTypes(); }
				catch (ReflectionTypeLoadException ex) { types = Array.FindAll(ex.Types, x => x != null); }
				catch (Exception) { continue; }
				foreach (Type t in types)
				{
					if (t.IsNested || !t.IsSealed || !t.IsAbstract || t.IsGenericTypeDefinition || t.FullName == null) continue;
					try
					{
						if (t.IsDefined(typeof(System.Runtime.CompilerServices.ExtensionAttribute), false) && !found.Contains(t.FullName)) found.Add(t.FullName);
					}
					catch (Exception) { }
				}
			}
			found.Sort(StringComparer.Ordinal);
			return new RingList(found);
		}

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
					if (t.Namespace != ns || t.IsEnum || t.IsByRefLike)
					{
						continue;
					}
					if (typeof(Delegate).IsAssignableFrom(t))
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
			return new RingList(found);
		}

		private static string TName(Type t)
		{
			if (t.IsPointer) return "System.IntPtr";          /* an address: Ring gives a number or a buffer */
			return t.FullName ?? t.Name;
		}

		internal static bool Usable(MethodBase m, bool openType = false)
		{
			if (!openType && m.ContainsGenericParameters && !(m is MethodInfo gm && gm.IsGenericMethodDefinition))
			{
				return false;
			}
			foreach (ParameterInfo p in m.GetParameters())
			{
				Type pt = p.ParameterType.IsByRef ? p.ParameterType.GetElementType() : p.ParameterType;
				if (m is MethodInfo && IsSpan(pt, out _, out _)) continue;          /* a Span<T> parameter: Ring gives an array (see InvokeWithSpans) */
				if (m is MethodInfo && pt.IsByRefLike && !(p.IsOut && !p.IsIn) && RefStructFactory(pt) != null) continue;          /* a ref struct made from a value */
				if (pt.IsPointer && !p.ParameterType.IsByRef && !pt.GetElementType().IsByRefLike) continue;          /* an address or a buffer: see ConvertPointer */
				if (pt.IsFunctionPointer || pt.IsPointer || pt.IsByRefLike || pt.IsByRef || (pt.IsGenericType && pt.GetGenericArguments().Any(g => g.IsByRefLike)))
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
			List<object> list = new RingList();
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
			List<object> ctors = new RingList();
			if (!t.IsAbstract)
			{
				foreach (ConstructorInfo c in t.GetConstructors(BindingFlags.Public | BindingFlags.Instance))
				{
					if (Usable(c)) ctors.Add(ApiParams(c));
				}
			}
			r["ctors"] = ctors;
			List<object> methods = new RingList();
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
			List<object> props = new RingList();
			List<object> fields = new RingList();
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
			List<object> indexers = new RingList();
			foreach (PropertyInfo p in InterfaceAware(t).SelectMany(x => x.GetProperties(BindingFlags.Public | BindingFlags.Instance)))
			{
				ParameterInfo[] ips = p.GetIndexParameters();
				if (ips.Length == 1 && p.GetMethod != null && p.GetMethod.IsPublic)
				{
					indexers.Add(new Dictionary<string, object> { { "i", Pretty(ips[0].ParameterType) }, { "n", ips[0].Name ?? "" }, { "t", Pretty(p.PropertyType) }, { "w", p.SetMethod != null && p.SetMethod.IsPublic ? 1 : 0 } });
					break;
				}
			}
			r["indexers"] = indexers;
			List<object> events = new RingList();
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

		/* The parameters that answer a value: ref and out (a ref struct that was made for the call is not answered), and the Span<T> that the method
		   writes to (the filled array is answered) */
		private static int ByRefCount(MethodBase m)
		{
			int n = 0;
			foreach (ParameterInfo p in m.GetParameters())
			{
				if (p.ParameterType.IsByRef)
				{
					Type element = p.ParameterType.GetElementType();
					if (!element.IsByRefLike || IsSpan(element, out _, out _)) n++;
				}
				else if (IsSpan(p.ParameterType, out _, out bool writable) && writable) n++;
			}
			return n;
		}

		/* Span<T> and ReadOnlySpan<T> */
		internal static bool IsSpan(Type t, out Type element, out bool writable)
		{
			element = null;
			writable = false;
			if (!t.IsGenericType) return false;
			Type def = t.GetGenericTypeDefinition();
			if (def != typeof(Span<>) && def != typeof(ReadOnlySpan<>)) return false;
			element = t.GetGenericArguments()[0];
			writable = def == typeof(Span<>);
			return true;
		}

		private static Type Unwrap(Type t)
		{
			return t.IsByRef ? t.GetElementType() : t;
		}

		/* A ref struct of a library (MessagePackWriter, Utf8JsonReader) cannot be held by Ring or boxed. A parameter of such a type is made for the
		   call from one value: a public op_Implicit(X) or a public constructor whose first parameter is X (the others optional), with X something
		   Ring can give (a text, an array, an object). The struct is not answered: what the method does to it is lost. */
		private static readonly System.Collections.Concurrent.ConcurrentDictionary<Type, MethodBase> RefStructFactories =
			new System.Collections.Concurrent.ConcurrentDictionary<Type, MethodBase>();

		internal static MethodBase RefStructFactory(Type refStruct)
		{
			return RefStructFactories.GetOrAdd(refStruct, FindRefStructFactory);
		}

		private static bool Convertible(Type source)
		{
			return !source.IsPointer && !source.IsByRef && (!source.IsByRefLike || IsSpan(source, out _, out _));
		}

		private static MethodBase FindRefStructFactory(Type r)
		{
			foreach (MethodInfo m in r.GetMethods(BindingFlags.Public | BindingFlags.Static))
			{
				if (m.Name == "op_Implicit" && m.ReturnType == r && m.GetParameters().Length == 1 && Convertible(m.GetParameters()[0].ParameterType)) return m;
			}
			ConstructorInfo best = null;
			foreach (ConstructorInfo c in r.GetConstructors(BindingFlags.Public | BindingFlags.Instance))
			{
				ParameterInfo[] cps = c.GetParameters();
				if (cps.Length == 0 || !Convertible(cps[0].ParameterType) || cps.Skip(1).Any(q => !q.IsOptional)) continue;
				if (best == null || cps.Length < best.GetParameters().Length) best = c;
			}
			return best;
		}

		private static Type FactorySource(MethodBase factory)
		{
			return factory.GetParameters()[0].ParameterType;
		}

		/* A method that is called through IL (see InvokeWithSpans): a Span or ref struct parameter, or a Span or ref struct result */
		private static bool UsesIl(MethodBase m)
		{
			return m.GetParameters().Any(p => { Type t = Unwrap(p.ParameterType); return IsSpan(t, out _, out _) || (t.IsByRefLike && RefStructFactory(t) != null); })
				|| (m is MethodInfo mi && (IsSpan(mi.ReturnType, out _, out _) || (mi.ReturnType.IsByRefLike && ResultPlanOf(mi.ReturnType) != null)));
		}

		/* A ref struct that a method returns cannot be boxed. It is answered as what it holds when it can be read in one go: an array (a ToArray
		   method), a list of its items (a ref struct enumerator, or one with GetEnumerator: foreach), or a text (the one method without parameters
		   that returns a string: ToString, utf8_to_string). */
		internal sealed class ResultPlan
		{
			public string Kind;            // "array", "list", "text"
			public MethodInfo Method;      // ToArray, or the method that gives the text, or GetEnumerator (null when the struct is the enumerator)
			public Type Enumerator;
			public MethodInfo MoveNext, Current;
		}

		private static readonly System.Collections.Concurrent.ConcurrentDictionary<Type, ResultPlan> ResultPlans =
			new System.Collections.Concurrent.ConcurrentDictionary<Type, ResultPlan>();

		internal static ResultPlan ResultPlanOf(Type refStruct)
		{
			return ResultPlans.GetOrAdd(refStruct, FindResultPlan);
		}

		private static ResultPlan FindResultPlan(Type r)
		{
			const BindingFlags own = BindingFlags.Public | BindingFlags.Instance;
			MethodInfo toArray = r.GetMethod("ToArray", own, null, Type.EmptyTypes, null);
			if (toArray != null && toArray.ReturnType.IsArray) return new ResultPlan { Kind = "array", Method = toArray };
			MethodInfo getEnumerator = r.GetMethod("GetEnumerator", own, null, Type.EmptyTypes, null);
			Type enumerator = getEnumerator != null ? getEnumerator.ReturnType : r;
			MethodInfo moveNext = enumerator.GetMethod("MoveNext", own, null, Type.EmptyTypes, null);
			PropertyInfo current = enumerator.GetProperty("Current", own);
			if (moveNext != null && moveNext.ReturnType == typeof(bool) && current?.GetMethod != null && !(current.PropertyType.IsByRefLike && !IsSpan(current.PropertyType, out _, out _)))
			{
				return new ResultPlan { Kind = "list", Method = getEnumerator, Enumerator = enumerator, MoveNext = moveNext, Current = current.GetMethod };
			}
			MethodInfo text = r.GetMethod("ToString", own, null, Type.EmptyTypes, null);
			if (text == null || text.DeclaringType != r)
			{
				MethodInfo[] texts = r.GetMethods(own | BindingFlags.DeclaredOnly).Where(x => x.ReturnType == typeof(string) && x.GetParameters().Length == 0 && !x.IsSpecialName).ToArray();
				text = texts.Length == 1 ? texts[0] : null;
			}
			return text != null ? new ResultPlan { Kind = "text", Method = text } : null;
		}

		/* an item of the list that a ref struct enumerator gives: a char array is a text */
		public static void AddResultItem(List<object> list, object item)
		{
			list.Add(item is char[] chars ? new string(chars) : item);
		}

		private static void EmitInstanceCall(System.Reflection.Emit.ILGenerator il, System.Reflection.Emit.LocalBuilder local, MethodInfo method)
		{
			if (local.LocalType.IsValueType)
			{
				il.Emit(System.Reflection.Emit.OpCodes.Ldloca, local);
				il.Emit(System.Reflection.Emit.OpCodes.Call, method);
			}
			else
			{
				il.Emit(System.Reflection.Emit.OpCodes.Ldloc, local);
				il.Emit(System.Reflection.Emit.OpCodes.Callvirt, method);
			}
		}

		/* the ref struct on the stack becomes the object that is answered */
		private static void EmitRefStructResult(System.Reflection.Emit.ILGenerator il, Type refStruct)
		{
			ResultPlan plan = ResultPlanOf(refStruct);
			System.Reflection.Emit.LocalBuilder value = il.DeclareLocal(refStruct);
			il.Emit(System.Reflection.Emit.OpCodes.Stloc, value);
			if (plan.Kind == "array" || plan.Kind == "text")
			{
				il.Emit(System.Reflection.Emit.OpCodes.Ldloca, value);
				il.Emit(System.Reflection.Emit.OpCodes.Call, plan.Method);
				return;
			}
			System.Reflection.Emit.LocalBuilder list = il.DeclareLocal(typeof(RingList));
			il.Emit(System.Reflection.Emit.OpCodes.Newobj, typeof(RingList).GetConstructor(Type.EmptyTypes));
			il.Emit(System.Reflection.Emit.OpCodes.Stloc, list);
			System.Reflection.Emit.LocalBuilder enumerator = il.DeclareLocal(plan.Enumerator);
			if (plan.Method != null)
			{
				il.Emit(System.Reflection.Emit.OpCodes.Ldloca, value);
				il.Emit(System.Reflection.Emit.OpCodes.Call, plan.Method);
			}
			else il.Emit(System.Reflection.Emit.OpCodes.Ldloc, value);
			il.Emit(System.Reflection.Emit.OpCodes.Stloc, enumerator);
			System.Reflection.Emit.Label top = il.DefineLabel();
			System.Reflection.Emit.Label end = il.DefineLabel();
			il.MarkLabel(top);
			EmitInstanceCall(il, enumerator, plan.MoveNext);
			il.Emit(System.Reflection.Emit.OpCodes.Brfalse, end);
			il.Emit(System.Reflection.Emit.OpCodes.Ldloc, list);
			EmitInstanceCall(il, enumerator, plan.Current);
			Type item = plan.Current.ReturnType;
			if (IsSpan(item, out _, out _))
			{
				System.Reflection.Emit.LocalBuilder span = il.DeclareLocal(item);
				il.Emit(System.Reflection.Emit.OpCodes.Stloc, span);
				il.Emit(System.Reflection.Emit.OpCodes.Ldloca, span);
				il.Emit(System.Reflection.Emit.OpCodes.Call, item.GetMethod("ToArray", Type.EmptyTypes));
			}
			else if (item.IsValueType) il.Emit(System.Reflection.Emit.OpCodes.Box, item);
			il.Emit(System.Reflection.Emit.OpCodes.Call, typeof(Bridge).GetMethod("AddResultItem"));
			il.Emit(System.Reflection.Emit.OpCodes.Br, top);
			il.MarkLabel(end);
			il.Emit(System.Reflection.Emit.OpCodes.Ldloc, list);
		}

		/* A parameter that Ring does not give as it is: the overloads with it are listed only when no other overload of the name has a plain form */
		private static bool HasSpanParameter(MethodBase m)
		{
			return UsesIl(m) || m.GetParameters().Any(p => Unwrap(p.ParameterType).IsPointer);
		}

		private static readonly System.Collections.Concurrent.ConcurrentDictionary<MethodInfo, Func<object, object[], object>> SpanCalls =
			new System.Collections.Concurrent.ConcurrentDictionary<MethodInfo, Func<object, object[], object>>();

		/* A method with a Span<T> or ReadOnlySpan<T> parameter or result, or a ref struct parameter, cannot be called by reflection (a ref struct
		   cannot be boxed). A small method is made with IL for it: it takes the object[] of the arguments, makes each span around the array that Ring
		   gave (and each ref struct from its value), calls the method, and puts the values of ref and out parameters back into the array (a span as
		   an array). A Span result is answered as an array. */
		private static object InvokeWithSpans(MethodInfo m, object instance, object[] conv)
		{
			ParameterInfo[] ps = m.GetParameters();
			for (int i = 0; i < ps.Length; i++)
			{
				Type pt = Unwrap(ps[i].ParameterType);
				if (conv[i] == Type.Missing || (conv[i] == null && pt.IsValueType && !pt.IsByRefLike && Nullable.GetUnderlyingType(pt) == null))
				{
					conv[i] = pt.IsValueType && !pt.IsByRefLike ? Activator.CreateInstance(pt) : null;
				}
			}
			return SpanCalls.GetOrAdd(m, BuildSpanCall)(instance, conv);
		}

		/* the argument i of the object[] as a value of the type: a span from its array, a ref struct from its source value, any other value unboxed */
		private static void EmitValue(System.Reflection.Emit.ILGenerator il, Type type, int index)
		{
			il.Emit(System.Reflection.Emit.OpCodes.Ldarg_1);
			il.Emit(System.Reflection.Emit.OpCodes.Ldc_I4, index);
			il.Emit(System.Reflection.Emit.OpCodes.Ldelem_Ref);
			if (IsSpan(type, out Type element, out _))
			{
				il.Emit(System.Reflection.Emit.OpCodes.Castclass, element.MakeArrayType());
				il.Emit(System.Reflection.Emit.OpCodes.Call, type.GetMethod("op_Implicit", new[] { element.MakeArrayType() }));
			}
			else if (type.IsByRefLike)
			{
				MethodBase factory = RefStructFactory(type);
				Type source = FactorySource(factory);
				if (IsSpan(source, out Type sourceElement, out _))
				{
					il.Emit(System.Reflection.Emit.OpCodes.Castclass, sourceElement.MakeArrayType());
					il.Emit(System.Reflection.Emit.OpCodes.Call, source.GetMethod("op_Implicit", new[] { sourceElement.MakeArrayType() }));
				}
				else il.Emit(System.Reflection.Emit.OpCodes.Unbox_Any, source);
				if (factory is ConstructorInfo ctor)
				{
					foreach (ParameterInfo rest in ctor.GetParameters().Skip(1)) EmitDefault(il, rest.ParameterType);
					il.Emit(System.Reflection.Emit.OpCodes.Newobj, ctor);
				}
				else il.Emit(System.Reflection.Emit.OpCodes.Call, (MethodInfo)factory);
			}
			else il.Emit(System.Reflection.Emit.OpCodes.Unbox_Any, type);
		}

		private static void EmitDefault(System.Reflection.Emit.ILGenerator il, Type type)
		{
			if (!type.IsValueType) { il.Emit(System.Reflection.Emit.OpCodes.Ldnull); return; }
			System.Reflection.Emit.LocalBuilder temp = il.DeclareLocal(type);
			il.Emit(System.Reflection.Emit.OpCodes.Ldloca, temp);
			il.Emit(System.Reflection.Emit.OpCodes.Initobj, type);
			il.Emit(System.Reflection.Emit.OpCodes.Ldloc, temp);
		}

		private static Func<object, object[], object> BuildSpanCall(MethodInfo m)
		{
			ParameterInfo[] ps = m.GetParameters();
			Type declaring = m.DeclaringType;
			System.Reflection.Emit.DynamicMethod dm = new System.Reflection.Emit.DynamicMethod("SpanCall", typeof(object), new[] { typeof(object), typeof(object[]) }, typeof(Bridge).Module, true);
			System.Reflection.Emit.ILGenerator il = dm.GetILGenerator();
			System.Reflection.Emit.LocalBuilder[] locals = new System.Reflection.Emit.LocalBuilder[ps.Length];
			for (int i = 0; i < ps.Length; i++)
			{
				if (!ps[i].ParameterType.IsByRef) continue;
				Type et = ps[i].ParameterType.GetElementType();
				locals[i] = il.DeclareLocal(et);
				if (IsSpan(et, out Type spanElement, out _))
				{
					/* a span that is passed by reference: made from the array when there is one, else the empty span (an out parameter) */
					System.Reflection.Emit.LocalBuilder array = il.DeclareLocal(spanElement.MakeArrayType());
					System.Reflection.Emit.Label none = il.DefineLabel();
					il.Emit(System.Reflection.Emit.OpCodes.Ldarg_1);
					il.Emit(System.Reflection.Emit.OpCodes.Ldc_I4, i);
					il.Emit(System.Reflection.Emit.OpCodes.Ldelem_Ref);
					il.Emit(System.Reflection.Emit.OpCodes.Castclass, spanElement.MakeArrayType());
					il.Emit(System.Reflection.Emit.OpCodes.Stloc, array);
					il.Emit(System.Reflection.Emit.OpCodes.Ldloc, array);
					il.Emit(System.Reflection.Emit.OpCodes.Brfalse, none);
					il.Emit(System.Reflection.Emit.OpCodes.Ldloc, array);
					il.Emit(System.Reflection.Emit.OpCodes.Call, et.GetMethod("op_Implicit", new[] { spanElement.MakeArrayType() }));
					il.Emit(System.Reflection.Emit.OpCodes.Stloc, locals[i]);
					il.MarkLabel(none);
				}
				else if (et.IsByRefLike)
				{
					EmitValue(il, et, i);
					il.Emit(System.Reflection.Emit.OpCodes.Stloc, locals[i]);
				}
				else
				{
					il.Emit(System.Reflection.Emit.OpCodes.Ldarg_1);
					il.Emit(System.Reflection.Emit.OpCodes.Ldc_I4, i);
					il.Emit(System.Reflection.Emit.OpCodes.Ldelem_Ref);
					il.Emit(System.Reflection.Emit.OpCodes.Unbox_Any, et);
					il.Emit(System.Reflection.Emit.OpCodes.Stloc, locals[i]);
				}
			}
			if (!m.IsStatic)
			{
				il.Emit(System.Reflection.Emit.OpCodes.Ldarg_0);
				if (declaring.IsValueType) il.Emit(System.Reflection.Emit.OpCodes.Unbox, declaring);
				else il.Emit(System.Reflection.Emit.OpCodes.Castclass, declaring);
			}
			for (int i = 0; i < ps.Length; i++)
			{
				if (locals[i] != null) il.Emit(System.Reflection.Emit.OpCodes.Ldloca, locals[i]);
				else EmitValue(il, ps[i].ParameterType, i);
			}
			il.Emit(m.IsStatic || declaring.IsValueType ? System.Reflection.Emit.OpCodes.Call : System.Reflection.Emit.OpCodes.Callvirt, m);
			System.Reflection.Emit.LocalBuilder result = il.DeclareLocal(typeof(object));
			if (m.ReturnType == typeof(void)) il.Emit(System.Reflection.Emit.OpCodes.Ldnull);
			else if (IsSpan(m.ReturnType, out Type resultElement, out _))
			{
				/* a Span result is answered as an array */
				System.Reflection.Emit.LocalBuilder span = il.DeclareLocal(m.ReturnType);
				il.Emit(System.Reflection.Emit.OpCodes.Stloc, span);
				il.Emit(System.Reflection.Emit.OpCodes.Ldloca, span);
				il.Emit(System.Reflection.Emit.OpCodes.Call, m.ReturnType.GetMethod("ToArray", Type.EmptyTypes));
			}
			else if (m.ReturnType.IsByRefLike) EmitRefStructResult(il, m.ReturnType);
			else if (m.ReturnType.IsValueType) il.Emit(System.Reflection.Emit.OpCodes.Box, m.ReturnType);
			il.Emit(System.Reflection.Emit.OpCodes.Stloc, result);
			for (int i = 0; i < ps.Length; i++)
			{
				if (locals[i] == null) continue;
				Type et = ps[i].ParameterType.GetElementType();
				if (et.IsByRefLike && !IsSpan(et, out _, out _)) continue;
				il.Emit(System.Reflection.Emit.OpCodes.Ldarg_1);
				il.Emit(System.Reflection.Emit.OpCodes.Ldc_I4, i);
				if (IsSpan(et, out _, out _))
				{
					il.Emit(System.Reflection.Emit.OpCodes.Ldloca, locals[i]);
					il.Emit(System.Reflection.Emit.OpCodes.Call, et.GetMethod("ToArray", Type.EmptyTypes));
				}
				else
				{
					il.Emit(System.Reflection.Emit.OpCodes.Ldloc, locals[i]);
					if (et.IsValueType) il.Emit(System.Reflection.Emit.OpCodes.Box, et);
				}
				il.Emit(System.Reflection.Emit.OpCodes.Stelem_Ref);
			}
			il.Emit(System.Reflection.Emit.OpCodes.Ldloc, result);
			il.Emit(System.Reflection.Emit.OpCodes.Ret);
			return (Func<object, object[], object>)dm.CreateDelegate(typeof(Func<object, object[], object>));
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
			List<object> list = new RingList();
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
		/* A generic method whose type parameters are not all found in its parameters (Cast<T>(IEnumerable), AddSingleton<T>(IServiceCollection)) cannot be called
		   from Ring: nothing says what T is. The generator leaves such extension methods out. */
		internal static bool NotInferable(MethodInfo m)
		{
			if (!m.IsGenericMethodDefinition) return false;
			foreach (Type argument in m.GetGenericArguments())
			{
				bool found = false;
				foreach (ParameterInfo p in m.GetParameters())
				{
					if (Mentions(p.ParameterType, argument)) { found = true; break; }
				}
				if (!found) return true;
			}
			return false;
		}

		private static bool Mentions(Type type, Type argument)
		{
			if (type == argument) return true;
			if (type.HasElementType) return Mentions(type.GetElementType(), argument);
			if (type.IsGenericType)
			{
				foreach (Type inner in type.GetGenericArguments())
				{
					if (Mentions(inner, argument)) return true;
				}
			}
			return false;
		}

		/* The types whose members describe t: an interface does not list what it inherits from other interfaces (IXLFont has no Bold: it is
		   a member of IXLFontBase), so the members of the inherited interfaces count as its own. A class lists its inherited members itself. */
		private static IEnumerable<Type> InterfaceAware(Type t)
		{
			if (!t.IsInterface) return new[] { t };
			return new[] { t }.Concat(t.GetInterfaces());
		}

		/* The type of a generic definition that describes it: closed over object (or int, string when a constraint does not allow object), so that the
		   members have types; null when no such type exists */
		internal static Type CloseOverObject(Type def)
		{
			Type[] parameters = def.GetGenericArguments();
			Func<Type, Type>[] choices =
			{
				g =>
				{
					if ((g.GenericParameterAttributes & GenericParameterAttributes.NotNullableValueTypeConstraint) != 0) return typeof(int);
					foreach (Type c in g.GetGenericParameterConstraints())
					{
						if (!c.ContainsGenericParameters) return c;
					}
					return typeof(object);
				},
				g => typeof(int),
				g => typeof(string)
			};
			foreach (Func<Type, Type> choose in choices)
			{
				try { return def.MakeGenericType(parameters.Select(choose).ToArray()); }
				catch (ArgumentException) { }
			}
			return null;
		}

		private static List<object> Describe(Type t)
		{
			Type definition = null;
			bool openType = false;
			if (t.IsGenericTypeDefinition)
			{
				/* a generic definition is described by its members, with object for the type arguments; its static members need a closed type, so
				   they are left out */
				definition = t;
				/* a definition that no simple type closes (TAssertions : Assertions<TAssertions>, T : struct, Enum) is described as it is, open: its
				   members have the type parameters in their types, which the generator reads as objects */
				Type closed = CloseOverObject(t);
				if (closed != null) t = closed; else openType = true;
			}
			List<object> ctors = new RingList();
			if (!t.IsAbstract)
			{
				/* a constructor with a pointer parameter is listed only when the type has no other constructor that is usable (like the overloads
				   with a Span) */
				bool plainConstructor = t.GetConstructors(BindingFlags.Public | BindingFlags.Instance).Any(c => Usable(c, openType) && !HasSpanParameter(c));
				foreach (ConstructorInfo c in t.GetConstructors(BindingFlags.Public | BindingFlags.Instance))
				{
					if (!Usable(c, openType)) continue;
					if (plainConstructor && HasSpanParameter(c)) continue;
					List<object> types = ParamTypes(c);
					ctors.Add(types);
					/* optional parameters: the constructor is also available with fewer parameters */
					for (int cut = types.Count - 1; cut >= RequiredCount(c); cut--)
					{
						ctors.Add(new RingList(types.GetRange(0, cut)));
					}
				}
			}
			List<object> methods = new RingList();
			/* a method with a Span parameter is listed only when no other overload of the name has a plain form (Stream.Write(buffer, offset, count)
			   keeps its place; the Span overload is still reached by callMethod) */
			HashSet<string> plainNames = new HashSet<string>(InterfaceAware(t).SelectMany(x => x.GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static))
				.Where(x => !x.IsSpecialName && Usable(x, openType) && !HasSpanParameter(x)).Select(x => x.Name));
			foreach (BindingFlags f in new[] { BindingFlags.Public | BindingFlags.Instance, BindingFlags.Public | BindingFlags.Static })
			{
				HashSet<string> seenMethods = new HashSet<string>();
				foreach (MethodInfo m in InterfaceAware(t).SelectMany(x => x.GetMethods(f)))
				{
					if (m.IsSpecialName || !Usable(m, openType)) continue;
					if (HasSpanParameter(m) && plainNames.Contains(m.Name)) continue;
					if (definition != null && m.IsStatic) continue;
					if (t.IsInterface && !seenMethods.Add(m.Name + "(" + string.Join(",", m.GetParameters().Select(q => q.ParameterType.FullName)) + ")")) continue;
					methods.Add(new RingList { m.Name, m.IsStatic, m.ReturnType.IsPointer ? "System.Int64" : TName(m.ReturnType), ParamTypes(m), ByRefCount(m), RequiredCount(m), m.IsDefined(typeof(System.Runtime.CompilerServices.ExtensionAttribute), false) ? 1 : 0, NotInferable(m) ? 1 : 0 });
				}
			}
			List<object> members = new RingList();
			foreach (BindingFlags f in new[] { BindingFlags.Public | BindingFlags.Instance, BindingFlags.Public | BindingFlags.Static })
			{
				HashSet<string> seenProperties = new HashSet<string>();
				foreach (PropertyInfo p in InterfaceAware(t).SelectMany(x => x.GetProperties(f)))
				{
					if (p.GetIndexParameters().Length > 0) continue;
					if (t.IsInterface && !seenProperties.Add(p.Name)) continue;
					if (definition != null && (p.GetMethod ?? p.SetMethod).IsStatic) continue;
					bool canRead = p.GetMethod != null && p.GetMethod.IsPublic;
					bool canWrite = p.SetMethod != null && p.SetMethod.IsPublic;
					members.Add(new RingList { p.Name, canRead, canWrite, (p.GetMethod ?? p.SetMethod).IsStatic, TName(p.PropertyType) });
				}
				foreach (FieldInfo fi in t.GetFields(f))
				{
					if (definition != null && fi.IsStatic) continue;
					members.Add(new RingList { fi.Name, true, !fi.IsInitOnly && !fi.IsLiteral, fi.IsStatic, TName(fi.FieldType) });
				}
			}
			/* Indexer (like List[i] or Dictionary[key]): [indexType, valueType, canWrite] */
			List<object> indexer = new RingList();
			foreach (PropertyInfo p in t.GetProperties(BindingFlags.Public | BindingFlags.Instance))
			{
				ParameterInfo[] ips = p.GetIndexParameters();
				if (ips.Length == 1 && p.GetMethod != null && p.GetMethod.IsPublic)
				{
					indexer = new RingList { TName(ips[0].ParameterType), TName(p.PropertyType), p.SetMethod != null && p.SetMethod.IsPublic };
					break;
				}
			}
			/* Events: [name, isStatic, handlerType] */
			List<object> events = new RingList();
			foreach (BindingFlags f in new[] { BindingFlags.Public | BindingFlags.Instance, BindingFlags.Public | BindingFlags.Static })
			{
				HashSet<string> seenEvents = new HashSet<string>();
				foreach (EventInfo ev in InterfaceAware(t).SelectMany(x => x.GetEvents(f)))
				{
					if (t.IsInterface && !seenEvents.Add(ev.Name)) continue;
					if (definition != null && f.HasFlag(BindingFlags.Static)) continue;
					events.Add(new RingList { ev.Name, f.HasFlag(BindingFlags.Static), TName(ev.EventHandlerType) });
				}
			}
			/* the interfaces that the class implements and its base class does not (the extension methods of an interface are methods of the classes that implement it) */
			List<object> interfaces = new RingList();
			HashSet<Type> inherited = new HashSet<Type>(t.IsInterface || t.BaseType == null ? Type.EmptyTypes : t.BaseType.GetInterfaces());
			foreach (Type i in t.GetInterfaces())
			{
				if (i.IsVisible && !i.IsGenericType && !inherited.Contains(i)) interfaces.Add(TName(i));
			}
			string baseName = t.BaseType == null ? "" : definition != null && t.BaseType.IsGenericType ? t.BaseType.GetGenericTypeDefinition().FullName : TName(t.BaseType);
			/* the operators the class has itself (a derived class inherits the Ring method operator of its base class) */
			List<object> operators = new RingList();
			if (!t.IsInterface)
			{
				foreach (MethodInfo m in t.GetMethods(BindingFlags.Public | BindingFlags.Static | BindingFlags.DeclaredOnly))
				{
					if (m.IsSpecialName && OperatorNames.ContainsValue(m.Name) && !operators.Contains(m.Name)) operators.Add(m.Name);
				}
			}
			return new RingList { TName(definition ?? t), t.IsAbstract && t.IsSealed, ctors, methods, members, indexer, events, t.IsValueType, t.Assembly.GetName().Name, baseName, interfaces, operators };
		}

		private static List<object> ToList(object target)
		{
			if (!(Plain(target) is IEnumerable en) || target is string)
			{
				throw new ArgumentException("The object is not enumerable");
			}
			List<object> list = new RingList();
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

		/* A pointer parameter (byte*, char*, void*, int*): a number is the address (from Marshal.AllocHGlobal, a native library ...); a text, a byte
		   string, a list, a ByteBuffer or null is a buffer that is pinned for the call (a text and a byte string end with a zero, for the C strings),
		   so the address is valid during the call only; a ByteBuffer is the live array, which the called method may fill. */
		private static unsafe bool ConvertPointer(object v, Type t, out object result, out int score)
		{
			result = null;
			score = 0;
			Type element = t.GetElementType();
			if (element.IsByRef || element.IsByRefLike) return false;
			if (v == null)
			{
				result = Pointer.Box((void*)0, t);
				score = 2;
				return true;
			}
			if (v is IntPtr intPtr) v = (double)(long)intPtr;
			if (v is double number)
			{
				if (number < 0 || number != Math.Floor(number)) return false;
				result = Pointer.Box((void*)(long)number, t);
				score = 3;
				return true;
			}
			if (element.IsPointer) return false;
			Array array = null;
			bool voidOrByte = element == typeof(void) || element == typeof(byte) || element == typeof(sbyte);
			if (v is ByteBuffer buffer && voidOrByte) array = buffer.Data;
			else if (v is string text)
			{
				if (element == typeof(char))
				{
					char[] chars = new char[text.Length + 1];
					text.CopyTo(0, chars, 0, text.Length);
					array = chars;
				}
				else if (voidOrByte)
				{
					byte[] bytes = new byte[Encoding.UTF8.GetByteCount(text) + 1];
					Encoding.UTF8.GetBytes(text, 0, text.Length, bytes, 0);
					array = bytes;
				}
			}
			else if (v is byte[] raw && voidOrByte)
			{
				byte[] bytes = new byte[raw.Length + 1];
				Array.Copy(raw, bytes, raw.Length);
				array = bytes;
			}
			else if (v is object[])
			{
				/* a list: numbers of the element type (bytes for void*) */
				if (TryConvert(v, (element == typeof(void) ? typeof(byte) : element).MakeArrayType(), out object converted, out _)) array = (Array)converted;
			}
			if (array == null) return false;
			if (pinned == null) pinned = new List<GCHandle>();
			GCHandle handle = GCHandle.Alloc(array, GCHandleType.Pinned);
			pinned.Add(handle);
			result = Pointer.Box((void*)handle.AddrOfPinnedObject(), t);
			score = 1;
			return true;
		}

		/* A pointer that a method returns is its address, as a number */
		private static unsafe object PointerResult(object returned)
		{
			return returned is Pointer pointer ? (object)(double)(long)(IntPtr)Pointer.Unbox(pointer) : returned;
		}

		/* Convert a Ring value to a parameter type, score = how good the match is (higher is better) */
		private static bool TryConvert(object v, Type t, out object result, out int score)
		{
			result = null;
			score = 0;
			if (t.IsByRef || t.IsFunctionPointer)
			{
				return false;
			}
			v = Plain(v);
			if (t.IsPointer) return ConvertPointer(v, t, out result, out score);
			Type ut = Nullable.GetUnderlyingType(t) ?? t;
			if ((ut == typeof(IntPtr) || ut == typeof(UIntPtr)) && v is double address && address >= 0 && address == Math.Floor(address))
			{
				result = ut == typeof(IntPtr) ? (object)new IntPtr((long)address) : new UIntPtr((ulong)address);
				score = 5;
				return true;
			}
			if (IsSpan(ut, out Type spanElement, out bool spanWritable))
			{
				/* a Span<T> or ReadOnlySpan<T>: an array of T (a text for char, a byte string or a list for byte ...); a number is the size of a new
				   array for a Span<T> that the method fills */
				if (spanWritable && v is double size && size >= 0 && size == Math.Floor(size) && size < int.MaxValue)
				{
					result = Array.CreateInstance(spanElement, (int)size);
					score = 1;
					return true;
				}
				if (spanElement == typeof(char) && v is string text)
				{
					result = text.ToCharArray();
					score = 1;          /* a plain parameter (a string) wins against a span */
					return true;
				}
				if (TryConvert(v, spanElement.MakeArrayType(), out result, out score))
				{
					score = 1;
					return true;
				}
				return false;
			}
			if (ut.IsByRefLike)
			{
				/* a ref struct of a library: made for the call from its source value (see RefStructFactory) */
				MethodBase factory = RefStructFactory(ut);
				if (factory == null) return false;
				if (!TryConvert(v, FactorySource(factory), out result, out score)) return false;
				score = Math.Max(1, score - 1);
				return true;
			}
			if (v is ByteBuffer buffer && (ut == typeof(byte[]) || ut == typeof(object)))
			{
				result = buffer.Data;               /* the live array, so that the called method fills it */
				score = ut == typeof(byte[]) ? 10 : 1;
				return true;
			}
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
				if (ut == typeof(Enum))
				{
					/* a parameter of the type System.Enum (Humanize(Enum value)) does not say which enum: the text gives the full name of the member,
					   "System.DayOfWeek.Friday" */
					int dot = s.LastIndexOf('.');
					if (dot > 0)
					{
						Type enumType = null;
						try { enumType = ResolveSimple(s.Substring(0, dot)); } catch (Exception) { }
						if (enumType != null && enumType.IsEnum && Enum.TryParse(enumType, s.Substring(dot + 1), true, out object member))
						{
							result = member;
							score = 1;
							return true;
						}
					}
					return false;
				}
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

		/* ---- the overload that was chosen for a kind of arguments is remembered ----
		   Choosing among many overloads (Math.Max has 14) costs more than the call itself. For the same group of candidates and the same
		   KINDS of arguments (the type, and for a number: whole or not and in which range) the choice is the same, so it is made once;
		   the arguments are still converted for the chosen overload, and when that fails the full choice is made again. A text is a kind
		   only when no candidate takes an enum, a Guid, a Type or another type that the text could become at that position (the choice
		   would depend on the text); a list is never remembered. */
		private sealed class PickGroup
		{
			public readonly System.Collections.Concurrent.ConcurrentDictionary<string, MethodBase> Chosen = new System.Collections.Concurrent.ConcurrentDictionary<string, MethodBase>();
			public readonly bool[] TextIsKind = new bool[8];
		}

		private static readonly System.Collections.Concurrent.ConcurrentDictionary<object, PickGroup> PickGroups =
			new System.Collections.Concurrent.ConcurrentDictionary<object, PickGroup>();

		private static bool TextNeutral(Type t)
		{
			Type u = Nullable.GetUnderlyingType(t) ?? t;
			return u == typeof(string) || u == typeof(object) || u == typeof(char) || u == typeof(byte[]) || (u.IsPrimitive && u != typeof(IntPtr) && u != typeof(UIntPtr)) || u == typeof(decimal);
		}

		private static PickGroup GroupOf(IEnumerable<MethodBase> candidates)
		{
			return PickGroups.GetOrAdd(candidates, key =>
			{
				PickGroup g = new PickGroup();
				for (int i = 0; i < g.TextIsKind.Length; i++)
				{
					bool neutral = true;
					foreach (MethodBase m in (IEnumerable<MethodBase>)key)
					{
						ParameterInfo[] ps = m.GetParameters();
						if (m.ContainsGenericParameters) { neutral = false; break; }
						if (i < ps.Length)
						{
							Type pt = ps[i].ParameterType.IsByRef ? ps[i].ParameterType.GetElementType() : ps[i].ParameterType;
							if (!TextNeutral(pt)) { neutral = false; break; }
						}
					}
					g.TextIsKind[i] = neutral;
				}
				return g;
			});
		}

		/* the kinds of the arguments as a text, or null when they are not remembered */
		private static string KindsOf(object[] args, PickGroup group)
		{
			if (args.Length > group.TextIsKind.Length)
			{
				return null;
			}
			StringBuilder sb = new StringBuilder(args.Length * 4);
			for (int i = 0; i < args.Length; i++)
			{
				object v = args[i];
				switch (v)
				{
					case null: sb.Append('z'); break;
					case string str:
						if (!group.TextIsKind[i]) { return null; }
						sb.Append(str.Length == 1 ? 'c' : 's');
						break;
					case bool: sb.Append('b'); break;
					case double d:
						{
							if (d != Math.Floor(d) || double.IsInfinity(d)) { sb.Append('d'); break; }
							sb.Append(d >= 0
								? (d <= 127 ? "p1" : d <= 255 ? "p2" : d <= 32767 ? "p3" : d <= 65535 ? "p4" : d <= 2147483647 ? "p5" : d <= 4294967295 ? "p6" : d < 9.2e18 ? "p7" : "p8")
								: (d >= -128 ? "n1" : d >= -32768 ? "n2" : d >= -2147483648 ? "n3" : d > -9.2e18 ? "n4" : "n5"));
							break;
						}
					case byte[]: sb.Append('y'); break;
					case object[]: return null;
					case TypeRef: sb.Append('R'); break;
					case CallbackRef: sb.Append('k'); break;
					case ByteBuffer: sb.Append('B'); break;
					default: sb.Append('T').Append(v.GetType().TypeHandle.Value.ToInt64().ToString("x")); break;
				}
				sb.Append(',');
			}
			return sb.ToString();
		}

		private static MethodBase PickCached(IEnumerable<MethodBase> candidates, object[] args, out object[] converted)
		{
			PickGroup group = GroupOf(candidates);
			string kinds = KindsOf(args, group);
			if (kinds == null)
			{
				return Pick(candidates, args, out converted);
			}
			if (group.Chosen.TryGetValue(kinds, out MethodBase cached))
			{
				MethodBase again = Pick(new[] { cached }, args, out converted);
				if (again != null)
				{
					return again;
				}
			}
			MethodBase best = Pick(candidates, args, out converted);
			if (best != null)
			{
				group.Chosen[kinds] = best;
			}
			return best;
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
						conv[i] = pt.IsValueType && !pt.IsByRefLike ? Activator.CreateInstance(pt) : null;
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

		private static MethodInfo CloseGeneric(MethodInfo def, object[] args, Type[] typeArgs = null)
		{
			if (typeArgs != null)
			{
				/* the type arguments the caller gave (:typeArguments = [ "System.String" ]): only a generic method with that many fit */
				if (def.GetGenericArguments().Length != typeArgs.Length) return null;
				try { return def.MakeGenericMethod(typeArgs); }
				catch (ArgumentException) { return null; }
			}
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

		/* The handle of a new object; 0 when the value is not an object for Ring (it travels as a text, a number...: see Encode) */
		private static object NewHandle(object value)
		{
			switch (value)
			{
				case null or string or char or bool or byte[] or Enum or decimal or double or float:
				case sbyte or byte or short or ushort or int or uint or long or ulong:
				case List<object> when RingList.IsResult(value):
					return 0.0;
				default:
					return (double)Register(value);
			}
		}

		private static readonly System.Collections.Concurrent.ConcurrentDictionary<Type, ConstructorInfo[]> Constructors =
			new System.Collections.Concurrent.ConcurrentDictionary<Type, ConstructorInfo[]>();

		private static ConstructorInfo[] ConstructorsOf(Type t)
		{
			return Constructors.GetOrAdd(t, type => type.GetConstructors(BindingFlags.Public | BindingFlags.Instance));
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
			ConstructorInfo ctor = PickCached(ConstructorsOf(t), args, out object[] conv) as ConstructorInfo;
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
			MethodInfo m = PickCached(MethodsNamed(t, name, flags), args, out object[] conv) as MethodInfo;
			if (m == null && instance != null)
			{
				m = PickFromInterfaces(t, name, args, out conv);
			}
			if (m == null && instance != null)
			{
				MethodBase[] extensions = ExtensionsFor(t, name);
				if (extensions.Length > 0)
				{
					object[] withTarget = new object[args.Length + 1];
					withTarget[0] = instance;
					Array.Copy(args, 0, withTarget, 1, args.Length);
					m = PickCached(extensions, withTarget, out conv) as MethodInfo;
					if (m != null) instance = null;
				}
			}
			if (m == null)
			{
				throw new MissingMethodException("No public method " + t.FullName + "." + name + " matches the " + args.Length + " argument(s)");
			}
			return InvokeResult(m, instance, conv);
		}

		/* ---------------------------------------------------------------- operators and conversions
		   A class that has operator methods (op_Addition ...) gets the Ring method operator(cOperator, xOther): Ring calls it for o + x, o < x, and
		   for x + o with "r+" (the object comes second). The operator method of either class is used; == and < fall back to Equals and IComparable. */
		internal static readonly Dictionary<string, string> OperatorNames = new Dictionary<string, string>
		{
			{ "+", "op_Addition" }, { "-", "op_Subtraction" }, { "*", "op_Multiply" }, { "/", "op_Division" }, { "%", "op_Modulus" },
			{ "=", "op_Equality" }, { "!=", "op_Inequality" }, { "<", "op_LessThan" }, { ">", "op_GreaterThan" },
			{ "<=", "op_LessThanOrEqual" }, { ">=", "op_GreaterThanOrEqual" }, { "&", "op_BitwiseAnd" }, { "|", "op_BitwiseOr" },
			{ "^", "op_ExclusiveOr" }, { "<<", "op_LeftShift" }, { ">>", "op_RightShift" },
			{ "neg", "op_UnaryNegation" }, { "~", "op_OnesComplement" }, { "not", "op_LogicalNot" }
		};

		private static IEnumerable<MethodBase> OperatorMethods(string name, params object[] operands)
		{
			HashSet<MethodBase> seen = new HashSet<MethodBase>();
			foreach (object operand in operands)
			{
				if (operand == null) continue;
				Type t = operand is TypeRef tr ? tr.Type : operand.GetType();
				foreach (MethodInfo m in t.GetMethods(BindingFlags.Public | BindingFlags.Static | BindingFlags.FlattenHierarchy))
				{
					if (m.IsSpecialName && m.Name == name && seen.Add(m)) yield return m;
				}
			}
		}

		private static object CallOperator(object left, string op, object other)
		{
			bool reversed = op.Length > 1 && op[0] == 'r' && OperatorNames.ContainsKey(op.Substring(1));
			if (reversed) op = op.Substring(1);
			if (!OperatorNames.TryGetValue(op, out string name))
			{
				throw new NotSupportedException("The operator '" + op + "' is not supported for a .NET object");
			}
			bool unary = op == "neg" || op == "~" || op == "not";
			other = Plain(other);
			object[] args = unary ? new[] { left } : reversed ? new[] { other, left } : new[] { left, other };
			MethodInfo m = Pick(OperatorMethods(name, args), args, out object[] conv) as MethodInfo;
			if (m != null) return m.Invoke(null, conv);
			if (!unary)
			{
				if (op == "=" || op == "!=")
				{
					bool equal = Equals(left, other);
					return (op == "=") == equal ? 1.0 : 0.0;
				}
				if ((op == "<" || op == ">" || op == "<=" || op == ">=") && left is IComparable comparable)
				{
					object converted = other;
					if (other != null && other.GetType() != left.GetType() && TryConvert(other, left.GetType(), out object c, out int score)) converted = c;
					int order = comparable.CompareTo(converted);
					if (reversed) order = -order;
					bool result = op == "<" ? order < 0 : op == ">" ? order > 0 : op == "<=" ? order <= 0 : order >= 0;
					return result ? 1.0 : 0.0;
				}
			}
			throw new MissingMethodException("No operator " + name + " of " + left.GetType().FullName + " accepts " + (unary ? "the object" : other == null ? "null" : other.GetType().FullName));
		}

		/* The conversion of a value to a type with op_Implicit / op_Explicit of the value's class or of the target class (the cast of C#), or the
		   plain conversion of the bridge (a number to another number type, a text to a number type ...) */
		private static object ConvertValue(object value, Type target)
		{
			value = Plain(value);
			if (value != null && target.IsInstanceOfType(value)) return value;
			foreach (string name in new[] { "op_Implicit", "op_Explicit" })
			{
				foreach (MethodBase candidate in OperatorMethods(name, value, new TypeRef(target)))
				{
					MethodInfo m = (MethodInfo)candidate;
					if (!target.IsAssignableFrom(m.ReturnType)) continue;
					if (m.GetParameters().Length == 1 && TryConvert(value, m.GetParameters()[0].ParameterType, out object arg, out int score))
					{
						return m.Invoke(null, new[] { arg });
					}
				}
			}
			if (TryConvert(value, target, out object converted, out int s2)) return converted;
			throw new InvalidCastException("Can't convert " + (value == null ? "null" : value.GetType().FullName) + " to " + target.FullName);
		}

		/* Generic methods with the type arguments given: JsonConvert.DeserializeObject<Person>(json). Each generic method of that name with that
		   many type arguments is closed over them; the other methods are not candidates. */
		private static IEnumerable<MethodBase> CloseAll(IEnumerable<MethodBase> candidates, Type[] typeArgs)
		{
			foreach (MethodBase candidate in candidates)
			{
				if (candidate is MethodInfo def && def.IsGenericMethodDefinition)
				{
					MethodInfo closed = CloseGeneric(def, null, typeArgs);
					if (closed != null) yield return closed;
				}
			}
		}

		private static object CallMethodGeneric(object target, string name, object typeNames, object[] args)
		{
			object[] list = Plain(typeNames) as object[] ?? new object[] { Plain(typeNames) };
			Type[] typeArgs = new Type[list.Length];
			for (int i = 0; i < list.Length; i++)
			{
				object item = Plain(list[i]);
				typeArgs[i] = item as Type ?? (item is string text ? ResolveType(text) : throw new ArgumentException("The type arguments must be type names"));
			}
			Type t;
			object instance = null;
			BindingFlags flags;
			if (target is TypeRef tr) { t = tr.Type; flags = StaticFlags; }
			else
			{
				if (target == null) throw new NullReferenceException("Can't call '" + name + "' on a null object");
				instance = target;
				t = target.GetType();
				flags = InstanceFlags;
			}
			object[] conv = null;
			MethodInfo m = Pick(CloseAll(MethodsNamed(t, name, flags), typeArgs), args, out conv) as MethodInfo;
			if (m == null && instance != null)
			{
				m = Pick(CloseAll(MethodsNamed(t, name, StaticFlags), typeArgs), args, out conv) as MethodInfo;
				if (m != null) instance = null;
			}
			if (m == null && instance != null)
			{
				foreach (Type i in t.GetInterfaces())
				{
					if (!i.IsVisible) continue;
					m = Pick(CloseAll(MethodsNamed(i, name, InstanceFlags), typeArgs), args, out conv) as MethodInfo;
					if (m != null) break;
				}
			}
			if (m == null && instance != null)
			{
				object[] withTarget = new object[args.Length + 1];
				withTarget[0] = instance;
				Array.Copy(args, 0, withTarget, 1, args.Length);
				m = Pick(CloseAll(ExtensionsFor(t, name), typeArgs), withTarget, out conv) as MethodInfo;
				if (m != null) instance = null;
			}
			if (m == null)
			{
				throw new MissingMethodException("No public generic method " + t.FullName + "." + name + "<" + string.Join(", ", typeArgs.Select(x => x.Name)) + "> matches the " + args.Length + " argument(s)");
			}
			return InvokeResult(m, instance, conv);
		}

		/* ---------------------------------------------------------------- extension methods
		   The generated class of a type has a method for each extension method of that type (Table.AddColumn("x") is TableExtensions.AddColumn(table, "x")).
		   A call finds the extension methods only after the methods of the object itself: the first time that is needed, the static classes with
		   extension methods of the loaded assemblies are collected (again when an assembly was loaded since). */
		private static readonly object ExtensionSync = new object();
		private static readonly HashSet<Assembly> ExtensionScanned = new HashSet<Assembly>();
		private static readonly List<MethodInfo> ExtensionMethods = new List<MethodInfo>();
		private static readonly System.Collections.Concurrent.ConcurrentDictionary<(Type, string), MethodBase[]> ExtensionCache =
			new System.Collections.Concurrent.ConcurrentDictionary<(Type, string), MethodBase[]>();

		private static void ScanExtensions()
		{
			lock (ExtensionSync)
			{
				bool added = false;
				foreach (Assembly assembly in AppDomain.CurrentDomain.GetAssemblies())
				{
					if (assembly.IsDynamic || !ExtensionScanned.Add(assembly)) continue;
					Type[] types;
					try { types = assembly.GetExportedTypes(); } catch (Exception) { continue; }
					foreach (Type t in types)
					{
						if (!t.IsSealed || !t.IsAbstract || t.IsGenericTypeDefinition) continue;
						try
						{
							if (!t.IsDefined(typeof(System.Runtime.CompilerServices.ExtensionAttribute), false)) continue;
							foreach (MethodInfo m in t.GetMethods(BindingFlags.Public | BindingFlags.Static))
							{
								if (m.IsDefined(typeof(System.Runtime.CompilerServices.ExtensionAttribute), false)) { ExtensionMethods.Add(m); added = true; }
							}
						}
						catch (Exception) { }
					}
				}
				if (added) ExtensionCache.Clear();
			}
		}

		/* A generated method of an extension method asks for its static class before the call: the class is loaded (and its assembly with it) */
		private static object RegisterExtensions(string typeName)
		{
			Type t = null;
			try { t = ResolveSimple(typeName); } catch (Exception) { }
			if (t == null || !t.IsSealed || !t.IsAbstract) return 0;
			ScanExtensions();
			return 1;
		}

		private static MethodBase[] ExtensionsFor(Type target, string name)
		{
			ScanExtensions();
			return ExtensionCache.GetOrAdd((target, name), key =>
			{
				MethodInfo[] all;
				lock (ExtensionSync) { all = ExtensionMethods.ToArray(); }
				List<MethodBase> found = new List<MethodBase>();
				foreach (StringComparison comparison in new[] { StringComparison.Ordinal, StringComparison.OrdinalIgnoreCase })
				{
					foreach (MethodInfo m in all)
					{
						if (!string.Equals(m.Name, key.Item2, comparison)) continue;
						Type first = m.GetParameters()[0].ParameterType;
						if (!first.ContainsGenericParameters && first.IsAssignableFrom(key.Item1)) found.Add(m);
					}
					if (found.Count > 0) break;
				}
				return found.ToArray();
			});
		}

		/* A method that the class implements explicitly (a row of Dapper is a public IDictionary<string, object> and has no public get_Item) is
		   found in the public interfaces of the class. */
		private static MethodInfo PickFromInterfaces(Type t, string name, object[] args, out object[] conv)
		{
			conv = null;
			foreach (Type i in t.GetInterfaces())
			{
				if (!i.IsVisible) continue;
				MethodInfo m = PickCached(MethodsNamed(i, name, InstanceFlags), args, out conv) as MethodInfo;
				if (m != null) return m;
			}
			return null;
		}

		/* Run a method and shape its result: methods with out/ref parameters return a list [return value (if any), out/ref values...] */
		private static object InvokeResult(MethodInfo m, object instance, object[] conv)
		{
			bool spanCall = UsesIl(m);
			object returned = spanCall ? InvokeWithSpans(m, instance, conv) : m.Invoke(instance, conv);
			if (m.ReturnType.IsPointer) returned = PointerResult(returned);
			if (spanCall && returned is char[] returnedChars && m.ReturnType.IsByRefLike) returned = new string(returnedChars);
			if (ByRefCount(m) == 0)
			{
				return returned;
			}
			List<object> results = new RingList();
			if (m.ReturnType != typeof(void))
			{
				results.Add(returned);
			}
			ParameterInfo[] mps = m.GetParameters();
			for (int i = 0; i < mps.Length; i++)
			{
				Type answered = Unwrap(mps[i].ParameterType);
				bool spanParameter = IsSpan(answered, out _, out bool writableSpan);
				if (mps[i].ParameterType.IsByRef ? (!answered.IsByRefLike || spanParameter) : (spanParameter && writableSpan))
				{
					results.Add(spanParameter && conv[i] is char[] chars ? new string(chars) : conv[i]);
				}
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

		/* The reserved pair [ "typeArguments", [ "System.String", ... ] ] is not a parameter: it gives the type arguments of a generic method
		   (JsonConvert.DeserializeObject<T>(json)) that the arguments cannot tell; null when there is none */
		private static Type[] TakeTypeArguments(ref string[] names, ref object[] values)
		{
			int at = Array.FindIndex(names, n => string.Equals(n, "typeArguments", StringComparison.OrdinalIgnoreCase));
			if (at < 0) return null;
			object raw = Plain(values[at]);
			object[] list = raw as object[] ?? new object[] { raw };
			Type[] result = new Type[list.Length];
			for (int i = 0; i < list.Length; i++)
			{
				object item = Plain(list[i]);
				result[i] = item as Type ?? (item is string text ? ResolveType(text) : throw new ArgumentException("typeArguments must be a list of type names"));
			}
			names = names.Where((n, i) => i != at).ToArray();
			values = values.Where((v, i) => i != at).ToArray();
			return result;
		}

		private static MethodBase PickNamed(IEnumerable<MethodBase> candidates, string[] names, object[] values, out object[] converted, Type[] typeArgs = null)
		{
			MethodBase best = null;
			object[] bestArgs = null;
			int bestScore = int.MinValue;
			foreach (MethodBase candidate in candidates)
			{
				MethodBase m = candidate;
				if (typeArgs != null && !(m is MethodInfo given0 && given0.IsGenericMethodDefinition)) continue;
				if (m is MethodInfo def && def.IsGenericMethodDefinition)
				{
					/* a generic method (Enumerable.Contains<T>(source, value)): match the names, then close it with the types of the values */
					int[] openGiven = MatchNames(def.GetParameters(), names);
					if (openGiven == null) continue;
					object[] ordered = new object[openGiven.Length];
					for (int i = 0; i < ordered.Length; i++) ordered[i] = openGiven[i] >= 0 ? values[openGiven[i]] : null;
					m = CloseGeneric(def, ordered, typeArgs);
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
						conv[i] = pt.IsValueType && !pt.IsByRefLike ? Activator.CreateInstance(pt) : null;
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
			Type[] typeArgs = TakeTypeArguments(ref names, ref values);
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
			MethodInfo m = PickNamed(MethodsNamed(t, name, flags), names, values, out conv, typeArgs) as MethodInfo;
			if (m == null && instance != null)
			{
				/* an object also gives access to the static methods of its class (Process.Start(startInfo)) */
				m = PickNamed(MethodsNamed(t, name, StaticFlags), names, values, out conv, typeArgs) as MethodInfo;
				if (m != null) instance = null;
			}
			if (m == null && instance != null)
			{
				foreach (Type i in t.GetInterfaces())
				{
					if (!i.IsVisible) continue;
					m = PickNamed(MethodsNamed(i, name, InstanceFlags), names, values, out conv, typeArgs) as MethodInfo;
					if (m != null) break;
				}
			}
			if (m == null && instance != null)
			{
				foreach (MethodBase candidate in ExtensionsFor(t, name))
				{
					string[] namesWithTarget = new string[names.Length + 1];
					object[] valuesWithTarget = new object[values.Length + 1];
					namesWithTarget[0] = candidate.GetParameters()[0].Name;
					valuesWithTarget[0] = instance;
					Array.Copy(names, 0, namesWithTarget, 1, names.Length);
					Array.Copy(values, 0, valuesWithTarget, 1, values.Length);
					m = PickNamed(new[] { candidate }, namesWithTarget, valuesWithTarget, out conv, typeArgs) as MethodInfo;
					if (m != null) { instance = null; break; }
				}
			}
			if (m == null)
			{
				throw new MissingMethodException("No public method " + t.FullName + "." + name + " has the parameters (" + Describe(names) + ")"
						+ (typeArgs == null ? "" : " and " + typeArgs.Length + " type argument(s)"));
			}
			return InvokeResult(m, instance, conv);
		}

		private static object CreateInstanceNamed(Type t, object pairs)
		{
			SplitPairs(pairs, out string[] names, out object[] values);
			Type[] typeArgs = TakeTypeArguments(ref names, ref values);
			if (t.IsGenericTypeDefinition)
			{
				if (typeArgs == null) throw new ArgumentException("The generic type " + t.FullName + " needs its type arguments: :typeArguments = [ type names ]");
				t = t.MakeGenericType(typeArgs);
			}
			else if (typeArgs != null) throw new ArgumentException(t.FullName + " is not a generic type: :typeArguments does not apply");
			if (t.IsAbstract) throw new InvalidOperationException("Can't create an instance of the abstract type " + t.FullName);
			if (names.Length == 0 && t.IsValueType) return Activator.CreateInstance(t);
			ConstructorInfo ctor = PickNamed(ConstructorsOf(t), names, values, out object[] conv) as ConstructorInfo;
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
