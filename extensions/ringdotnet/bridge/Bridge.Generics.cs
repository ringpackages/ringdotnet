/* Generic methods: closing an open generic method from the arguments, or from the type names that the program gives. */

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
	}
}
