/* Extension methods: collecting them from the loaded assemblies and finding the ones of a type. */

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

		private static bool ImplementsDefinition(Type type, Type definition)
		{
			for (Type t = type; t != null; t = t.BaseType)
			{
				if (t.IsGenericType && t.GetGenericTypeDefinition() == definition) return true;
			}
			return type.GetInterfaces().Any(i => i.IsGenericType && i.GetGenericTypeDefinition() == definition);
		}

		/* Do extension methods extend this type (or, for a generic type, its definition)? Used for delegate types: a delegate gets a Ring class only then. */
		private static bool HasExtensionMethods(Type t)
		{
			if (t == typeof(Delegate) || t == typeof(MulticastDelegate)) return false;          /* the base types of all delegates have no class */
			ScanExtensions();
			MethodInfo[] all;
			lock (ExtensionSync) { all = ExtensionMethods.ToArray(); }
			Type definition = t.IsGenericType ? t.GetGenericTypeDefinition() : t;
			foreach (MethodInfo m in all)
			{
				Type first = Unwrap(m.GetParameters()[0].ParameterType);
				if (first == t || (first.IsGenericType && first.GetGenericTypeDefinition() == definition)) return true;
			}
			return false;
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
						Type first = Unwrap(m.GetParameters()[0].ParameterType);          /* this in S (a struct passed by reference) is S */
						if (!first.ContainsGenericParameters && first.IsAssignableFrom(key.Item1)) found.Add(m);
						/* the extended type is a generic type (IValidator<T>): the class must be, or implement, a closed type of that definition; the
						   type arguments of the method are then inferred from the object */
						else if (first.IsGenericType && first.ContainsGenericParameters && ImplementsDefinition(key.Item1, first.GetGenericTypeDefinition())) found.Add(m);
					}
					if (found.Count > 0) break;
				}
				return found.ToArray();
			});
		}
	}
}
