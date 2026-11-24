/* Arrays, collections and async enumerables: copying the items into a list. */

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
		/* ---------------------------------------------------------------- IAsyncEnumerable
		   Ring has no await foreach. An IAsyncEnumerable<T> that a method returns is read with toList (all the items, waiting for each one), or one item at a
		   time: asyncEnumerator() gives the enumerator, asyncNext() waits for the next item (false at the end), Current is the item, asyncDispose() ends it. */
		private static Type AsyncInterface(Type t, string definition)
		{
			foreach (Type i in t.IsInterface ? new[] { t }.Concat(t.GetInterfaces()) : t.GetInterfaces())
			{
				if (i.IsGenericType && i.GetGenericTypeDefinition().FullName == definition) return i;
			}
			return null;
		}

		private static object GetAsyncEnumerator(object target)
		{
			Type i = target == null ? null : AsyncInterface(target.GetType(), "System.Collections.Generic.IAsyncEnumerable`1");
			if (i == null) throw new ArgumentException("The object is not an IAsyncEnumerable");
			return i.GetMethod("GetAsyncEnumerator").Invoke(target, new object[] { default(System.Threading.CancellationToken) });
		}

		private static bool AsyncNext(object enumerator)
		{
			Type i = enumerator == null ? null : AsyncInterface(enumerator.GetType(), "System.Collections.Generic.IAsyncEnumerator`1");
			if (i == null) throw new ArgumentException("The object is not an IAsyncEnumerator");
			object pending = i.GetMethod("MoveNextAsync").Invoke(enumerator, null);          /* a ValueTask<bool> */
			return ((System.Threading.Tasks.Task<bool>)pending.GetType().GetMethod("AsTask").Invoke(pending, null)).GetAwaiter().GetResult();
		}

		private static void AsyncDispose(object enumerator)
		{
			if (enumerator is IAsyncDisposable disposable) disposable.DisposeAsync().AsTask().GetAwaiter().GetResult();
		}

		private static List<object> AsyncToList(object target)
		{
			object enumerator = GetAsyncEnumerator(target);
			PropertyInfo current = AsyncInterface(enumerator.GetType(), "System.Collections.Generic.IAsyncEnumerator`1").GetProperty("Current");
			List<object> list = new RingList();
			try
			{
				while (AsyncNext(enumerator)) list.Add(current.GetValue(enumerator));
			}
			finally { AsyncDispose(enumerator); }
			return list;
		}

		private static List<object> ToList(object target)
		{
			target = Plain(target);
			if (target != null && !(target is IEnumerable) && AsyncInterface(target.GetType(), "System.Collections.Generic.IAsyncEnumerable`1") != null)
			{
				return AsyncToList(target);
			}
			if (!(Plain(target) is IEnumerable en) || target is string)
			{
				throw new ArgumentException("The object is not enumerable");
			}
			List<object> list = new RingList();
			foreach (object item in en)
			{
				list.Add(item);
			}
			return list;
		}
	}
}
