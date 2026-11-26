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
	/* A value of an exact .NET type for a parameter of type object: Ring has one kind of number, a whole number that goes to an object is an Int32, and
	   dnBox("System.Double",10) is the Double 10 (an Int64, a Single, a Decimal ... the same way) */
	public sealed class Boxed
	{
		public object Value;
		public Boxed(object value) { Value = value; }
		public override string ToString() { return Value == null ? "" : Convert.ToString(Value, System.Globalization.CultureInfo.InvariantCulture); }
	}

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

	public static unsafe partial class Bridge
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
			FillCommandLineArgs();
		}

		/* The program is started by Ring, not by the .NET host: on Linux and macOS Environment.GetCommandLineArgs() is then empty, and a library that reads its
		   first item (System.CommandLine's RootCommand takes the name of the program from it) fails with an index error. Windows gives the command line of
		   the process. An empty answer is made the path of the program, which is what the first item is for a .NET program. */
		private static void FillCommandLineArgs()
		{
			try
			{
				if (Environment.GetCommandLineArgs().Length > 0 || string.IsNullOrEmpty(Environment.ProcessPath)) return;
				foreach (FieldInfo field in typeof(Environment).GetFields(BindingFlags.NonPublic | BindingFlags.Static))
				{
					if (field.FieldType == typeof(string[]) && !field.IsInitOnly)
					{
						field.SetValue(null, new[] { Environment.ProcessPath });
						if (Environment.GetCommandLineArgs().Length > 0) return;
					}
				}
			}
			catch (Exception)
			{
			}
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

		private static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

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
				case "box":
					return new Boxed(Convert.ChangeType(Plain(a[1]), ResolveType(Str(a, 0)), Inv));
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
				case "calls":
					{
						/* the same call; when the method answers the object that it was called on (a fluent method), the answer is SameAsReceiver: Ring keeps the wrapper it has */
						object receiver = a[0];
						object answer = CallMethod(receiver, Str(a, 1), Rest(a, 2));
						return answer != null && !(receiver is TypeRef) && !receiver.GetType().IsValueType && ReferenceEquals(answer, receiver) ? SameAsReceiver.Instance : answer;
					}
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
				case "asyncenumerator":
					return GetAsyncEnumerator(Plain(a[0]));
				case "asyncnext":
					return AsyncNext(Plain(a[0])) ? 1.0 : 0.0;
				case "asyncdispose":
					AsyncDispose(Plain(a[0]));
					return null;
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
				case "typekind":
					/* what a type is, by its name: interface, abstract, class, struct, enum or delegate ("" when the name is not a type): the generator takes the extension methods of a closed generic type only when its type arguments can have other types (interfaces, abstract classes) */
					return TypeKind(Str(a, 0));
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

		private const BindingFlags InstanceFlags = BindingFlags.Public | BindingFlags.Instance;

		private const BindingFlags StaticFlags = BindingFlags.Public | BindingFlags.Static | BindingFlags.FlattenHierarchy;
	}
}
