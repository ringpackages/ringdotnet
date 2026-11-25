/* Typed method calls (a prototype): an instance method with 0 to 8 parameters of a number, a yes/no or a text, and an answer of a number, a yes/no, a text
   or nothing, is called without a request text. dotnet_callt(handle, "Name", arguments...) passes each argument as a typed slot.
   The method is found on the real type of the object. It is called this way only when it is the ONLY method of that name that can take that many arguments
   (no other overload, no optional parameter or params array that could take them): then the generic request would choose it too. Anything else, an argument that
   does not convert exactly, or a struct target, is status 3: the generic request makes the call and raises its errors. */

using System;
using System.Collections.Concurrent;
using System.Linq.Expressions;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;

namespace RingDotNet
{
	public static unsafe partial class Bridge
	{
		[StructLayout(LayoutKind.Sequential)]
		public struct TypedArg
		{
			public int Kind;            /* 1 a number, 2 a text */
			public int TextLength;
			public double Number;
			public byte* Text;
		}

		private sealed class MethodAccessor
		{
			public int[] ParamKinds;            /* per parameter: 1 int, 2 long, 3 double, 4 bool, 5 text */
			public int ResultKind;              /* 0 nothing, 1 a number, 2 a yes/no, 3 a text */
			public Func<object, double[], string[], double> Number;
			public Func<object, double[], string[], string> Text;
			public Action<object, double[], string[]> Void;
		}

		private static readonly ConcurrentDictionary<(Type, string, int), MethodAccessor> MethodAccessors = new ConcurrentDictionary<(Type, string, int), MethodAccessor>();
		private static readonly MethodAccessor NoMethod = new MethodAccessor();
		[ThreadStatic] private static double[] CallNumbers;
		[ThreadStatic] private static string[] CallTexts;

		/* The kinds of parameter that are called directly: 1 int, 2 long, 3 double, 4 bool, 5 text, 6 uint, 7 short, 8 ushort, 9 byte, 10 sbyte, 11 ulong, 12 float.
		   (An enum, a char, a decimal, a nullable and the rest are the generic request's.) */
		private static int ParamKind(Type t)
		{
			if (t.IsEnum) return 0;
			if (t == typeof(int)) return 1;
			if (t == typeof(long)) return 2;
			if (t == typeof(double)) return 3;
			if (t == typeof(bool)) return 4;
			if (t == typeof(string)) return 5;
			if (t == typeof(uint)) return 6;
			if (t == typeof(short)) return 7;
			if (t == typeof(ushort)) return 8;
			if (t == typeof(byte)) return 9;
			if (t == typeof(sbyte)) return 10;
			if (t == typeof(ulong)) return 11;
			if (t == typeof(float)) return 12;
			return 0;
		}

		/* the range of a whole number for the integer kinds (the same numbers that Convert.ChangeType accepts) */
		private static bool WholeIn(double v, double low, double high)
		{
			return v == Math.Floor(v) && v >= low && v <= high;
		}

		private static MethodAccessor BuildMethodAccessor(Type type, string name, int argc)
		{
			try
			{
				if (type.IsValueType) return NoMethod;
				MethodInfo exact = null;
				foreach (MethodInfo m in MethodsNamed(type, name, InstanceFlags))
				{
					if (m.Name != name) return NoMethod;          /* found only by another letter case: the generic request decides */
					ParameterInfo[] ps = m.GetParameters();
					bool hasParams = ps.Length > 0 && IsParams(ps[ps.Length - 1]);
					int required = 0;
					foreach (ParameterInfo p in ps) { if (!IsOutOnly(p) && !p.IsOptional) required++; }
					bool canTake = hasParams || (required <= argc && argc <= ps.Length);
					if (!canTake) continue;
					/* the only one that can take these arguments, and with exactly this many parameters */
					if (exact != null || hasParams || ps.Length != argc || m.IsGenericMethodDefinition || required != argc) return NoMethod;
					exact = m;
				}
				if (exact == null) return NoMethod;
				ParameterInfo[] parameters = exact.GetParameters();
				int[] kinds = new int[argc];
				ParameterExpression o = Expression.Parameter(typeof(object), "o");
				ParameterExpression n = Expression.Parameter(typeof(double[]), "n");
				ParameterExpression s = Expression.Parameter(typeof(string[]), "s");
				Expression[] arguments = new Expression[argc];
				for (int i = 0; i < argc; i++)
				{
					Type pt = parameters[i].ParameterType;
					if (pt.IsByRef || pt.IsPointer) return NoMethod;
					kinds[i] = ParamKind(pt);
					Expression slot = Expression.ArrayIndex(n, Expression.Constant(i));
					switch (kinds[i])
					{
						case 3: arguments[i] = slot; break;
						case 4: arguments[i] = Expression.NotEqual(slot, Expression.Constant(0.0)); break;
						case 5: arguments[i] = Expression.ArrayIndex(s, Expression.Constant(i)); break;
						case 0: return NoMethod;
						default: arguments[i] = Expression.Convert(slot, pt); break;
					}
				}
				Expression call = Expression.Call(Expression.Convert(o, type), exact, arguments);
				Type rt = exact.ReturnType;
				MethodAccessor a = new MethodAccessor { ParamKinds = kinds };
				if (rt == typeof(void))
				{
					a.ResultKind = 0;
					a.Void = Expression.Lambda<Action<object, double[], string[]>>(call, o, n, s).Compile();
				}
				else if (rt == typeof(string))
				{
					a.ResultKind = 3;
					a.Text = Expression.Lambda<Func<object, double[], string[], string>>(call, o, n, s).Compile();
				}
				else if (rt == typeof(bool))
				{
					a.ResultKind = 2;
					a.Number = Expression.Lambda<Func<object, double[], string[], double>>(Expression.Condition(call, Expression.Constant(1.0), Expression.Constant(0.0)), o, n, s).Compile();
				}
				else if (IsPlainNumber(rt))
				{
					a.ResultKind = 1;
					a.Number = Expression.Lambda<Func<object, double[], string[], double>>(Expression.Convert(call, typeof(double)), o, n, s).Compile();
				}
				else
				{
					return NoMethod;
				}
				return a;
			}
			catch (Exception)
			{
				return NoMethod;
			}
		}

		/* An argument that the parameter takes exactly: a whole number in range for an int or a long, any number for a double, a number for a yes/no, a text */
		private static bool PutArgument(MethodAccessor a, int i, TypedArg* arg, double[] numbers, string[] texts)
		{
			int kind = a.ParamKinds[i];
			if (kind == 5)
			{
				if (arg->Kind != 2) return false;
				try { texts[i] = StrictUtf8.GetString(arg->Text, arg->TextLength); } catch (Exception) { return false; }
				return true;
			}
			if (arg->Kind != 1) return false;
			double v = arg->Number;
			bool ok;
			switch (kind)
			{
				case 1: ok = WholeIn(v, int.MinValue, int.MaxValue); break;
				case 2: ok = WholeIn(v, -9223372036854775808.0, 9223372036854774784.0); break;
				case 3: ok = true; break;
				case 4: ok = true; break;
				case 6: ok = WholeIn(v, 0, uint.MaxValue); break;
				case 7: ok = WholeIn(v, short.MinValue, short.MaxValue); break;
				case 8: ok = WholeIn(v, 0, ushort.MaxValue); break;
				case 9: ok = WholeIn(v, 0, byte.MaxValue); break;
				case 10: ok = WholeIn(v, sbyte.MinValue, sbyte.MaxValue); break;
				case 11: ok = WholeIn(v, 0, 18446744073709549568.0); break;
				case 12: ok = true; break;
				default: ok = false; break;
			}
			if (!ok) return false;
			numbers[i] = v;
			return true;
		}

		[UnmanagedCallersOnly]
		public static int CallTyped(long handle, byte* name, int nameLength, TypedArg* args, int argc, TypedResult* r)
		{
			if (Depth == 0) RingThread = Environment.CurrentManagedThreadId;
			Depth++;
			try
			{
				if (argc < 0 || argc > 8) return 3;
				if (!TypedTarget(handle, out object target)) return 3;
				PropEntry e = FindProp(name, nameLength);
				Type t = target.GetType();
				MethodAccessor a = MethodAccessors.GetOrAdd((t, e.NameText, argc), key => BuildMethodAccessor(key.Item1, key.Item2, key.Item3));
				if (a == NoMethod) return 3;
				double[] numbers = CallNumbers ??= new double[8];
				string[] texts = CallTexts ??= new string[8];
				for (int i = 0; i < argc; i++)
				{
					if (!PutArgument(a, i, &args[i], numbers, texts)) return 3;
				}
				switch (a.ResultKind)
				{
					case 0:
						a.Void(target, numbers, texts);
						return 5;
					case 1:
					case 2:
						r->Number = a.Number(target, numbers, texts);
						return 0;
					default:
						string s = a.Text(target, numbers, texts);
						return s == null ? 2 : WriteText(r, s);
				}
			}
			catch (Exception ex)
			{
				return WriteError(r, Unwrap(ex));
			}
			finally
			{
				Depth--;
			}
		}
	}
}
