/* Operators (op_Addition ...) and comparisons for the objects that have them. */

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
		/* ---------------------------------------------------------------- operators and conversions
		   A class that has operator methods (op_Addition ...) gets the Ring method operator(cOperator, xOther): Ring calls it for o + x, o < x, and
		   for x + o with "r+" (the object comes second). The operator method of either class is used; == and < fall back to Equals and IComparable. */
		internal static readonly Dictionary<string, string> OperatorNames = new Dictionary<string, string>
		{
			{ "+", "op_Addition" }, { "-", "op_Subtraction" }, { "*", "op_Multiply" }, { "/", "op_Division" }, { "%", "op_Modulus" },
			{ "=", "op_Equality" }, { "!=", "op_Inequality" }, { "<", "op_LessThan" }, { ">", "op_GreaterThan" },
			{ "<=", "op_LessThanOrEqual" }, { ">=", "op_GreaterThanOrEqual" }, { "&", "op_BitwiseAnd" }, { "|", "op_BitwiseOr" },
			{ "^", "op_ExclusiveOr" }, { "<<", "op_LeftShift" }, { ">>", "op_RightShift" },
			{ "neg", "op_UnaryNegation" }, { "~", "op_OnesComplement" }, { "not", "op_LogicalNot" }
		};

		private static IEnumerable<MethodBase> OperatorMethods(string name, params object[] operands)
		{
			HashSet<MethodBase> seen = new HashSet<MethodBase>();
			foreach (object operand in operands)
			{
				if (operand == null) continue;
				Type t = operand is TypeRef tr ? tr.Type : operand.GetType();
				foreach (MethodInfo m in t.GetMethods(BindingFlags.Public | BindingFlags.Static | BindingFlags.FlattenHierarchy))
				{
					if (m.IsSpecialName && m.Name == name && seen.Add(m)) yield return m;
				}
			}
		}

		private static object CallOperator(object left, string op, object other)
		{
			bool reversed = op.Length > 1 && op[0] == 'r' && OperatorNames.ContainsKey(op.Substring(1));
			if (reversed) op = op.Substring(1);
			if (!OperatorNames.TryGetValue(op, out string name))
			{
				throw new NotSupportedException("The operator '" + op + "' is not supported for a .NET object");
			}
			bool unary = op == "neg" || op == "~" || op == "not";
			other = Plain(other);
			object[] args = unary ? new[] { left } : reversed ? new[] { other, left } : new[] { left, other };
			MethodInfo m = Pick(OperatorMethods(name, args), args, out object[] conv) as MethodInfo;
			if (m != null) return m.Invoke(null, conv);
			if (!unary)
			{
				if (op == "=" || op == "!=")
				{
					bool equal = Equals(left, other);
					return (op == "=") == equal ? 1.0 : 0.0;
				}
				if (op == "<" || op == ">" || op == "<=" || op == ">=")
				{
					int? compared = CompareWith(left, other);
					if (compared.HasValue)
					{
						int order = compared.Value;
						if (reversed) order = -order;
						bool result = op == "<" ? order < 0 : op == ">" ? order > 0 : op == "<=" ? order <= 0 : order >= 0;
						return result ? 1.0 : 0.0;
					}
				}
				if ((op == "<" || op == ">" || op == "<=" || op == ">=") && left is IComparable comparable)
				{
					object converted = other;
					if (other != null && other.GetType() != left.GetType() && TryConvert(other, left.GetType(), out object c, out int score)) converted = c;
					int order = comparable.CompareTo(converted);
					if (reversed) order = -order;
					bool result = op == "<" ? order < 0 : op == ">" ? order > 0 : op == "<=" ? order <= 0 : order >= 0;
					return result ? 1.0 : 0.0;
				}
			}
			throw new MissingMethodException("No operator " + name + " of " + left.GetType().FullName + " accepts " + (unary ? "the object" : other == null ? "null" : other.GetType().FullName));
		}

		/* IComparable<T>.CompareTo of the left object that takes the other object (a type that has no op_LessThan but compares: SemVersion); null when it has none */
		private static int? CompareWith(object left, object other)
		{
			if (left == null || other == null) return null;
			foreach (Type i in left.GetType().GetInterfaces())
			{
				if (!i.IsGenericType || i.GetGenericTypeDefinition() != typeof(IComparable<>)) continue;
				Type argument = i.GetGenericArguments()[0];
				if (!argument.IsInstanceOfType(other)) continue;
				return (int)i.GetMethod("CompareTo").Invoke(left, new[] { other });
			}
			return null;
		}
	}
}
