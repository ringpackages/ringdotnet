/* The delegates that Ring callbacks become. A delegate made from an expression tree is a dynamic method: its Method has no DeclaringType, and some libraries (ML.NET CustomMapping)
   look at the type of the method of a delegate they are given. These delegates are bound to real methods of this class instead: a static method whose first parameter is the
   callback is made into a delegate that has the callback as its target, so the method of the delegate is a method of Bridge.Thunks, with a type. */

using System;
using System.Reflection;

namespace RingDotNet
{
	public static unsafe partial class Bridge
	{
		/* what a thunk calls: the Ring function of the callback and the type of the answer that the delegate must give */
		private sealed class CallbackTarget
		{
			public readonly string Function;
			public readonly Type ReturnType;
			public CallbackTarget(string function, Type returnType) { Function = function; ReturnType = returnType; }
			public object Run(object[] args) { return RaiseCallback(Function, ReturnType, args); }
		}

		private static class Thunks
		{
			public static void Act0(CallbackTarget t) { t.Run(new object[0]); }
			public static void Act1<T1>(CallbackTarget t, T1 a1) { t.Run(new object[] { a1 }); }
			public static void Act2<T1, T2>(CallbackTarget t, T1 a1, T2 a2) { t.Run(new object[] { a1, a2 }); }
			public static void Act3<T1, T2, T3>(CallbackTarget t, T1 a1, T2 a2, T3 a3) { t.Run(new object[] { a1, a2, a3 }); }
			public static void Act4<T1, T2, T3, T4>(CallbackTarget t, T1 a1, T2 a2, T3 a3, T4 a4) { t.Run(new object[] { a1, a2, a3, a4 }); }
			public static void Act5<T1, T2, T3, T4, T5>(CallbackTarget t, T1 a1, T2 a2, T3 a3, T4 a4, T5 a5) { t.Run(new object[] { a1, a2, a3, a4, a5 }); }
			public static void Act6<T1, T2, T3, T4, T5, T6>(CallbackTarget t, T1 a1, T2 a2, T3 a3, T4 a4, T5 a5, T6 a6) { t.Run(new object[] { a1, a2, a3, a4, a5, a6 }); }
			public static void Act7<T1, T2, T3, T4, T5, T6, T7>(CallbackTarget t, T1 a1, T2 a2, T3 a3, T4 a4, T5 a5, T6 a6, T7 a7) { t.Run(new object[] { a1, a2, a3, a4, a5, a6, a7 }); }
			public static void Act8<T1, T2, T3, T4, T5, T6, T7, T8>(CallbackTarget t, T1 a1, T2 a2, T3 a3, T4 a4, T5 a5, T6 a6, T7 a7, T8 a8) { t.Run(new object[] { a1, a2, a3, a4, a5, a6, a7, a8 }); }
			public static R Fun0<R>(CallbackTarget t) { return (R)t.Run(new object[0]); }
			public static R Fun1<R, T1>(CallbackTarget t, T1 a1) { return (R)t.Run(new object[] { a1 }); }
			public static R Fun2<R, T1, T2>(CallbackTarget t, T1 a1, T2 a2) { return (R)t.Run(new object[] { a1, a2 }); }
			public static R Fun3<R, T1, T2, T3>(CallbackTarget t, T1 a1, T2 a2, T3 a3) { return (R)t.Run(new object[] { a1, a2, a3 }); }
			public static R Fun4<R, T1, T2, T3, T4>(CallbackTarget t, T1 a1, T2 a2, T3 a3, T4 a4) { return (R)t.Run(new object[] { a1, a2, a3, a4 }); }
			public static R Fun5<R, T1, T2, T3, T4, T5>(CallbackTarget t, T1 a1, T2 a2, T3 a3, T4 a4, T5 a5) { return (R)t.Run(new object[] { a1, a2, a3, a4, a5 }); }
			public static R Fun6<R, T1, T2, T3, T4, T5, T6>(CallbackTarget t, T1 a1, T2 a2, T3 a3, T4 a4, T5 a5, T6 a6) { return (R)t.Run(new object[] { a1, a2, a3, a4, a5, a6 }); }
			public static R Fun7<R, T1, T2, T3, T4, T5, T6, T7>(CallbackTarget t, T1 a1, T2 a2, T3 a3, T4 a4, T5 a5, T6 a6, T7 a7) { return (R)t.Run(new object[] { a1, a2, a3, a4, a5, a6, a7 }); }
			public static R Fun8<R, T1, T2, T3, T4, T5, T6, T7, T8>(CallbackTarget t, T1 a1, T2 a2, T3 a3, T4 a4, T5 a5, T6 a6, T7 a7, T8 a8) { return (R)t.Run(new object[] { a1, a2, a3, a4, a5, a6, a7, a8 }); }
		}

		/* A delegate of the type delegateType that runs the Ring function, bound to a method of Thunks; null when the delegate has a parameter that a generic method can not take
		   (ref, out, a pointer, a ref struct) or more than 8 parameters: the caller makes it another way */
		private static Delegate TryThunkDelegate(Type delegateType, MethodInfo invoke, ParameterInfo[] ps, string ringFunction)
		{
			if (ps.Length > 8) return null;
			Type[] parameterTypes = new Type[ps.Length];
			for (int i = 0; i < ps.Length; i++)
			{
				Type pt = ps[i].ParameterType;
				if (pt.IsByRef || pt.IsPointer || pt.IsByRefLike) return null;
				parameterTypes[i] = pt;
			}
			Type returnType = invoke.ReturnType;
			if (returnType.IsByRef || returnType.IsPointer || returnType.IsByRefLike) return null;
			try
			{
				bool isVoid = returnType == typeof(void);
				MethodInfo method = typeof(Thunks).GetMethod((isVoid ? "Act" : "Fun") + ps.Length, BindingFlags.Public | BindingFlags.Static);
				Type[] arguments = new Type[parameterTypes.Length + (isVoid ? 0 : 1)];
				if (!isVoid) arguments[0] = returnType;
				Array.Copy(parameterTypes, 0, arguments, isVoid ? 0 : 1, parameterTypes.Length);
				if (arguments.Length > 0) method = method.MakeGenericMethod(arguments);
				return Delegate.CreateDelegate(delegateType, new CallbackTarget(ringFunction, returnType), method, false);
			}
			catch (Exception)
			{
				return null;
			}
		}
	}
}
