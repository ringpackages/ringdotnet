/* The wire format: reading a request, writing an answer or an error, and the list of type names that Ring wraps an object with. */

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
		private static List<object> Decode(ReadOnlySpan<byte> data)
		{
			List<object> items = new List<object>();
			int pos = 0;
			while (pos < data.Length)
			{
				char tag = (char)data[pos++];
				int len = 0;
				while (pos < data.Length && data[pos] != (byte)':')
				{
					len = len * 10 + (data[pos++] - (byte)'0');
				}
				pos++; /* skip ':' */
				if (pos + len > data.Length)
				{
					throw new ArgumentException("Malformed request");
				}
				ReadOnlySpan<byte> body = data.Slice(pos, len);
				pos += len;
				switch (tag)
				{
					case 's': items.Add(DecodeString(body)); break;
					case 'n': items.Add(double.Parse(Encoding.ASCII.GetString(body), NumberStyles.Float, Inv)); break;
					case 'b': items.Add(body.Length > 0 && body[0] == (byte)'1'); break;
					case 'd': items.Add(BitConverter.ToDouble(body)); break;
					case 'z': items.Add(null); break;
					case 'o': items.Add(Lookup(ParseHandle(body))); break;
					case 'l':
						{
							object[] list = Decode(body).ToArray();
							RingLists.TryAdd(list, null);          /* a list of Ring: its whole numbers become Int32 where an object is expected (NormalizeNumbers) */
							items.Add(list);
							break;
						}
					case 'c': items.Add(new CallbackRef(Encoding.UTF8.GetString(body))); break;
					case 'e': throw new InvalidOperationException("Ring error: " + Encoding.UTF8.GetString(body));
					default: throw new ArgumentException("Unknown item tag '" + tag + "'");
				}
			}
			return items;
		}

		/* The arrays that were made from lists of Ring (a .NET object[] that Ring holds as an object is not one of them) */
		private static readonly System.Runtime.CompilerServices.ConditionalWeakTable<object[], object> RingLists = new System.Runtime.CompilerServices.ConditionalWeakTable<object[], object>();

		/* Ring has one kind of number, a double. Where an object is expected (an argument of String.Format, an item of params object[], a value of a
		   dictionary of objects) a whole number is an Int32: "{0:D3}" and "{0:X}" need an int, JSON writes 5 and not 5.0, and a database stores an integer.
		   A list of Ring that goes to an object[] gets the same for its items. */
		private static object NormalizeNumbers(object value)
		{
			if (value is Boxed boxed) return boxed.Value;
			if (value is double d && d == Math.Floor(d) && d >= int.MinValue && d <= int.MaxValue) return (int)d;
			if (value is object[] list && RingLists.TryGetValue(list, out _))
			{
				object[] copy = new object[list.Length];
				for (int i = 0; i < list.Length; i++) copy[i] = NormalizeNumbers(list[i]);
				return copy;
			}
			return value;
		}

		/* An object item is "<id>" or "<id>|<type>|<base type>|..." (the form sent to Ring) */
		private static long ParseHandle(ReadOnlySpan<byte> body)
		{
			int bar = body.IndexOf((byte)'|');
			return long.Parse(Encoding.ASCII.GetString(bar < 0 ? body : body.Slice(0, bar)), Inv);
		}

		/* Type names Ring can wrap the object with: its type, then its base types */
		private static readonly System.Collections.Concurrent.ConcurrentDictionary<Type, string> TypeChains = new System.Collections.Concurrent.ConcurrentDictionary<Type, string>();

		private static string TypeChain(object value)
		{
			return TypeChains.GetOrAdd(value.GetType(), BuildTypeChain);
		}

		private static string BuildTypeChain(Type type)
		{
			StringBuilder sb = new StringBuilder();
			int count = 0;
			for (Type t = type; t != null && t != typeof(object) && count < 8; t = t.BaseType, count++)
			{
				sb.Append('|').Append(t.FullName ?? t.Name);
				/* a closed generic type is also known by its definition (List`1): the generated class of the definition wraps it */
				if (t.IsGenericType) sb.Append('|').Append(t.GetGenericTypeDefinition().FullName);
			}
			/* then the interfaces (a class that is not generated can still be wrapped as ICryptoTransform, IDisposable...).
			   The most specific interface comes first: the one named after the class by the usual rule (XLWorksheet --> IXLWorksheet),
			   then the ones that inherit the most interfaces. GetInterfaces gives no useful order, and a class that is not public
			   (it is returned as the interface) would be wrapped as the first interface that has a wrapper, often a general one. */
			string conventional = "I" + type.Name;
			Type[] interfaces = type.GetInterfaces().Where(i => i.IsVisible).OrderBy(i => i.Name == conventional ? 0 : 1).ThenByDescending(i => i.GetInterfaces().Length).ToArray();
			/* Interfaces that rank the same (neither is the one named after the class, and they inherit as many interfaces) can not be told apart: a
			   class that is not public and implements IElement and IContainer (the elements of a fluent API) is both. When two or more of them are
			   interfaces of the assembly of the class itself, they are one part of the chain, joined with '&', and Ring wraps the object with a class that
			   has the members of all of them. The interfaces of the framework (IDisposable ...) stay separate parts, after them. */
			/* A class that is not public is returned as one of its interfaces (ServiceProviderEngineScope as IServiceScope), and it is all of them: IServiceScope has
			   the property ServiceProvider, IServiceProvider the method GetService. Its interfaces that are not generic (up to 6, the one named after the class
			   first) are one part of the chain, joined with '&': Ring wraps the object with a class that has the members of every one of them that has a class. */
			if (!type.IsVisible)
			{
				List<Type> all = interfaces.Take(6).ToList();
				if (all.Count >= 2)
				{
					/* a generic interface is named by its definition (IDictionary`2): the generated class of the definition has the members */
					sb.Append('|').Append(string.Join("&", all.Select(i => (i.IsGenericType ? i.GetGenericTypeDefinition().FullName : i.FullName) ?? i.Name)));
					count += all.Count;
					interfaces = interfaces.Where(i => !all.Contains(i)).ToArray();
				}
			}
			for (int start = 0; start < interfaces.Length;)
			{
				int end = start;
				while (end < interfaces.Length && interfaces[end].Name == conventional == (interfaces[start].Name == conventional)
					&& interfaces[end].GetInterfaces().Length == interfaces[start].GetInterfaces().Length) end++;
				List<Type> group = new List<Type>();
				List<Type> own = new List<Type>();
				for (int k = start; k < end; k++)
				{
					if (!interfaces[k].IsGenericType && interfaces[k].Assembly == type.Assembly) own.Add(interfaces[k]); else group.Add(interfaces[k]);
				}
				if (own.Count >= 2 && count < 40)
				{
					sb.Append('|').Append(string.Join("&", own.Select(i => i.FullName ?? i.Name)));
					count += own.Count;
				}
				else
				{
					group.InsertRange(0, own);
					own.Clear();
				}
				foreach (Type i in group)
				{
					if (count++ >= 40) break;
					sb.Append('|').Append(i.FullName ?? i.Name);
					if (i.IsGenericType) sb.Append('|').Append(i.GetGenericTypeDefinition().FullName);
				}
				start = end;
			}
			return sb.ToString();
		}

		private static readonly UTF8Encoding StrictUtf8 = new UTF8Encoding(false, true);

		/* Valid UTF-8 text becomes a string; anything else (binary data) stays a byte[] */
		private static object DecodeString(ReadOnlySpan<byte> body)
		{
			try
			{
				return StrictUtf8.GetString(body);
			}
			catch (ArgumentException)
			{
				return body.ToArray();
			}
		}

		private static void WriteItem(MemoryStream ms, char tag, byte[] body)
		{
			ms.WriteByte((byte)tag);
			byte[] len = Encoding.ASCII.GetBytes(body.Length.ToString(Inv));
			ms.Write(len, 0, len.Length);
			ms.WriteByte((byte)':');
			ms.Write(body, 0, body.Length);
		}

		private static void Encode(MemoryStream ms, object value)
		{
			switch (value)
			{
				case null: WriteItem(ms, 'z', Array.Empty<byte>()); return;
				case string s: WriteItem(ms, 's', Encoding.UTF8.GetBytes(s)); return;
				case char c: WriteItem(ms, 's', Encoding.UTF8.GetBytes(c.ToString())); return;
				case bool b: WriteItem(ms, 'b', new[] { (byte)(b ? '1' : '0') }); return;
				case byte[] raw: WriteItem(ms, 's', raw); return;
				case Enum e: WriteItem(ms, 's', Encoding.UTF8.GetBytes(e.ToString())); return;
				case decimal m: WriteItem(ms, 'n', Encoding.ASCII.GetBytes(((double)m).ToString("R", Inv))); return;
				case double d: WriteItem(ms, 'n', Encoding.ASCII.GetBytes(d.ToString("R", Inv))); return;
				case float f: WriteItem(ms, 'n', Encoding.ASCII.GetBytes(((double)f).ToString("R", Inv))); return;
				case sbyte or byte or short or ushort or int or uint or long or ulong:
					WriteItem(ms, 'n', Encoding.ASCII.GetBytes(Convert.ToString(value, Inv))); return;
				case List<object> list when RingList.IsResult(list):
					{
						MemoryStream inner = new MemoryStream();
						foreach (object item in list) { Encode(inner, item); }
						WriteItem(ms, 'l', inner.ToArray());
						return;
					}
				case SameAsReceiver:
					WriteItem(ms, 'q', new byte[0]);
					return;
				default:
					WriteItem(ms, 'o', Encoding.UTF8.GetBytes(Register(value).ToString(Inv) + TypeChain(value)));
					return;
			}
		}

		private static byte[] EncodeToBytes(object value)
		{
			MemoryStream ms = new MemoryStream();
			Encode(ms, value);
			return ms.ToArray();
		}

		private static byte[] EncodeError(Exception ex)
		{
			MemoryStream ms = new MemoryStream();
			WriteItem(ms, 'e', Encoding.UTF8.GetBytes(ex.GetType().FullName + ": " + ex.Message + (Environment.GetEnvironmentVariable("RINGDOTNET_TRACE") == "1" ? Environment.NewLine + ex.StackTrace : "")));
			return ms.ToArray();
		}

		private static Exception Unwrap(Exception ex)
		{
			while (ex is TargetInvocationException && ex.InnerException != null)
			{
				ex = ex.InnerException;
			}
			return ex;
		}
	}
}
