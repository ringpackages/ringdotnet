/* Finding a .NET type by its name. */

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
	public static unsafe partial class Bridge
	{
		/* A loaded assembly runs its module initializer at once (RingDotNet.Data uses it to find the native SQLite library of the system) */
		private static Assembly Initialize(Assembly assembly)
		{
			System.Runtime.CompilerServices.RuntimeHelpers.RunModuleConstructor(assembly.ManifestModule.ModuleHandle);
			return assembly;
		}

		/* The type of a name: a plain name ("System.IO.File", "System.IO.File, System.Runtime") or a closed generic type; raises an error when
		   there is no such type */
		private static string TypeKind(string name)
		{
			Type t = null;
			try { t = ResolveType(name); } catch (Exception) { }
			if (t == null) return "";
			if (t.IsInterface) return "interface";
			if (t.IsEnum) return "enum";
			if (typeof(Delegate).IsAssignableFrom(t)) return "delegate";
			if (t.IsValueType) return "struct";
			if (t.IsAbstract && !t.IsSealed) return "abstract";
			return "class";
		}

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
	}
}
