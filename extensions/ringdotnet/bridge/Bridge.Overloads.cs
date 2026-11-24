/* Choosing the overload: the shape of the parameters, the scoring of the candidates, and the cache of the choice for a kind of arguments. */

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

		private static bool IsParams(ParameterInfo p)
		{
			return p.ParameterType.IsArray && p.IsDefined(typeof(ParamArrayAttribute), false);
		}

		/* An override often has no default values of its own: the optional parameters are declared where the method was first declared
		   (ChannelWriter<T>.TryComplete(Exception error = null) and its override in a private class), so the parameter is looked up there too. */
		private static ParameterInfo DeclaredParameter(MethodBase m, ParameterInfo p)
		{
			if (p.IsOptional || !(m is MethodInfo mi) || !mi.IsVirtual) return p;
			MethodInfo b = mi.GetBaseDefinition();
			if (b == null || b == mi) return p;
			ParameterInfo[] bp = b.GetParameters();
			return p.Position < bp.Length && bp[p.Position].IsOptional ? bp[p.Position] : p;
		}

		private static ParamShape ShapeOf(MethodBase m)
		{
			return Shapes.GetOrAdd(m, method =>
			{
				ParamShape shape = new ParamShape { Parameters = method.GetParameters() };
				foreach (ParameterInfo p in shape.Parameters)
				{
					if (IsOutOnly(p)) continue;
					shape.Inputs++;
					if (!DeclaredParameter(method, p).IsOptional && !IsParams(p)) shape.Required++;          /* a params array may be left out: it is empty */
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
						if (!ok && IsParams(ps[i]) && next == args.Length && TryConvert(args[next - 1], pt.GetElementType(), out object single, out int singleScore))
						{
							/* one value for a params array (Configure(repository, appender)): an array of one item */
							Array one = Array.CreateInstance(pt.GetElementType(), 1);
							one.SetValue(single, 0);
							conv[i] = one;
							ok = true;
							sc = singleScore;
						}
						total += sc;
					}
					else if (IsParams(ps[i]))
					{
						conv[i] = Array.CreateInstance(pt.GetElementType(), 0);
					}
					else
					{
						ParameterInfo declared = DeclaredParameter(m, ps[i]);
						conv[i] = declared.HasDefaultValue ? declared.DefaultValue : Type.Missing;
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

		private static readonly System.Collections.Concurrent.ConcurrentDictionary<Type, ConstructorInfo[]> Constructors =
			new System.Collections.Concurrent.ConcurrentDictionary<Type, ConstructorInfo[]>();

		private static ConstructorInfo[] ConstructorsOf(Type t)
		{
			return Constructors.GetOrAdd(t, type => type.GetConstructors(BindingFlags.Public | BindingFlags.Instance));
		}
	}
}
