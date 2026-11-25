/* Typed properties: a property of a number, a yes/no or a text is read and written without a request text.
   The generated getter calls dotnet_getp(handle, "Name") and the generated setter dotnet_setp(handle, "Name", value) (ring_dotnet.c), which call the
   entries below with the name as bytes. The property is looked up by its name on the real type of the object, like the request "get" does; a compiled
   accessor is kept for each name and type, so the next call is a table lookup and a delegate call.
   The status answers 0 (a number or a yes/no in Number), 1 (a text), 2 (a null text), 3 (this call can not be done here: the extension makes the
   request of the generic path, which does it and raises its errors), 4 (an error of the property itself: its text). */

using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq.Expressions;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;

namespace RingDotNet
{
	public static unsafe partial class Bridge
	{
		[StructLayout(LayoutKind.Sequential)]
		public struct TypedResult
		{
			public double Number;
			public byte* Text;
			public int TextLength;
			public int Pad;
		}

		/* What a property of one type can do */
		private sealed class PropAccessor
		{
			public int Kind;                         /* 0 not typed, 1 a number, 2 a yes/no, 3 a text */
			public Func<object, double> Number;      /* a number, or a yes/no as 1 or 0 */
			public Func<object, string> Text;
			public Action<object, object> Write;     /* null when the property can not be written this way */
			public Type PropertyType;
		}

		private sealed class AccessorPair
		{
			public readonly Type Type;
			public readonly PropAccessor Accessor;
			public AccessorPair(Type type, PropAccessor accessor) { Type = type; Accessor = accessor; }
		}

		/* One name: the accessors of the types that have a property of that name */
		private sealed class PropEntry
		{
			public byte[] Name;
			public string NameText;
			public int Hash;
			public AccessorPair Last;
			public Type StaticType;                  /* the type that this name names (a static typed call), when it was resolved */
			public bool StaticResolved;
			public readonly ConcurrentDictionary<Type, PropAccessor> ByType = new ConcurrentDictionary<Type, PropAccessor>();
		}

		private static PropEntry[] PropTable = new PropEntry[1024];
		private static int PropCount;
		private static readonly PropAccessor NotTyped = new PropAccessor { Kind = 0 };

		private static PropEntry FindProp(byte* name, int length)
		{
			ReadOnlySpan<byte> span = new ReadOnlySpan<byte>(name, length);
			uint hash = 2166136261;
			for (int k = 0; k < span.Length; k++)
			{
				hash = (hash ^ span[k]) * 16777619;
			}
			int mask = PropTable.Length - 1;
			int i = (int)(hash & (uint)mask);
			while (PropTable[i] != null)
			{
				PropEntry e = PropTable[i];
				if (e.Hash == (int)hash && span.SequenceEqual(e.Name)) return e;
				i = (i + 1) & mask;
			}
			PropEntry added = new PropEntry { Name = span.ToArray(), NameText = Encoding.UTF8.GetString(span), Hash = (int)hash };
			if ((PropCount + 1) * 2 > PropTable.Length)
			{
				PropEntry[] old = PropTable;
				PropTable = new PropEntry[old.Length * 2];
				foreach (PropEntry e in old) { if (e != null) Place(e); }
			}
			Place(added);
			PropCount++;
			return added;
		}

		private static void Place(PropEntry e)
		{
			int mask = PropTable.Length - 1;
			int i = e.Hash & mask;
			while (PropTable[i] != null) i = (i + 1) & mask;
			PropTable[i] = e;
		}

		private static PropAccessor AccessorFor(PropEntry entry, Type type)
		{
			AccessorPair last = entry.Last;
			if (last != null && last.Type == type) return last.Accessor;
			PropAccessor a = entry.ByType.GetOrAdd(type, t => BuildAccessor(entry.NameText, t));
			entry.Last = new AccessorPair(type, a);
			return a;
		}

		private static bool IsPlainNumber(Type t)
		{
			switch (Type.GetTypeCode(t))
			{
				case TypeCode.SByte: case TypeCode.Byte: case TypeCode.Int16: case TypeCode.UInt16: case TypeCode.Int32: case TypeCode.UInt32:
				case TypeCode.Int64: case TypeCode.UInt64: case TypeCode.Single: case TypeCode.Double: case TypeCode.Decimal:
					return !t.IsEnum;
				default:
					return false;
			}
		}

		/* The accessor of the property (or field) of a name on a type: the one that the request "get" would find. A member of another kind is NotTyped. */
		private static PropAccessor BuildAccessor(string name, Type type)
		{
			try
			{
				PropertyInfo p = FindProperty(type, name, InstanceFlags);
				FieldInfo fi = null;
				Type memberType;
				if (p != null && p.GetIndexParameters().Length == 0 && p.GetMethod != null && p.GetMethod.IsPublic && !p.PropertyType.IsByRef && !p.PropertyType.IsByRefLike && !p.PropertyType.IsPointer)
				{
					memberType = p.PropertyType;
				}
				else
				{
					p = null;
					fi = type.GetField(name, InstanceFlags);
					if (fi == null || fi.FieldType.IsPointer) return NotTyped;
					memberType = fi.FieldType;
				}
				PropAccessor a = new PropAccessor { PropertyType = memberType };
				ParameterExpression o = Expression.Parameter(typeof(object), "o");
				ParameterExpression v = Expression.Parameter(typeof(object), "v");
				Expression target = Expression.Convert(o, type);
				Expression read = p != null ? Expression.Property(target, p) : Expression.Field(target, fi);
				if (memberType == typeof(string))
				{
					a.Kind = 3;
					a.Text = Expression.Lambda<Func<object, string>>(read, o).Compile();
				}
				else if (memberType == typeof(bool))
				{
					a.Kind = 2;
					a.Number = Expression.Lambda<Func<object, double>>(Expression.Condition(read, Expression.Constant(1.0), Expression.Constant(0.0)), o).Compile();
				}
				else if (memberType.IsEnum)
				{
					/* an enum is read as the text of its member name (what the wire format answers) and written from a text or a number by TryConvert */
					a.Kind = 3;
					a.Text = Expression.Lambda<Func<object, string>>(Expression.Call(Expression.Convert(read, typeof(object)), typeof(object).GetMethod("ToString")), o).Compile();
				}
				else if (IsPlainNumber(memberType))
				{
					a.Kind = 1;
					a.Number = Expression.Lambda<Func<object, double>>(Expression.Convert(read, typeof(double)), o).Compile();
				}
				else
				{
					return NotTyped;
				}
				/* a write is typed for a class (a struct is changed in its box by reflection) with a public setter */
				bool canWrite = p != null ? (p.SetMethod != null && p.SetMethod.IsPublic) : (!fi.IsInitOnly && !fi.IsLiteral);
				if (canWrite && !type.IsValueType)
				{
					Expression place = p != null ? Expression.Property(target, p) : Expression.Field(target, fi);
					a.Write = Expression.Lambda<Action<object, object>>(Expression.Assign(place, Expression.Convert(v, memberType)), o, v).Compile();
				}
				return a;
			}
			catch (Exception)
			{
				return NotTyped;
			}
		}

		private static byte* TextBuffer;
		private static int TextCapacity;

		private static int WriteText(TypedResult* r, string s)
		{
			int max = Encoding.UTF8.GetMaxByteCount(s.Length);
			if (max > TextCapacity)
			{
				if (TextBuffer != null) NativeMemory.Free(TextBuffer);
				TextCapacity = Math.Max(max, 256);
				TextBuffer = (byte*)NativeMemory.Alloc((nuint)TextCapacity);
			}
			int n = Encoding.UTF8.GetBytes(s, new Span<byte>(TextBuffer, TextCapacity));
			r->Text = TextBuffer;
			r->TextLength = n;
			return 1;
		}

		/* An error of the property itself: the same text that the generic request answers */
		private static int WriteError(TypedResult* r, Exception ex)
		{
			WriteText(r, ex.GetType().FullName + ": " + ex.Message + (Environment.GetEnvironmentVariable("RINGDOTNET_TRACE") == "1" ? Environment.NewLine + ex.StackTrace : ""));
			return 4;
		}

		private static bool TypedTarget(long handle, out object target)
		{
			lock (Sync)
			{
				if (!Handles.TryGetValue(handle, out target)) return false;
			}
			return target != null && !(target is TypeRef);
		}

		[UnmanagedCallersOnly]
		public static int GetProp(long handle, byte* name, int nameLength, TypedResult* r)
		{
			if (Depth == 0) RingThread = Environment.CurrentManagedThreadId;
			Depth++;
			try
			{
				if (!TypedTarget(handle, out object target)) return 3;
				PropAccessor a = AccessorFor(FindProp(name, nameLength), target.GetType());
				switch (a.Kind)
				{
					case 1:
					case 2:
						r->Number = a.Number(target);
						return 0;
					case 3:
						string s = a.Text(target);
						return s == null ? 2 : WriteText(r, s);
					default:
						return 3;
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

		private static int WriteProp(long handle, byte* name, int nameLength, object value, TypedResult* r)
		{
			if (Depth == 0) RingThread = Environment.CurrentManagedThreadId;
			Depth++;
			try
			{
				if (!TypedTarget(handle, out object target)) return 3;
				PropAccessor a = AccessorFor(FindProp(name, nameLength), target.GetType());
				if (a.Write == null) return 3;
				if (!TryConvert(value, a.PropertyType, out object converted, out int _)) return 3;
				a.Write(target, converted);
				return 0;
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

		[UnmanagedCallersOnly]
		public static int SetPropNumber(long handle, byte* name, int nameLength, double value, TypedResult* r)
		{
			return WriteProp(handle, name, nameLength, value, r);
		}

		[UnmanagedCallersOnly]
		public static int SetPropText(long handle, byte* name, int nameLength, byte* text, int textLength, TypedResult* r)
		{
			object value;
			try
			{
				value = DecodeString(new ReadOnlySpan<byte>(text, textLength));
			}
			catch (Exception)
			{
				return 3;
			}
			return WriteProp(handle, name, nameLength, value, r);
		}
	}
}
