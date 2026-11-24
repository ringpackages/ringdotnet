/* Properties and fields: reading and writing them. */

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
		/* A property by name; a property that hides one of a base class (CheckedListBox.Items) is the one of the most derived type */
		private static PropertyInfo FindProperty(Type t, string name, BindingFlags f)
		{
			try
			{
				return t.GetProperty(name, f);
			}
			catch (AmbiguousMatchException)
			{
				PropertyInfo best = null;
				foreach (PropertyInfo p in t.GetProperties(f))
				{
					if (p.Name != name && !(f.HasFlag(BindingFlags.IgnoreCase) && string.Equals(p.Name, name, StringComparison.OrdinalIgnoreCase))) continue;
					if (p.GetIndexParameters().Length > 0) continue;
					if (best == null || best.DeclaringType.IsAssignableFrom(p.DeclaringType)) best = p;
				}
				return best;
			}
		}

		private static object GetMember(object target, string name)
		{
			Type t = target is TypeRef tr ? tr.Type : target?.GetType();
			object instance = target is TypeRef ? null : target;
			if (t == null)
			{
				throw new NullReferenceException("Can't read '" + name + "' from a null object");
			}
			BindingFlags flags = target is TypeRef ? StaticFlags : InstanceFlags;
			foreach (BindingFlags f in new[] { flags, flags | BindingFlags.IgnoreCase })
			{
				PropertyInfo p = FindProperty(t, name, f);
				if (p != null && p.GetIndexParameters().Length == 0)
				{
					/* a Span or ref struct property, a pointer, or a ref property is read like the result of a method (see InvokeResult) */
					if (p.GetMethod != null && (p.PropertyType.IsByRefLike || p.PropertyType.IsPointer || p.PropertyType.IsByRef)) return InvokeResult(p.GetMethod, instance, new object[0]);
					return p.GetValue(instance);
				}
				FieldInfo fi = t.GetField(name, f);
				if (fi != null)
				{
					return fi.FieldType.IsPointer ? PointerResult(fi.GetValue(instance)) : fi.GetValue(instance);
				}
			}
			if (instance != null)
			{
				/* a property that the class implements explicitly (the Current of a compiler-made async iterator) is found in its public interfaces */
				foreach (Type i in t.GetInterfaces())
				{
					if (!i.IsVisible) continue;
					PropertyInfo ip = i.GetProperty(name, BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);
					if (ip != null && ip.GetIndexParameters().Length == 0 && ip.CanRead) return ip.GetValue(instance);
				}
			}
			throw new MissingMemberException("No public property or field " + t.FullName + "." + name);
		}

		private static void SetMember(object target, string name, object value)
		{
			Type t = target is TypeRef tr ? tr.Type : target?.GetType();
			object instance = target is TypeRef ? null : target;
			if (t == null)
			{
				throw new NullReferenceException("Can't write '" + name + "' on a null object");
			}
			BindingFlags flags = target is TypeRef ? StaticFlags : InstanceFlags;
			foreach (BindingFlags f in new[] { flags, flags | BindingFlags.IgnoreCase })
			{
				PropertyInfo p = FindProperty(t, name, f);
				if (p != null && p.CanWrite)
				{
					if (!TryConvert(value, p.PropertyType, out object conv, out int _))
					{
						throw new ArgumentException("Can't convert the value to " + p.PropertyType.FullName);
					}
					p.SetValue(instance, conv);
					return;
				}
				FieldInfo fi = t.GetField(name, f);
				if (fi != null)
				{
					if (!TryConvert(value, fi.FieldType, out object conv, out int _))
					{
						throw new ArgumentException("Can't convert the value to " + fi.FieldType.FullName);
					}
					fi.SetValue(instance, conv);
					return;
				}
			}
			throw new MissingMemberException("No writable public property or field " + t.FullName + "." + name);
		}
	}
}
