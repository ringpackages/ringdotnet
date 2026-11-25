/* Describing the public API of a type: for the class generator, the audit and the documentation tools. */

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
					if (typeof(Delegate).IsAssignableFrom(t) && !HasExtensionMethods(t))
					{
						/* a delegate is a callback in Ring, and has no class, unless extension methods extend it (Sprache's Parser<T>) */
						continue;
					}
					/* the types that the compiler makes (the marker types of C# 14 extension blocks: IArchiveEntryExtensions+<G>$E1C2...) have no Ring name */
					if (t.Name.IndexOf('<') >= 0 || t.Name.IndexOf('$') >= 0)
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
			/* a generic type with a type parameter (IValidator<T> in the parameters of a generic method) has no full name: its definition is named */
			if (t.FullName == null && t.IsGenericType) return t.GetGenericTypeDefinition().FullName ?? t.Name;
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
				if (IsSpan(pt, out _, out _)) continue;          /* a Span<T> parameter: Ring gives an array (see InvokeWithSpans) */
				if (pt.IsByRefLike && !(p.IsOut && !p.IsIn) && RefStructFactory(pt) != null) continue;          /* a ref struct made from a value */
				if (pt.IsPointer && !p.ParameterType.IsByRef && !pt.GetElementType().IsByRefLike) continue;          /* an address or a buffer: see ConvertPointer */
				if (pt.IsFunctionPointer || pt.IsPointer || (pt.IsByRefLike && !pt.IsGenericParameter) || pt.IsByRef || (pt.IsGenericType && pt.GetGenericArguments().Any(g => g.IsByRefLike && !g.IsGenericParameter)))
				{
					return false;
				}
			}
			return true;
		}

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
					if (p.IsIn && !p.IsOut) continue;          /* an in parameter (this in S, a struct passed by reference) is an input only */
					Type element = p.ParameterType.GetElementType();
					if (!element.IsByRefLike || IsSpan(element, out _, out _)) n++;
				}
				else if (IsSpan(p.ParameterType, out _, out bool writable) && writable) n++;
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
			List<object> list = new RingList();
			foreach (ParameterInfo p in m.GetParameters())
			{
				if (IsOutOnly(p)) continue;
				list.Add(TName(p.ParameterType.IsByRef ? p.ParameterType.GetElementType() : p.ParameterType));
			}
			return list;
		}

		/* The types whose members describe t: an interface does not list what it inherits from other interfaces (IXLFont has no Bold: it is
		   a member of IXLFontBase), so the members of the inherited interfaces count as its own. A class lists its inherited members itself. */
		private static IEnumerable<Type> InterfaceAware(Type t)
		{
			if (!t.IsInterface) return new[] { t };
			return new[] { t }.Concat(t.GetInterfaces());
		}

		/* The description of a type for the generator (dnDescribe), a list of: 1 the name, 2 a static class, 3 constructors, 4 methods (the
		   extension methods are marked), 5 properties and fields, 6 the indexer, 7 events, 8 a struct, 9 the assembly, 10 the base type, 11 the
		   interfaces, 12 the operators, 13 the indexers with several indexes, 14 a delegate type */
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
					if (m.IsStatic && m.IsAbstract) continue;          /* a static abstract member of an interface: the classes that implement it have the static method */
					if (HasSpanParameter(m) && plainNames.Contains(m.Name)) continue;
					if (definition != null && m.IsStatic) continue;
					if (t.IsInterface && !seenMethods.Add(m.Name + "(" + string.Join(",", m.GetParameters().Select(q => q.ParameterType.FullName)) + ")")) continue;
					methods.Add(new RingList { m.Name, m.IsStatic, m.ReturnType.IsPointer ? "System.Int64" : TName(Unwrap(m.ReturnType)), ParamTypes(m), ByRefCount(m), RequiredCount(m), m.IsDefined(typeof(System.Runtime.CompilerServices.ExtensionAttribute), false) ? 1 : 0, NotInferable(m) ? 1 : 0 });
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
					members.Add(new RingList { p.Name, canRead, canWrite && !p.PropertyType.IsByRef && !p.PropertyType.IsByRefLike, (p.GetMethod ?? p.SetMethod).IsStatic, TName(Unwrap(p.PropertyType)), p.PropertyType.IsEnum });
				}
				foreach (FieldInfo fi in t.GetFields(f))
				{
					if (definition != null && fi.IsStatic) continue;
					members.Add(new RingList { fi.Name, true, !fi.IsInitOnly && !fi.IsLiteral, fi.IsStatic, TName(fi.FieldType), fi.FieldType.IsEnum });
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
			/* Indexers with several indexes (Matrix[row, column]): [ [indexTypes], valueType, canWrite ] each; Ring gives the indexes as a list */
			List<object> multiIndexers = new RingList();
			foreach (PropertyInfo p in t.GetProperties(BindingFlags.Public | BindingFlags.Instance))
			{
				ParameterInfo[] ips = p.GetIndexParameters();
				if (ips.Length >= 2 && p.GetMethod != null && p.GetMethod.IsPublic)
				{
					multiIndexers.Add(new RingList { new RingList(ips.Select(q => (object)TName(q.ParameterType))), TName(Unwrap(p.PropertyType)), p.SetMethod != null && p.SetMethod.IsPublic });
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
				if (!i.IsVisible || inherited.Contains(i)) continue;
				/* a generic interface is named by its definition (IValidator`1): the extension methods of it are methods of the classes that implement it.
				   The generic interfaces of System (IEnumerable<T>: LINQ) are left out: every collection would get every LINQ method. */
				if (!i.IsGenericType) interfaces.Add(TName(i));
				else if (!(i.Namespace ?? "").StartsWith("System", StringComparison.Ordinal) && !interfaces.Contains(i.GetGenericTypeDefinition().FullName)) interfaces.Add(i.GetGenericTypeDefinition().FullName);
			}
			/* a base class that is a generic type is named by its definition: when the definition has a class, the class derives from it (PersonValidator from AbstractValidator) */
			string baseName = t.BaseType == null ? "" : t.BaseType.IsGenericType ? t.BaseType.GetGenericTypeDefinition().FullName : TName(t.BaseType);
			/* the operators the class has itself (a derived class inherits the Ring method operator of its base class) */
			List<object> operators = new RingList();
			if (!t.IsInterface)
			{
				foreach (MethodInfo m in t.GetMethods(BindingFlags.Public | BindingFlags.Static | BindingFlags.DeclaredOnly))
				{
					if (m.IsSpecialName && OperatorNames.ContainsValue(m.Name) && !operators.Contains(m.Name)) operators.Add(m.Name);
				}
				/* a type that compares (IComparable, IComparable<T>) gets the operators < > <= >= by CompareTo, also when it has no op_LessThan */
				if (!t.IsAbstract && t.GetInterfaces().Any(i => i == typeof(IComparable) || (i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IComparable<>))) && !operators.Contains("IComparable")) operators.Add("IComparable");
			}
			return new RingList { TName(definition ?? t), t.IsAbstract && t.IsSealed, ctors, methods, members, indexer, events, t.IsValueType, t.Assembly.GetName().Name, baseName, interfaces, operators, multiIndexers, typeof(Delegate).IsAssignableFrom(t) };
		}
	}
}
