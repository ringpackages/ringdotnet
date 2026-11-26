/* Events and delegates: Ring code that .NET calls, and the callbacks that run it. */

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
		/* The handlers set from Ring, per object and event name (one handler per event, like RingQt) */
		private static readonly ConditionalWeakTable<object, Dictionary<string, Delegate>> EventHandlers =
			new ConditionalWeakTable<object, Dictionary<string, Delegate>>();

		private static void SetEvent(object target, string name, object callback)
		{
			Type t = target is TypeRef tr ? tr.Type : target?.GetType();
			object instance = target is TypeRef ? null : target;
			if (t == null)
			{
				throw new NullReferenceException("Can't use the event '" + name + "' of a null object");
			}
			BindingFlags flags = (target is TypeRef ? BindingFlags.Static : BindingFlags.Instance) | BindingFlags.Public;
			EventInfo ev = t.GetEvent(name, flags) ?? t.GetEvent(name, flags | BindingFlags.IgnoreCase);
			if (ev == null)
			{
				throw new MissingMemberException("No public event " + t.FullName + "." + name);
			}
			object key = target is TypeRef ? (object)t : target;
			Dictionary<string, Delegate> map = EventHandlers.GetOrCreateValue(key);
			if (map.TryGetValue(ev.Name, out Delegate old))
			{
				ev.RemoveEventHandler(instance, old);
				map.Remove(ev.Name);
			}
			if (callback is CallbackRef cb)
			{
				Delegate handler = MakeDelegate(ev.EventHandlerType, cb.Name);
				ev.AddEventHandler(instance, handler);
				map[ev.Name] = handler;
			}
			else if (callback != null)
			{
				throw new ArgumentException("The event handler must be created with dnCallback()");
			}
		}

		private static Delegate MakeDelegate(Type delegateType, string ringFunction)
		{
			MethodInfo invoke = delegateType.GetMethod("Invoke");
			ParameterInfo[] ps = invoke.GetParameters();
			Delegate thunk = TryThunkDelegate(delegateType, invoke, ps, ringFunction);
			if (thunk != null) return thunk;
			ParameterExpression[] pe = new ParameterExpression[ps.Length];
			Expression[] boxed = new Expression[ps.Length];
			for (int i = 0; i < ps.Length; i++)
			{
				if (ps[i].ParameterType.IsByRef)
				{
					throw new NotSupportedException("Ring callbacks can't use ref/out parameters");
				}
				pe[i] = Expression.Parameter(ps[i].ParameterType, ps[i].Name);
				boxed[i] = Expression.Convert(pe[i], typeof(object));
			}
			Expression call = Expression.Call(typeof(Bridge).GetMethod(nameof(RaiseCallback), BindingFlags.NonPublic | BindingFlags.Static),
				Expression.Constant(ringFunction), Expression.Constant(invoke.ReturnType, typeof(Type)),
				Expression.NewArrayInit(typeof(object), boxed));
			Expression body = invoke.ReturnType == typeof(void)
				? call
				: (Expression)Expression.Convert(call, invoke.ReturnType);
			return Expression.Lambda(delegateType, body, pe).Compile();
		}

		/* For other assemblies (RingDotNet.Data): run the Ring function of a callback made with dnCallback() */
		public static object CallRing(object callback, Type returnType, object[] args)
		{
			if (callback is CallbackRef cb) return RaiseCallback(cb.Name, returnType, args);
			throw new ArgumentException("The callback must be created with dnCallback() (got " + (callback == null ? "null" : callback.GetType().FullName) + ")");
		}

		/* Called by the generated delegates: run the Ring function and convert its result */
		private static object RaiseCallback(string ringFunction, Type returnType, object[] args)
		{
			if (NativeCallback == null || Depth == 0 || Environment.CurrentManagedThreadId != RingThread)
			{
				Console.Error.WriteLine("RingDotNet: the callback '" + ringFunction + "' was ignored (Ring callbacks only run on the Ring thread during a call)");
				return returnType.IsValueType && returnType != typeof(void) ? Activator.CreateInstance(returnType) : null;
			}
			MemoryStream ms = new MemoryStream();
			WriteItem(ms, 's', Encoding.UTF8.GetBytes(ringFunction));
			foreach (object arg in args)
			{
				Encode(ms, arg);
			}
			byte[] request = ms.ToArray();
			byte[] response = new byte[4096];
			int size;
			fixed (byte* req = request)
			fixed (byte* resp = response)
			{
				size = NativeCallback(req, request.Length, resp, response.Length);
			}
			if (size > response.Length)
			{
				response = new byte[size];
				fixed (byte* resp = response)
				{
					NativeCallback(null, 0, resp, response.Length);
				}
			}
			List<object> items = Decode(new ReadOnlySpan<byte>(response, 0, size));
			if (returnType == typeof(void))
			{
				return null;
			}
			object value = items.Count > 0 ? items[0] : null;
			if (!TryConvert(value, returnType, out object converted, out int _))
			{
				throw new InvalidCastException("Can't convert the Ring callback result to " + returnType.FullName);
			}
			return converted;
		}
	}
}
