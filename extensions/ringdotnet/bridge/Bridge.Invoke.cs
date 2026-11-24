/* Calling a method, or making an object: the call itself and its result. */

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
		private static object CreateInstance(Type t, object[] args)
		{
			if (t.IsAbstract)
			{
				throw new InvalidOperationException("Can't create an instance of the abstract type " + t.FullName);
			}
			if (args.Length == 0 && t.IsValueType)
			{
				return Activator.CreateInstance(t);
			}
			ConstructorInfo ctor = PickCached(ConstructorsOf(t), args, out object[] conv) as ConstructorInfo;
			if (ctor == null)
			{
				throw new MissingMethodException("No public constructor of " + t.FullName + " matches the " + args.Length + " argument(s)");
			}
			return UsesIl(ctor) ? InvokeConstructor(ctor, conv) : ctor.Invoke(conv);
		}

		private static object CallMethod(object target, string name, object[] args)
		{
			Type t;
			object instance = null;
			BindingFlags flags;
			if (target is TypeRef tr)
			{
				t = tr.Type;
				flags = StaticFlags;
			}
			else
			{
				if (target == null)
				{
					throw new NullReferenceException("Can't call '" + name + "' on a null object");
				}
				instance = target;
				t = target.GetType();
				flags = InstanceFlags;
			}
			MethodInfo m = PickCached(MethodsNamed(t, name, flags), args, out object[] conv) as MethodInfo;
			if (m == null && instance != null)
			{
				m = PickFromInterfaces(t, name, args, out conv);
			}
			if (m == null && instance != null)
			{
				MethodBase[] extensions = ExtensionsFor(t, name);
				if (extensions.Length > 0)
				{
					object[] withTarget = new object[args.Length + 1];
					withTarget[0] = instance;
					Array.Copy(args, 0, withTarget, 1, args.Length);
					m = PickCached(extensions, withTarget, out conv) as MethodInfo;
					if (m != null) instance = null;
				}
			}
			if (m == null && args.Length == 0)
			{
				/* a call without arguments of a name that is a property or a field (dnStatic("NodaTime.SystemClock","Instance",[])) reads it */
				try { return GetMember(target, name); }
				catch (MissingMemberException) { }
			}
			if (m == null)
			{
				throw new MissingMethodException("No public method " + t.FullName + "." + name + " matches the " + args.Length + " argument(s)");
			}
			return InvokeResult(m, instance, conv);
		}

		/* A method that the class implements explicitly (a row of Dapper is a public IDictionary<string, object> and has no public get_Item) is
		   found in the public interfaces of the class. */
		private static MethodInfo PickFromInterfaces(Type t, string name, object[] args, out object[] conv)
		{
			conv = null;
			foreach (Type i in t.GetInterfaces())
			{
				if (!i.IsVisible) continue;
				MethodInfo m = PickCached(MethodsNamed(i, name, InstanceFlags), args, out conv) as MethodInfo;
				if (m != null) return m;
			}
			return null;
		}

		/* Run a method and shape its result: methods with out/ref parameters return a list [return value (if any), out/ref values...] */
		/* MethodInfo.Invoke(obj, args), ConstructorInfo.Invoke(args) and Delegate.DynamicInvoke(args) take the arguments of another method as an object[]: the numbers
		   of Ring are doubles there, and reflection does not narrow a double to an int, so the arguments are converted to the parameter types of that method */
		private static void FixInvokeArguments(MethodInfo m, object instance, object[] conv)
		{
			if (m.Name != "Invoke" && m.Name != "DynamicInvoke") return;
			ParameterInfo[] target = instance is MethodBase mb ? mb.GetParameters() : instance is Delegate d ? d.Method.GetParameters() : null;
			if (target == null) return;
			ParameterInfo[] mine = m.GetParameters();
			for (int at = 0; at < mine.Length; at++)
			{
				if (mine[at].ParameterType != typeof(object[]) || !(conv[at] is object[] args)) continue;
				object[] fixedArgs = new object[args.Length];
				for (int i = 0; i < args.Length; i++)
				{
					Type wanted = i < target.Length ? Unwrap(target[i].ParameterType) : null;
					fixedArgs[i] = args[i] is double && wanted != null && TryConvert(args[i], wanted, out object converted, out _) ? converted : args[i];
				}
				conv[at] = fixedArgs;
			}
		}

		private static object InvokeResult(MethodInfo m, object instance, object[] conv)
		{
			FixInvokeArguments(m, instance, conv);
			bool spanCall = UsesIl(m);
			object returned = spanCall ? InvokeWithSpans(m, instance, conv) : m.Invoke(instance, conv);
			if (m.ReturnType.IsPointer) returned = PointerResult(returned);
			if (spanCall && returned is char[] returnedChars && Unwrap(m.ReturnType).IsByRefLike) returned = new string(returnedChars);
			if (ByRefCount(m) == 0)
			{
				return returned;
			}
			List<object> results = new RingList();
			if (m.ReturnType != typeof(void))
			{
				results.Add(returned);
			}
			ParameterInfo[] mps = m.GetParameters();
			for (int i = 0; i < mps.Length; i++)
			{
				Type answered = Unwrap(mps[i].ParameterType);
				bool spanParameter = IsSpan(answered, out _, out bool writableSpan);
				if (mps[i].ParameterType.IsByRef ? ((!answered.IsByRefLike || spanParameter) && !(mps[i].IsIn && !mps[i].IsOut)) : (spanParameter && writableSpan))
				{
					results.Add(spanParameter && conv[i] is char[] chars ? new string(chars) : conv[i]);
				}
			}
			return results;
		}
	}
}
