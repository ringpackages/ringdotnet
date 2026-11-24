/* Calls with named arguments: matching the names to the parameters of the candidates. */

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
					else if (DeclaredParameter(m, ps[i]).IsOptional)
					{
						ParameterInfo declared = DeclaredParameter(m, ps[i]);
						conv[i] = declared.HasDefaultValue ? declared.DefaultValue : Type.Missing;
					}
					else if (IsParams(ps[i])) conv[i] = Array.CreateInstance(pt.GetElementType(), 0);
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
			return UsesIl(ctor) ? InvokeConstructor(ctor, conv) : ctor.Invoke(conv);
		}
	}
}
