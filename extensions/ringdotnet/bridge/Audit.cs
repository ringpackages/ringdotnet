/* Audit of the public API of an assembly: how much of it can Ring use, and what gets in the way?
   The rules are those of the bridge itself (Bridge.Usable, Bridge.NotInferable, and the types that the generator wraps), so the report says
   what the generator really does. The answer is a list of [tag, count, [up to three examples]], read by tools/dotnettools/auditassembly.ring.

   Tags that start with GAP are things that Ring cannot use today; INFO tags describe what is there; OK tags are supported. */

using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

namespace RingDotNet
{
	internal static class Audit
	{
		private sealed class Tally
		{
			private readonly SortedDictionary<string, int> counts = new SortedDictionary<string, int>(StringComparer.Ordinal);
			private readonly Dictionary<string, List<string>> examples = new Dictionary<string, List<string>>();

			public void Add(string tag, string example)
			{
				counts.TryGetValue(tag, out int n);
				counts[tag] = n + 1;
				if (!examples.TryGetValue(tag, out List<string> list))
				{
					list = new List<string>();
					examples[tag] = list;
				}
				if (list.Count < 3 && example != null) list.Add(example);
			}

			public RingList Result()
			{
				RingList result = new RingList();
				foreach (KeyValuePair<string, int> item in counts)
				{
					result.Add(new RingList { item.Key, (double)item.Value, new RingList(examples[item.Key]) });
				}
				return result;
			}
		}

		private static bool IsRefLike(Type t)
		{
			if (t.IsByRef) t = t.GetElementType();
			return t.IsByRefLike || (t.IsGenericType && t.GetGenericArguments().Any(g => g.IsByRefLike));
		}

		private static bool IsPointer(Type t)
		{
			if (t.IsByRef) t = t.GetElementType();
			return t.IsPointer;
		}

		/* An interface or abstract class that a program has to implement itself, as far as one can tell from the type: Ring can pass what it can
		   make (texts, numbers, lists for the collection interfaces, delegates through callbacks, objects of wrapped classes), but it cannot
		   write a class that implements an interface */
		private static bool NeedsImplementation(Type t)
		{
			if (t.IsByRef) t = t.GetElementType();
			if (!(t.IsInterface || (t.IsAbstract && !t.IsSealed))) return false;
			if (typeof(Delegate).IsAssignableFrom(t)) return false;
			if (t == typeof(object) || t == typeof(Type) || t == typeof(System.IO.Stream)) return false;
			if (t.IsGenericType)
			{
				Type d = t.GetGenericTypeDefinition();
				if (d == typeof(IEnumerable<>) || d == typeof(ICollection<>) || d == typeof(IList<>) || d == typeof(IReadOnlyList<>) ||
					d == typeof(IReadOnlyCollection<>) || d == typeof(IDictionary<,>) || d == typeof(IReadOnlyDictionary<,>) ||
					d == typeof(ISet<>) || d == typeof(IEnumerable<>)) return false;
			}
			if (t == typeof(System.Collections.IEnumerable) || t == typeof(System.Collections.ICollection) || t == typeof(System.Collections.IList) ||
				t == typeof(IDisposable) || t == typeof(IFormatProvider) || t == typeof(IComparable)) return false;
			return true;
		}

		private static string Short(Type t, string member)
		{
			return (t.FullName ?? t.Name) + "." + member;
		}

		public static RingList Assembly(Assembly asm)
		{
			Tally tally = new Tally();
			Type[] types;
			try { types = asm.GetExportedTypes(); }
			catch (ReflectionTypeLoadException ex) { types = Array.FindAll(ex.Types, x => x != null); }

			foreach (Type t in types)
			{
				string name = t.FullName ?? t.Name;
				tally.Add("INFO type: public types", name);

				/* what kind of type, and whether the generator wraps it */
				if (t.IsEnum) { tally.Add("OK   type: enum (a text in Ring)", name); continue; }
				if (typeof(Delegate).IsAssignableFrom(t)) { tally.Add("OK   type: delegate (a callback in Ring)", name); continue; }
				if (typeof(Attribute).IsAssignableFrom(t)) { tally.Add("INFO type: attribute (not wrapped)", name); continue; }
				if (typeof(Exception).IsAssignableFrom(t)) { tally.Add("INFO type: exception (not wrapped)", name); continue; }
				if (t.IsDefined(typeof(ObsoleteAttribute), false)) { tally.Add("INFO type: obsolete (not wrapped)", name); continue; }

				int members = CountMembers(t);
				if (t.IsNested) { tally.Add("GAP  type: nested type (not wrapped)", name); AddMembers(tally, members); continue; }
				if (t.IsGenericTypeDefinition) { tally.Add("GAP  type: generic type definition (not wrapped)", name); AddMembers(tally, members); continue; }
				if (t.IsByRefLike) { tally.Add("GAP  type: ref struct (cannot be an object)", name); AddMembers(tally, members); continue; }

				tally.Add("OK   type: wrapped (class, struct, interface)", name);
				if (t.IsInterface) tally.Add("INFO type: interface", name);
				else if (t.IsAbstract && t.IsSealed) tally.Add("INFO type: static class", name);
				else if (t.IsAbstract) tally.Add("INFO type: abstract class", name);
				else if (t.IsValueType) tally.Add("INFO type: struct", name);
				if (!t.IsInterface && !t.IsAbstract && t.GetConstructors(BindingFlags.Public | BindingFlags.Instance).Length == 0)
				{
					tally.Add("INFO type: no public constructor (made by a factory method)", name);
				}

				/* constructors */
				foreach (ConstructorInfo c in t.GetConstructors(BindingFlags.Public | BindingFlags.Instance))
				{
					tally.Add("INFO ctor: public constructors", Short(t, ".ctor"));
					if (!Bridge.Usable(c)) tally.Add("GAP  ctor: not callable (pointer or ref struct parameter)", Short(t, ".ctor"));
				}

				HashSet<string> callableNames = new HashSet<string>(t.GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static).Where(x => !x.IsSpecialName && Bridge.Usable(x) && !(x.IsGenericMethodDefinition && Bridge.NotInferable(x))).Select(x => x.Name));
				/* methods, like Describe: public instance and static, no accessors or operators */
				foreach (MethodInfo m in t.GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly))
				{
					if (m.IsSpecialName)
					{
						if (m.Name.StartsWith("op_", StringComparison.Ordinal)) tally.Add("GAP  method: operator (op_Addition ... not exposed)", Short(t, m.Name));
						continue;
					}
					string where = Short(t, m.Name);
					tally.Add("INFO method: public methods", where);
					ParameterInfo[] ps = m.GetParameters();
					if (ps.Any(p => IsPointer(p.ParameterType)) || ps.Any(p => IsRefLike(p.ParameterType)) || !Bridge.Usable(m))
					{
						string kind = ps.Any(p => IsPointer(p.ParameterType)) ? "pointer parameter" : ps.Any(p => IsRefLike(p.ParameterType)) ? "Span or other ref struct parameter" : "other";
						if (callableNames.Contains(m.Name)) tally.Add("INFO method: not callable (" + kind + "), but another overload of the name is", where);
						else tally.Add("GAP  method: not callable (" + kind + "), no other overload of the name", where);
					}
					else if (m.IsGenericMethodDefinition && Bridge.NotInferable(m))
					{
						if (callableNames.Contains(m.Name)) tally.Add("INFO method: generic with the type argument only in the result, but another overload of the name is callable", where);
						else tally.Add("GAP  method: not callable (generic, type argument only in the result), no other overload of the name", where);
					}
					else tally.Add("OK   method: callable", where);
					if (IsPointer(m.ReturnType) || IsRefLike(m.ReturnType)) tally.Add("GAP  method: pointer or ref struct result", where);
					if (m.ReturnType.IsByRef) tally.Add("GAP  method: ref return", where);
					if (m.IsGenericMethodDefinition)
					{
						tally.Add("INFO method: generic method", where);
						if (Bridge.NotInferable(m)) tally.Add("INFO method: generic with a type argument that no parameter shows (DeserializeObject<T> ...)", where);
					}
					if (m.IsDefined(typeof(System.Runtime.CompilerServices.ExtensionAttribute), false)) tally.Add("OK   method: extension method (added to the class it extends)", where);
					if (m.IsAbstract && m.IsStatic) tally.Add("GAP  method: static abstract (interface)", where);
					Type rt = m.ReturnType;
					if (typeof(System.Threading.Tasks.Task).IsAssignableFrom(rt) || (rt.IsGenericType && rt.GetGenericTypeDefinition().FullName == "System.Threading.Tasks.ValueTask`1") || rt.FullName == "System.Threading.Tasks.ValueTask")
						tally.Add("INFO method: asynchronous (Task, ValueTask)", where);
					if (rt.IsGenericType && rt.GetGenericTypeDefinition().FullName == "System.Collections.Generic.IAsyncEnumerable`1")
						tally.Add("GAP  method: IAsyncEnumerable result (no await foreach in Ring)", where);
					if (ps.Any(p => NeedsImplementation(p.ParameterType)))
						tally.Add("INFO method: a parameter is an interface or abstract class (only an existing object can be passed)", where);
					if (ps.Any(p => typeof(Delegate).IsAssignableFrom(p.ParameterType)))
						tally.Add("OK   method: delegate parameter (a callback in Ring)", where);
					if (ps.Any(p => p.IsOptional)) tally.Add("OK   method: optional parameters (named arguments)", where);
					if (ps.Any(p => p.GetCustomAttribute<ParamArrayAttribute>() != null)) tally.Add("OK   method: params array (a plain list)", where);
				}

				/* members the interfaces of the type bring in */
				if (!t.IsInterface)
				{
					int explicitMethods = t.GetMethods(BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.DeclaredOnly).Count(m => m.IsFinal && m.IsPrivate && m.Name.Contains('.'));
					for (int i = 0; i < explicitMethods; i++) tally.Add("OK   method: explicit interface implementation (found through the interface)", name);
				}

				/* properties, fields, events */
				foreach (PropertyInfo p in t.GetProperties(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly))
				{
					string where = Short(t, p.Name);
					int indexParameters = p.GetIndexParameters().Length;
					if (indexParameters == 0) tally.Add("INFO property: public properties", where);
					else if (indexParameters == 1) tally.Add("OK   property: indexer with one index (Item, SetItem)", where);
					else tally.Add("GAP  property: indexer with several indexes", where);
					if (IsRefLike(p.PropertyType) || IsPointer(p.PropertyType)) tally.Add("GAP  property: pointer or ref struct type", where);
					if (p.PropertyType.IsByRef) tally.Add("GAP  property: ref property", where);
				}
				foreach (FieldInfo f in t.GetFields(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly))
				{
					tally.Add("INFO field: public fields", Short(t, f.Name));
					if (IsRefLike(f.FieldType) || IsPointer(f.FieldType)) tally.Add("GAP  field: pointer or ref struct type", Short(t, f.Name));
				}
				foreach (EventInfo ev in t.GetEvents(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly))
				{
					tally.Add("OK   event: setXXXEvent / clearXXXEvent", Short(t, ev.Name));
				}
			}
			return tally.Result();
		}

		private static int CountMembers(Type t)
		{
			try
			{
				return t.GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly).Count(m => !m.IsSpecialName)
					+ t.GetConstructors(BindingFlags.Public | BindingFlags.Instance).Length
					+ t.GetProperties(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly).Length;
			}
			catch (Exception) { return 0; }
		}

		private static void AddMembers(Tally tally, int members)
		{
			for (int i = 0; i < members; i++) tally.Add("GAP  members of types that are not wrapped", null);
		}
	}
}
