/* Span<T>, ref structs and pointers in parameters: the small IL methods that call such a method, and the factories of ref structs. */

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
		/* Span<T> and ReadOnlySpan<T> */
		internal static bool IsSpan(Type t, out Type element, out bool writable)
		{
			element = null;
			writable = false;
			if (!t.IsGenericType) return false;
			Type def = t.GetGenericTypeDefinition();
			if (def != typeof(Span<>) && def != typeof(ReadOnlySpan<>)) return false;
			element = t.GetGenericArguments()[0];
			writable = def == typeof(Span<>);
			return true;
		}

		private static Type Unwrap(Type t)
		{
			return t.IsByRef ? t.GetElementType() : t;
		}

		/* A ref struct of a library (MessagePackWriter, Utf8JsonReader) cannot be held by Ring or boxed. A parameter of such a type is made for the
		   call from one value: a public op_Implicit(X) or a public constructor whose first parameter is X (the others optional), with X something
		   Ring can give (a text, an array, an object). The struct is not answered: what the method does to it is lost. */
		private static readonly System.Collections.Concurrent.ConcurrentDictionary<Type, MethodBase> RefStructFactories =
			new System.Collections.Concurrent.ConcurrentDictionary<Type, MethodBase>();

		internal static MethodBase RefStructFactory(Type refStruct)
		{
			return RefStructFactories.GetOrAdd(refStruct, FindRefStructFactory);
		}

		private static bool Convertible(Type source)
		{
			return !source.IsPointer && !source.IsByRef && (!source.IsByRefLike || IsSpan(source, out _, out _));
		}

		private static MethodBase FindRefStructFactory(Type r)
		{
			foreach (MethodInfo m in r.GetMethods(BindingFlags.Public | BindingFlags.Static))
			{
				if (m.Name == "op_Implicit" && m.ReturnType == r && m.GetParameters().Length == 1 && Convertible(m.GetParameters()[0].ParameterType)) return m;
			}
			ConstructorInfo best = null;
			foreach (ConstructorInfo c in r.GetConstructors(BindingFlags.Public | BindingFlags.Instance))
			{
				ParameterInfo[] cps = c.GetParameters();
				if (cps.Length == 0 || !Convertible(cps[0].ParameterType) || cps.Skip(1).Any(q => !q.IsOptional)) continue;
				if (best == null || cps.Length < best.GetParameters().Length) best = c;
			}
			if (best != null) return best;
			/* a static factory with one value (utf8z.FromString): From..., Create..., Parse..., Wrap... */
			foreach (MethodInfo m in r.GetMethods(BindingFlags.Public | BindingFlags.Static))
			{
				if (m.ReturnType != r || m.GetParameters().Length != 1 || !Convertible(m.GetParameters()[0].ParameterType)) continue;
				if (m.Name.StartsWith("From", StringComparison.Ordinal) || m.Name.StartsWith("Create", StringComparison.Ordinal) || m.Name.StartsWith("Parse", StringComparison.Ordinal) || m.Name.StartsWith("Wrap", StringComparison.Ordinal)) return m;
			}
			return null;
		}

		private static Type FactorySource(MethodBase factory)
		{
			return factory.GetParameters()[0].ParameterType;
		}

		/* A method that is called through IL (see InvokeWithSpans): a Span or ref struct parameter, or a Span or ref struct result */
		private static bool UsesIl(MethodBase m)
		{
			return m.GetParameters().Any(p => { Type t = Unwrap(p.ParameterType); return IsSpan(t, out _, out _) || (t.IsByRefLike && RefStructFactory(t) != null); })
				|| (m is MethodInfo mi && (IsSpan(Unwrap(mi.ReturnType), out _, out _) || (Unwrap(mi.ReturnType).IsByRefLike && ResultPlanOf(Unwrap(mi.ReturnType)) != null)));
		}

		/* A ref struct that a method returns cannot be boxed. It is answered as what it holds when it can be read in one go: an array (a ToArray
		   method), a list of its items (a ref struct enumerator, or one with GetEnumerator: foreach), or a text (the one method without parameters
		   that returns a string: ToString, utf8_to_string). */
		internal sealed class ResultPlan
		{
			public string Kind;            // "array", "list", "text", "properties"
			public PropertyInfo[] Properties;          // "properties": the readable properties, answered as [name, value] pairs
			public MethodInfo Dispose;     // a Dispose() of the struct: called after it was read (what foreach does)
			public MethodInfo Method;      // ToArray, or the method that gives the text, or GetEnumerator (null when the struct is the enumerator)
			public Type Enumerator;
			public MethodInfo MoveNext, Current;
		}

		private static readonly System.Collections.Concurrent.ConcurrentDictionary<Type, ResultPlan> ResultPlans =
			new System.Collections.Concurrent.ConcurrentDictionary<Type, ResultPlan>();

		internal static ResultPlan ResultPlanOf(Type refStruct)
		{
			return ResultPlans.GetOrAdd(refStruct, r =>
			{
				ResultPlan plan = FindResultPlan(r);
				if (plan != null) plan.Dispose = r.GetMethod("Dispose", BindingFlags.Public | BindingFlags.Instance, null, Type.EmptyTypes, null);
				return plan;
			});
		}

		private static ResultPlan FindResultPlan(Type r)
		{
			const BindingFlags own = BindingFlags.Public | BindingFlags.Instance;
			MethodInfo toArray = r.GetMethod("ToArray", own, null, Type.EmptyTypes, null);
			if (toArray != null && toArray.ReturnType.IsArray) return new ResultPlan { Kind = "array", Method = toArray };
			MethodInfo getEnumerator = r.GetMethod("GetEnumerator", own, null, Type.EmptyTypes, null);
			Type enumerator = getEnumerator != null ? getEnumerator.ReturnType : r;
			MethodInfo moveNext = enumerator.GetMethod("MoveNext", own, null, Type.EmptyTypes, null);
			PropertyInfo current = enumerator.GetProperty("Current", own);
			if (moveNext != null && moveNext.ReturnType == typeof(bool) && current?.GetMethod != null && !(current.PropertyType.IsByRefLike && !IsSpan(current.PropertyType, out _, out _)))
			{
				return new ResultPlan { Kind = "list", Method = getEnumerator, Enumerator = enumerator, MoveNext = moveNext, Current = current.GetMethod };
			}
			MethodInfo text = r.GetMethod("ToString", own, null, Type.EmptyTypes, null);
			if (text == null || text.DeclaringType != r)
			{
				MethodInfo[] texts = r.GetMethods(own | BindingFlags.DeclaredOnly).Where(x => x.ReturnType == typeof(string) && x.GetParameters().Length == 0 && !x.IsSpecialName).ToArray();
				text = texts.Length == 1 ? texts[0] : null;
			}
			if (text != null) return new ResultPlan { Kind = "text", Method = text };
			/* a struct that only holds values (a buffer lease: Data, Length, Flags): its readable properties, as [name, value] pairs */
			PropertyInfo[] properties = r.GetProperties(own).Where(x => x.GetIndexParameters().Length == 0 && x.GetMethod != null && x.GetMethod.IsPublic && !x.PropertyType.IsPointer && !x.PropertyType.IsByRef
				&& !(x.PropertyType.IsByRefLike && !IsSpan(x.PropertyType, out _, out _))).ToArray();
			return properties.Length > 0 ? new ResultPlan { Kind = "properties", Properties = properties } : null;
		}

		/* [name, value] of a property of a ref struct that is answered as its properties */
		public static void AddResultPair(List<object> list, string name, object value)
		{
			list.Add(new RingList { name, value is char[] chars ? new string(chars) : value });
		}

		/* an item of the list that a ref struct enumerator gives: a char array is a text */
		public static void AddResultItem(List<object> list, object item)
		{
			list.Add(item is char[] chars ? new string(chars) : item);
		}

		private static void EmitInstanceCall(System.Reflection.Emit.ILGenerator il, System.Reflection.Emit.LocalBuilder local, MethodInfo method)
		{
			if (local.LocalType.IsValueType)
			{
				il.Emit(System.Reflection.Emit.OpCodes.Ldloca, local);
				il.Emit(System.Reflection.Emit.OpCodes.Call, method);
			}
			else
			{
				il.Emit(System.Reflection.Emit.OpCodes.Ldloc, local);
				il.Emit(System.Reflection.Emit.OpCodes.Callvirt, method);
			}
		}

		/* the ref struct on the stack becomes the object that is answered */
		private static void EmitRefStructResult(System.Reflection.Emit.ILGenerator il, Type refStruct)
		{
			ResultPlan plan = ResultPlanOf(refStruct);
			System.Reflection.Emit.LocalBuilder value = il.DeclareLocal(refStruct);
			il.Emit(System.Reflection.Emit.OpCodes.Stloc, value);
			if (plan.Kind == "array" || plan.Kind == "text")
			{
				il.Emit(System.Reflection.Emit.OpCodes.Ldloca, value);
				il.Emit(System.Reflection.Emit.OpCodes.Call, plan.Method);
				EmitDispose(il, value, plan);
				return;
			}
			if (plan.Kind == "properties")
			{
				System.Reflection.Emit.LocalBuilder pairs = il.DeclareLocal(typeof(RingList));
				il.Emit(System.Reflection.Emit.OpCodes.Newobj, typeof(RingList).GetConstructor(Type.EmptyTypes));
				il.Emit(System.Reflection.Emit.OpCodes.Stloc, pairs);
				foreach (PropertyInfo property in plan.Properties)
				{
					il.Emit(System.Reflection.Emit.OpCodes.Ldloc, pairs);
					il.Emit(System.Reflection.Emit.OpCodes.Ldstr, property.Name);
					il.Emit(System.Reflection.Emit.OpCodes.Ldloca, value);
					il.Emit(System.Reflection.Emit.OpCodes.Call, property.GetMethod);
					Type type = property.PropertyType;
					if (IsSpan(type, out _, out _))
					{
						System.Reflection.Emit.LocalBuilder span = il.DeclareLocal(type);
						il.Emit(System.Reflection.Emit.OpCodes.Stloc, span);
						il.Emit(System.Reflection.Emit.OpCodes.Ldloca, span);
						il.Emit(System.Reflection.Emit.OpCodes.Call, type.GetMethod("ToArray", Type.EmptyTypes));
					}
					else if (type.IsValueType) il.Emit(System.Reflection.Emit.OpCodes.Box, type);
					il.Emit(System.Reflection.Emit.OpCodes.Call, typeof(Bridge).GetMethod("AddResultPair"));
				}
				EmitDispose(il, value, plan);
				il.Emit(System.Reflection.Emit.OpCodes.Ldloc, pairs);
				return;
			}
			System.Reflection.Emit.LocalBuilder list = il.DeclareLocal(typeof(RingList));
			il.Emit(System.Reflection.Emit.OpCodes.Newobj, typeof(RingList).GetConstructor(Type.EmptyTypes));
			il.Emit(System.Reflection.Emit.OpCodes.Stloc, list);
			System.Reflection.Emit.LocalBuilder enumerator = il.DeclareLocal(plan.Enumerator);
			if (plan.Method != null)
			{
				il.Emit(System.Reflection.Emit.OpCodes.Ldloca, value);
				il.Emit(System.Reflection.Emit.OpCodes.Call, plan.Method);
			}
			else il.Emit(System.Reflection.Emit.OpCodes.Ldloc, value);
			il.Emit(System.Reflection.Emit.OpCodes.Stloc, enumerator);
			System.Reflection.Emit.Label top = il.DefineLabel();
			System.Reflection.Emit.Label end = il.DefineLabel();
			il.MarkLabel(top);
			EmitInstanceCall(il, enumerator, plan.MoveNext);
			il.Emit(System.Reflection.Emit.OpCodes.Brfalse, end);
			il.Emit(System.Reflection.Emit.OpCodes.Ldloc, list);
			EmitInstanceCall(il, enumerator, plan.Current);
			Type item = plan.Current.ReturnType;
			if (IsSpan(item, out _, out _))
			{
				System.Reflection.Emit.LocalBuilder span = il.DeclareLocal(item);
				il.Emit(System.Reflection.Emit.OpCodes.Stloc, span);
				il.Emit(System.Reflection.Emit.OpCodes.Ldloca, span);
				il.Emit(System.Reflection.Emit.OpCodes.Call, item.GetMethod("ToArray", Type.EmptyTypes));
			}
			else if (item.IsValueType) il.Emit(System.Reflection.Emit.OpCodes.Box, item);
			il.Emit(System.Reflection.Emit.OpCodes.Call, typeof(Bridge).GetMethod("AddResultItem"));
			il.Emit(System.Reflection.Emit.OpCodes.Br, top);
			il.MarkLabel(end);
			EmitDispose(il, value, plan);
			il.Emit(System.Reflection.Emit.OpCodes.Ldloc, list);
		}

		/* a ref struct that has Dispose() is disposed after it was read */
		private static void EmitDispose(System.Reflection.Emit.ILGenerator il, System.Reflection.Emit.LocalBuilder value, ResultPlan plan)
		{
			if (plan.Dispose == null) return;
			il.Emit(System.Reflection.Emit.OpCodes.Ldloca, value);
			il.Emit(System.Reflection.Emit.OpCodes.Call, plan.Dispose);
		}

		/* A parameter that Ring does not give as it is: the overloads with it are listed only when no other overload of the name has a plain form */
		private static bool HasSpanParameter(MethodBase m)
		{
			return UsesIl(m) || m.GetParameters().Any(p => Unwrap(p.ParameterType).IsPointer);
		}

		private static readonly System.Collections.Concurrent.ConcurrentDictionary<MethodInfo, Func<object, object[], object>> SpanCalls =
			new System.Collections.Concurrent.ConcurrentDictionary<MethodInfo, Func<object, object[], object>>();

		/* A method with a Span<T> or ReadOnlySpan<T> parameter or result, or a ref struct parameter, cannot be called by reflection (a ref struct
		   cannot be boxed). A small method is made with IL for it: it takes the object[] of the arguments, makes each span around the array that Ring
		   gave (and each ref struct from its value), calls the method, and puts the values of ref and out parameters back into the array (a span as
		   an array). A Span result is answered as an array. */
		private static object InvokeWithSpans(MethodInfo m, object instance, object[] conv)
		{
			ParameterInfo[] ps = m.GetParameters();
			for (int i = 0; i < ps.Length; i++)
			{
				Type pt = Unwrap(ps[i].ParameterType);
				if (conv[i] == Type.Missing || (conv[i] == null && pt.IsValueType && !pt.IsByRefLike && Nullable.GetUnderlyingType(pt) == null))
				{
					conv[i] = pt.IsValueType && !pt.IsByRefLike ? Activator.CreateInstance(pt) : null;
				}
			}
			return SpanCalls.GetOrAdd(m, BuildSpanCall)(instance, conv);
		}

		private static readonly System.Collections.Concurrent.ConcurrentDictionary<ConstructorInfo, Func<object[], object>> CtorCalls =
			new System.Collections.Concurrent.ConcurrentDictionary<ConstructorInfo, Func<object[], object>>();

		/* A constructor with a Span or ref struct parameter: the same small IL method, with newobj */
		private static object InvokeConstructor(ConstructorInfo ctor, object[] conv)
		{
			ParameterInfo[] ps = ctor.GetParameters();
			for (int i = 0; i < ps.Length; i++)
			{
				Type pt = Unwrap(ps[i].ParameterType);
				if (conv[i] == Type.Missing || (conv[i] == null && pt.IsValueType && !pt.IsByRefLike && Nullable.GetUnderlyingType(pt) == null))
				{
					conv[i] = pt.IsValueType && !pt.IsByRefLike ? Activator.CreateInstance(pt) : null;
				}
			}
			return CtorCalls.GetOrAdd(ctor, c =>
			{
				System.Reflection.Emit.DynamicMethod dm = new System.Reflection.Emit.DynamicMethod("CtorCall", typeof(object), new[] { typeof(object[]) }, typeof(Bridge).Module, true);
				System.Reflection.Emit.ILGenerator il = dm.GetILGenerator();
				ParameterInfo[] cps = c.GetParameters();
				for (int i = 0; i < cps.Length; i++)
				{
					if (cps[i].ParameterType.IsByRef) throw new NotSupportedException("A constructor with a ref parameter and a Span is not supported");
					EmitValue(il, cps[i].ParameterType, i, 0);
				}
				il.Emit(System.Reflection.Emit.OpCodes.Newobj, c);
				if (c.DeclaringType.IsValueType) il.Emit(System.Reflection.Emit.OpCodes.Box, c.DeclaringType);
				il.Emit(System.Reflection.Emit.OpCodes.Ret);
				return (Func<object[], object>)dm.CreateDelegate(typeof(Func<object[], object>));
			})(conv);
		}

		/* the argument i of the object[] as a value of the type: a span from its array, a ref struct from its source value, any other value unboxed */
		private static void EmitValue(System.Reflection.Emit.ILGenerator il, Type type, int index, int argumentsArgument = 1)
		{
			il.Emit(argumentsArgument == 1 ? System.Reflection.Emit.OpCodes.Ldarg_1 : System.Reflection.Emit.OpCodes.Ldarg_0);
			il.Emit(System.Reflection.Emit.OpCodes.Ldc_I4, index);
			il.Emit(System.Reflection.Emit.OpCodes.Ldelem_Ref);
			if (IsSpan(type, out Type element, out _))
			{
				il.Emit(System.Reflection.Emit.OpCodes.Castclass, element.MakeArrayType());
				il.Emit(System.Reflection.Emit.OpCodes.Call, type.GetMethod("op_Implicit", new[] { element.MakeArrayType() }));
			}
			else if (type.IsByRefLike)
			{
				MethodBase factory = RefStructFactory(type);
				Type source = FactorySource(factory);
				if (IsSpan(source, out Type sourceElement, out _))
				{
					il.Emit(System.Reflection.Emit.OpCodes.Castclass, sourceElement.MakeArrayType());
					il.Emit(System.Reflection.Emit.OpCodes.Call, source.GetMethod("op_Implicit", new[] { sourceElement.MakeArrayType() }));
				}
				else il.Emit(System.Reflection.Emit.OpCodes.Unbox_Any, source);
				if (factory is ConstructorInfo ctor)
				{
					foreach (ParameterInfo rest in ctor.GetParameters().Skip(1)) EmitDefault(il, rest.ParameterType);
					il.Emit(System.Reflection.Emit.OpCodes.Newobj, ctor);
				}
				else il.Emit(System.Reflection.Emit.OpCodes.Call, (MethodInfo)factory);
			}
			else il.Emit(System.Reflection.Emit.OpCodes.Unbox_Any, type);
		}

		private static void EmitDefault(System.Reflection.Emit.ILGenerator il, Type type)
		{
			if (!type.IsValueType) { il.Emit(System.Reflection.Emit.OpCodes.Ldnull); return; }
			System.Reflection.Emit.LocalBuilder temp = il.DeclareLocal(type);
			il.Emit(System.Reflection.Emit.OpCodes.Ldloca, temp);
			il.Emit(System.Reflection.Emit.OpCodes.Initobj, type);
			il.Emit(System.Reflection.Emit.OpCodes.Ldloc, temp);
		}

		private static Func<object, object[], object> BuildSpanCall(MethodInfo m)
		{
			ParameterInfo[] ps = m.GetParameters();
			Type declaring = m.DeclaringType;
			System.Reflection.Emit.DynamicMethod dm = new System.Reflection.Emit.DynamicMethod("SpanCall", typeof(object), new[] { typeof(object), typeof(object[]) }, typeof(Bridge).Module, true);
			System.Reflection.Emit.ILGenerator il = dm.GetILGenerator();
			System.Reflection.Emit.LocalBuilder[] locals = new System.Reflection.Emit.LocalBuilder[ps.Length];
			for (int i = 0; i < ps.Length; i++)
			{
				if (!ps[i].ParameterType.IsByRef) continue;
				Type et = ps[i].ParameterType.GetElementType();
				locals[i] = il.DeclareLocal(et);
				if (IsSpan(et, out Type spanElement, out _))
				{
					/* a span that is passed by reference: made from the array when there is one, else the empty span (an out parameter) */
					System.Reflection.Emit.LocalBuilder array = il.DeclareLocal(spanElement.MakeArrayType());
					System.Reflection.Emit.Label none = il.DefineLabel();
					il.Emit(System.Reflection.Emit.OpCodes.Ldarg_1);
					il.Emit(System.Reflection.Emit.OpCodes.Ldc_I4, i);
					il.Emit(System.Reflection.Emit.OpCodes.Ldelem_Ref);
					il.Emit(System.Reflection.Emit.OpCodes.Castclass, spanElement.MakeArrayType());
					il.Emit(System.Reflection.Emit.OpCodes.Stloc, array);
					il.Emit(System.Reflection.Emit.OpCodes.Ldloc, array);
					il.Emit(System.Reflection.Emit.OpCodes.Brfalse, none);
					il.Emit(System.Reflection.Emit.OpCodes.Ldloc, array);
					il.Emit(System.Reflection.Emit.OpCodes.Call, et.GetMethod("op_Implicit", new[] { spanElement.MakeArrayType() }));
					il.Emit(System.Reflection.Emit.OpCodes.Stloc, locals[i]);
					il.MarkLabel(none);
				}
				else if (et.IsByRefLike)
				{
					EmitValue(il, et, i);
					il.Emit(System.Reflection.Emit.OpCodes.Stloc, locals[i]);
				}
				else
				{
					il.Emit(System.Reflection.Emit.OpCodes.Ldarg_1);
					il.Emit(System.Reflection.Emit.OpCodes.Ldc_I4, i);
					il.Emit(System.Reflection.Emit.OpCodes.Ldelem_Ref);
					il.Emit(System.Reflection.Emit.OpCodes.Unbox_Any, et);
					il.Emit(System.Reflection.Emit.OpCodes.Stloc, locals[i]);
				}
			}
			if (!m.IsStatic)
			{
				il.Emit(System.Reflection.Emit.OpCodes.Ldarg_0);
				if (declaring.IsValueType) il.Emit(System.Reflection.Emit.OpCodes.Unbox, declaring);
				else il.Emit(System.Reflection.Emit.OpCodes.Castclass, declaring);
			}
			for (int i = 0; i < ps.Length; i++)
			{
				if (locals[i] != null) il.Emit(System.Reflection.Emit.OpCodes.Ldloca, locals[i]);
				else EmitValue(il, ps[i].ParameterType, i);
			}
			il.Emit(m.IsStatic || declaring.IsValueType ? System.Reflection.Emit.OpCodes.Call : System.Reflection.Emit.OpCodes.Callvirt, m);
			System.Reflection.Emit.LocalBuilder result = il.DeclareLocal(typeof(object));
			Type returned = Unwrap(m.ReturnType);          /* a ref return: the value is read from the reference first */
			if (m.ReturnType.IsByRef && returned != typeof(void)) il.Emit(System.Reflection.Emit.OpCodes.Ldobj, returned);
			if (returned == typeof(void)) il.Emit(System.Reflection.Emit.OpCodes.Ldnull);
			else if (IsSpan(returned, out Type resultElement, out _))
			{
				/* a Span result is answered as an array */
				System.Reflection.Emit.LocalBuilder span = il.DeclareLocal(returned);
				il.Emit(System.Reflection.Emit.OpCodes.Stloc, span);
				il.Emit(System.Reflection.Emit.OpCodes.Ldloca, span);
				il.Emit(System.Reflection.Emit.OpCodes.Call, returned.GetMethod("ToArray", Type.EmptyTypes));
			}
			else if (returned.IsByRefLike) EmitRefStructResult(il, returned);
			else if (returned.IsValueType) il.Emit(System.Reflection.Emit.OpCodes.Box, returned);
			il.Emit(System.Reflection.Emit.OpCodes.Stloc, result);
			for (int i = 0; i < ps.Length; i++)
			{
				if (locals[i] == null) continue;
				Type et = ps[i].ParameterType.GetElementType();
				if (et.IsByRefLike && !IsSpan(et, out _, out _)) continue;
				il.Emit(System.Reflection.Emit.OpCodes.Ldarg_1);
				il.Emit(System.Reflection.Emit.OpCodes.Ldc_I4, i);
				if (IsSpan(et, out _, out _))
				{
					il.Emit(System.Reflection.Emit.OpCodes.Ldloca, locals[i]);
					il.Emit(System.Reflection.Emit.OpCodes.Call, et.GetMethod("ToArray", Type.EmptyTypes));
				}
				else
				{
					il.Emit(System.Reflection.Emit.OpCodes.Ldloc, locals[i]);
					if (et.IsValueType) il.Emit(System.Reflection.Emit.OpCodes.Box, et);
				}
				il.Emit(System.Reflection.Emit.OpCodes.Stelem_Ref);
			}
			il.Emit(System.Reflection.Emit.OpCodes.Ldloc, result);
			il.Emit(System.Reflection.Emit.OpCodes.Ret);
			return (Func<object, object[], object>)dm.CreateDelegate(typeof(Func<object, object[], object>));
		}
	}
}
