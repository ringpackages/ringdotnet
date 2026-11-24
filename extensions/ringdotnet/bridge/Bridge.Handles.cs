/* The handle table: .NET objects stay in .NET, and Ring holds the number of the entry. */

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
		private static readonly Dictionary<long, object> Handles = new Dictionary<long, object>();

		private static readonly object Sync = new object();

		private static long NextHandle = 1;

		private static long Register(object value)
		{
			long id = NextHandle++;
			Handles[id] = value;
			return id;
		}

		private static object Lookup(long id)
		{
			if (!Handles.TryGetValue(id, out object value))
			{
				throw new ArgumentException("Invalid or released .NET object handle: " + id);
			}
			return value;
		}

		/* The handle of a new object; 0 when the value is not an object for Ring (it travels as a text, a number...: see Encode) */
		private static object NewHandle(object value)
		{
			switch (value)
			{
				case null or string or char or bool or byte[] or Enum or decimal or double or float:
				case sbyte or byte or short or ushort or int or uint or long or ulong:
				case List<object> when RingList.IsResult(value):
					return 0.0;
				default:
					return (double)Register(value);
			}
		}
	}
}
