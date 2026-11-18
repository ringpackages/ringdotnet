using System;
using System.IO;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

namespace RingDotNet
{
	/* The SQLite native library is found by the folder of the operating system and the processor: bin/runtimes/<system>-<processor>/native.
	   (Ring hosts the runtime without an app deps.json, so the normal lookup of runtimes/<rid>/native does not happen.) */
	internal static class NativeSqlite
	{
		[ModuleInitializer]
		internal static void Init()
		{
			try
			{
				NativeLibrary.SetDllImportResolver(Assembly.Load("SQLitePCLRaw.provider.e_sqlite3"), Resolve);
			}
			catch (Exception)
			{
				/* the default lookup is used */
			}
		}

		private static IntPtr Resolve(string name, Assembly assembly, DllImportSearchPath? path)
		{
			if (name != "e_sqlite3")
			{
				return IntPtr.Zero;
			}
			string system = RuntimeInformation.IsOSPlatform(OSPlatform.Windows) ? "win"
				: RuntimeInformation.IsOSPlatform(OSPlatform.OSX) ? "osx" : "linux";
			string file = system == "win" ? "e_sqlite3.dll" : system == "osx" ? "libe_sqlite3.dylib" : "libe_sqlite3.so";
			string processor = RuntimeInformation.ProcessArchitecture.ToString().ToLowerInvariant();   /* x64, x86, arm, arm64 */
			string folder = Path.GetDirectoryName(typeof(NativeSqlite).Assembly.Location);
			string candidate = Path.Combine(folder, "runtimes", system + "-" + processor, "native", file);
			if (File.Exists(candidate) && NativeLibrary.TryLoad(candidate, out IntPtr handle))
			{
				return handle;
			}
			return IntPtr.Zero;
		}
	}
}
