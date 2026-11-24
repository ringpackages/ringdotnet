/* Converting a value that comes from Ring to the .NET type of a parameter (numbers, texts, enums, lists, objects, pointers, implicit operators). */

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
		private static bool IsNumeric(Type t)
		{
			switch (Type.GetTypeCode(t))
			{
				case TypeCode.SByte: case TypeCode.Byte: case TypeCode.Int16: case TypeCode.UInt16:
				case TypeCode.Int32: case TypeCode.UInt32: case TypeCode.Int64: case TypeCode.UInt64:
				case TypeCode.Single: case TypeCode.Double: case TypeCode.Decimal:
					return true;
			}
			return false;
		}

		private static bool IsIntegral(Type t)
		{
			switch (Type.GetTypeCode(t))
			{
				case TypeCode.SByte: case TypeCode.Byte: case TypeCode.Int16: case TypeCode.UInt16:
				case TypeCode.Int32: case TypeCode.UInt32: case TypeCode.Int64: case TypeCode.UInt64:
					return true;
			}
			return false;
		}

		/* A pointer parameter (byte*, char*, void*, int*): a number is the address (from Marshal.AllocHGlobal, a native library ...); a text, a byte
		   string, a list, a ByteBuffer or null is a buffer that is pinned for the call (a text and a byte string end with a zero, for the C strings),
		   so the address is valid during the call only; a ByteBuffer is the live array, which the called method may fill. */
		private static unsafe bool ConvertPointer(object v, Type t, out object result, out int score)
		{
			result = null;
			score = 0;
			Type element = t.GetElementType();
			if (element.IsByRef || element.IsByRefLike) return false;
			if (v == null)
			{
				result = Pointer.Box((void*)0, t);
				score = 2;
				return true;
			}
			if (v is IntPtr intPtr) v = (double)(long)intPtr;
			if (v is double number)
			{
				if (number < 0 || number != Math.Floor(number)) return false;
				result = Pointer.Box((void*)(long)number, t);
				score = 3;
				return true;
			}
			if (element.IsPointer) return false;
			Array array = null;
			bool voidOrByte = element == typeof(void) || element == typeof(byte) || element == typeof(sbyte);
			if (v is ByteBuffer buffer && voidOrByte) array = buffer.Data;
			else if (v is string text)
			{
				if (element == typeof(char))
				{
					char[] chars = new char[text.Length + 1];
					text.CopyTo(0, chars, 0, text.Length);
					array = chars;
				}
				else if (voidOrByte)
				{
					byte[] bytes = new byte[Encoding.UTF8.GetByteCount(text) + 1];
					Encoding.UTF8.GetBytes(text, 0, text.Length, bytes, 0);
					array = bytes;
				}
			}
			else if (v is byte[] raw && voidOrByte)
			{
				byte[] bytes = new byte[raw.Length + 1];
				Array.Copy(raw, bytes, raw.Length);
				array = bytes;
			}
			else if (v is object[])
			{
				/* a list: numbers of the element type (bytes for void*) */
				if (TryConvert(v, (element == typeof(void) ? typeof(byte) : element).MakeArrayType(), out object converted, out _)) array = (Array)converted;
			}
			if (array == null) return false;
			if (pinned == null) pinned = new List<GCHandle>();
			GCHandle handle = GCHandle.Alloc(array, GCHandleType.Pinned);
			pinned.Add(handle);
			result = Pointer.Box((void*)handle.AddrOfPinnedObject(), t);
			score = 1;
			return true;
		}

		/* A pointer that a method returns is its address, as a number */
		private static unsafe object PointerResult(object returned)
		{
			return returned is Pointer pointer ? (object)(double)(long)(IntPtr)Pointer.Unbox(pointer) : returned;
		}

		/* Convert a Ring value to a parameter type, score = how good the match is (higher is better) */
		private static bool TryConvert(object v, Type t, out object result, out int score)
		{
			result = null;
			score = 0;
			if (t.IsByRef || t.IsFunctionPointer)
			{
				return false;
			}
			v = Plain(v);
			if (t.IsPointer) return ConvertPointer(v, t, out result, out score);
			if (v is Boxed exact)
			{
				/* an exact value (dnBox): an object parameter gets it as it is, another parameter gets the conversion of its value */
				if (t.IsInstanceOfType(exact.Value)) { result = exact.Value; score = 5; return true; }
				v = exact.Value;
			}
			if (t == typeof(object) && (v is double || (v is object[] ringList && RingLists.TryGetValue(ringList, out _))))
			{
				result = NormalizeNumbers(v);
				score = 1;
				return true;
			}
			if (v is object[] listOfRing && t != typeof(object) && t.IsAssignableFrom(typeof(object[])) && RingLists.TryGetValue(listOfRing, out _))
			{
				result = NormalizeNumbers(v);
				score = t == typeof(object[]) ? 4 : 2;
				return true;
			}
			Type ut = Nullable.GetUnderlyingType(t) ?? t;
			if ((ut == typeof(IntPtr) || ut == typeof(UIntPtr)) && v is double address && address >= 0 && address == Math.Floor(address))
			{
				result = ut == typeof(IntPtr) ? (object)new IntPtr((long)address) : new UIntPtr((ulong)address);
				score = 5;
				return true;
			}
			if (IsSpan(ut, out Type spanElement, out bool spanWritable))
			{
				/* a Span<T> or ReadOnlySpan<T>: an array of T (a text for char, a byte string or a list for byte ...); a number is the size of a new
				   array for a Span<T> that the method fills */
				if (spanWritable && v is double size && size >= 0 && size == Math.Floor(size) && size < int.MaxValue)
				{
					result = Array.CreateInstance(spanElement, (int)size);
					score = 1;
					return true;
				}
				if (spanElement == typeof(char) && v is string text)
				{
					result = text.ToCharArray();
					score = 1;          /* a plain parameter (a string) wins against a span */
					return true;
				}
				if (TryConvert(v, spanElement.MakeArrayType(), out result, out score))
				{
					score = 1;
					return true;
				}
				return false;
			}
			if (ut.IsByRefLike)
			{
				/* a ref struct of a library: made for the call from its source value (see RefStructFactory) */
				MethodBase factory = RefStructFactory(ut);
				if (factory == null) return false;
				if (!TryConvert(v, FactorySource(factory), out result, out score)) return false;
				score = Math.Max(1, score - 1);
				return true;
			}
			if (v is ByteBuffer buffer && (ut == typeof(byte[]) || ut == typeof(object)))
			{
				result = buffer.Data;               /* the live array, so that the called method fills it */
				score = ut == typeof(byte[]) ? 10 : 1;
				return true;
			}
			if (v is CallbackRef cb)
			{
				if (typeof(Delegate).IsAssignableFrom(ut) && ut != typeof(Delegate) && ut != typeof(MulticastDelegate))
				{
					result = MakeDelegate(ut, cb.Name);
					score = 12 - ut.GetMethod("Invoke").GetParameters().Length;
					return true;
				}
				if (ut == typeof(object))
				{
					/* a parameter of type object keeps the callback (an assembly that wraps Ring code calls it with Bridge.CallRing) */
					result = cb;
					score = 1;
					return true;
				}
				return false;
			}
			if (v == null)
			{
				if (!t.IsValueType || ut != t)
				{
					score = 1;
					return true;
				}
				return false;
			}
			if (v is double num && IsNumeric(ut))
			{
				/* Ring numbers are doubles: prefer int for whole numbers (Write(7) is Write(int), not Write(double)) */
				bool whole = num == Math.Floor(num);
				if (IsIntegral(ut) && !whole)
				{
					return false;
				}
				try
				{
					result = Convert.ChangeType(num, ut, Inv);
				}
				catch (Exception) { return false; }
				switch (Type.GetTypeCode(ut))
				{
					case TypeCode.Int32: score = whole ? 6 : 1; break;
					case TypeCode.Int64: score = whole ? 5 : 1; break;
					case TypeCode.Double: score = whole ? 2 : 6; break;
					case TypeCode.Single: score = whole ? 1 : 5; break;
					case TypeCode.Decimal: score = whole ? 1 : 4; break;
					default: score = whole ? 3 : 1; break;
				}
				return true;
			}
			if (ut.IsInstanceOfType(v))
			{
				result = v;
				score = ut == typeof(object) ? 1 : (v.GetType() == ut ? 4 : 2);
				return true;
			}
			if (v is double d)
			{
				if (ut.IsEnum)
				{
					result = Enum.ToObject(ut, (long)d);
					score = 1;
					return true;
				}
				if (IsNumeric(ut))
				{
					if (IsIntegral(ut) && d != Math.Floor(d))
					{
						return false;
					}
					try
					{
						result = Convert.ChangeType(d, ut, Inv);
						score = ut == typeof(int) ? 3 : 2;
						return true;
					}
					catch (Exception) { return false; }
				}
				if (ut == typeof(bool))
				{
					result = d != 0;
					score = 1;
					return true;
				}
				if (ut == typeof(string))
				{
					result = d.ToString("R", Inv);
					score = 0;
					return true;
				}
				return TryImplicit(v, ut, out result, out score);
			}
			if (v is string s)
			{
				if (ut == typeof(Enum))
				{
					/* a parameter of the type System.Enum (Humanize(Enum value)) does not say which enum: the text gives the full name of the member,
					   "System.DayOfWeek.Friday" */
					int dot = s.LastIndexOf('.');
					if (dot > 0)
					{
						Type enumType = null;
						try { enumType = ResolveSimple(s.Substring(0, dot)); } catch (Exception) { }
						if (enumType != null && enumType.IsEnum && Enum.TryParse(enumType, s.Substring(dot + 1), true, out object member))
						{
							result = member;
							score = 1;
							return true;
						}
					}
					return false;
				}
				if (ut.IsEnum)
				{
					/* TryParse: a text that is not a name of this enum is common while overloads are compared, and an exception is slow */
					if (Enum.TryParse(ut, s, true, out object parsed)) { result = parsed; score = 2; return true; }
					return false;
				}
				if (ut == typeof(char) && s.Length == 1)
				{
					result = s[0];
					score = 2;
					return true;
				}
				if (ut == typeof(byte[]))
				{
					result = Encoding.UTF8.GetBytes(s);
					score = 1;
					return true;
				}
				if (ut == typeof(Guid) && Guid.TryParse(s, out Guid g))
				{
					result = g;
					score = 2;
					return true;
				}
				if (ut == typeof(Type))
				{
					try { result = ResolveType(s); score = 2; return true; }
					catch (Exception) { return false; }
				}
				return TryImplicit(v, ut, out result, out score);
			}
			if (v is bool b)
			{
				if (IsNumeric(ut))
				{
					result = Convert.ChangeType(b ? 1 : 0, ut, Inv);
					score = 1;
					return true;
				}
				return false;
			}
			if (v is object[] list && ut.IsArray)
			{
				Type et = ut.GetElementType();
				Array arr = Array.CreateInstance(et, list.Length);
				for (int i = 0; i < list.Length; i++)
				{
					if (!TryConvert(list[i], et, out object item, out int _))
					{
						return false;
					}
					arr.SetValue(item, i);
				}
				result = arr;
				score = 2;
				return true;
			}
			if (v is object[] items && ut.IsGenericType && ut.GetGenericArguments().Length == 1)
			{
				/* a Ring list for IEnumerable<T>, IList<T>, ICollection<T>, List<T>... */
				Type et = ut.GetGenericArguments()[0];
				Array arr = Array.CreateInstance(et, items.Length);
				for (int i = 0; i < items.Length; i++)
				{
					if (!TryConvert(items[i], et, out object item, out int _))
					{
						return false;
					}
					arr.SetValue(item, i);
				}
				if (ut.IsAssignableFrom(arr.GetType()))
				{
					result = arr;
					score = 2;
					return true;
				}
				Type listType = typeof(List<>).MakeGenericType(et);
				if (ut.IsAssignableFrom(listType))
				{
					result = Activator.CreateInstance(listType, arr);
					score = 2;
					return true;
				}
			}
			return TryImplicit(v, ut, out result, out score);
		}

		/* User defined implicit conversions (string --> XName, string --> PathString ...) */
		/* The op_Implicit methods of a type (with one parameter): found once, because GetMethods copies a big array on every call */
		private static readonly System.Collections.Concurrent.ConcurrentDictionary<Type, MethodInfo[]> ImplicitCache =
			new System.Collections.Concurrent.ConcurrentDictionary<Type, MethodInfo[]>();

		private static MethodInfo[] ImplicitOperators(Type owner)
		{
			return ImplicitCache.GetOrAdd(owner, type =>
			{
				List<MethodInfo> list = new List<MethodInfo>();
				foreach (MethodInfo m in type.GetMethods(BindingFlags.Public | BindingFlags.Static))
				{
					if (m.Name == "op_Implicit" && m.GetParameters().Length == 1) list.Add(m);
				}
				return list.ToArray();
			});
		}

		private static bool TryImplicit(object v, Type target, out object result, out int score)
		{
			result = null;
			score = 0;
			Type from = v.GetType();
			foreach (Type owner in new[] { target, from })
			{
				foreach (MethodInfo m in ImplicitOperators(owner))
				{
					if (!target.IsAssignableFrom(m.ReturnType)) continue;
					ParameterInfo[] ps = ShapeOf(m).Parameters;
					object arg = null;
					bool usable = ps[0].ParameterType.IsAssignableFrom(from);
					if (usable)
					{
						arg = v;
					}
					else if (v is double && IsNumeric(ps[0].ParameterType))
					{
						/* a Ring number for BigInteger / Complex / Half... : whole numbers use the integer conversions first */
						usable = TryConvert(v, ps[0].ParameterType, out arg, out int sc) && (sc >= 5 || !(((double)v) == Math.Floor((double)v)) || ps[0].ParameterType == typeof(double));
					}
					if (usable)
					{
						try { result = m.Invoke(null, new[] { arg }); score = 1; return true; }
						catch (Exception) { }
					}
				}
			}
			return false;
		}

		/* The conversion of a value to a type with op_Implicit / op_Explicit of the value's class or of the target class (the cast of C#), or the
		   plain conversion of the bridge (a number to another number type, a text to a number type ...) */
		private static object ConvertValue(object value, Type target)
		{
			value = Plain(value);
			if (value != null && target.IsInstanceOfType(value)) return value;
			foreach (string name in new[] { "op_Implicit", "op_Explicit" })
			{
				foreach (MethodBase candidate in OperatorMethods(name, value, new TypeRef(target)))
				{
					MethodInfo m = (MethodInfo)candidate;
					if (!target.IsAssignableFrom(m.ReturnType)) continue;
					if (m.GetParameters().Length == 1 && TryConvert(value, m.GetParameters()[0].ParameterType, out object arg, out int score))
					{
						return m.Invoke(null, new[] { arg });
					}
				}
			}
			if (TryConvert(value, target, out object converted, out int s2)) return converted;
			throw new InvalidCastException("Can't convert " + (value == null ? "null" : value.GetType().FullName) + " to " + target.FullName);
		}
	}
}
