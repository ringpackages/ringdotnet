using System;
using System.Collections.Generic;

namespace MyCompany.Tools
{
	public enum Level { Low, Medium, High }

	public class Calculator
	{
		public double Total { get; private set; }
		public string Name { get; set; } = "calc";
		public event EventHandler Changed;

		public Calculator() { }
		public Calculator(double start) { Total = start; }

		public Calculator Add(double value) { Total += value; Changed?.Invoke(this, EventArgs.Empty); return this; }
		public Calculator Multiply(double value) { Total *= value; return this; }
		public static int Square(int x) { return x * x; }
		public static string EnumName(Enum value) { return value.GetType().Name + "." + value; }
		public string Describe(Level level, string prefix = "Total") { return prefix + "=" + Total + " (" + level + ")"; }
		public bool TryDivide(double by, out double result)
		{
			result = 0;
			if (by == 0) return false;
			result = Total / by;
			return true;
		}
		public List<string> Words(string text) { return new List<string>(text.Split(' ')); }
		/* a method that returns exactly List<object>: the bridge must hand it over as an object (ObjectList), not as a Ring list */
		public List<object> Mixed() { return new List<object> { 1, "two", 3.5 }; }
		/* generic methods whose type argument the arguments do not show: Ring gives it as a type name (callGeneric) */
		public static T Parse<T>(string text) { return (T)Convert.ChangeType(text, typeof(T), System.Globalization.CultureInfo.InvariantCulture); }
		public T Create<T>() where T : new() { return new T(); }
		/* closed generic types that have no class of their own: the class of the generic definition wraps them */
		public Dictionary<string, int> Counts() { return new Dictionary<string, int> { { "a", 1 }, { "b", 2 } }; }
		/* a nested type: its class is named after the types around it (CalculatorMemory) */
		public class Memory
		{
			public double Stored { get; set; }
			public string Label() { return "stored " + Stored; }
		}
		public Memory Remember() { return new Memory { Stored = Total }; }
		public SortedSet<double> Sorted() { return new SortedSet<double> { 3.5, 1.5 }; }
	}

	// A generic type that no simple type closes (TSelf is constrained by the type itself): its class is made from the open definition
	public class Fluent<TSelf> where TSelf : Fluent<TSelf>
	{
		public int Hits { get; set; }
		public Fluent<TSelf> Hit() { Hits++; return this; }
	}
	public class FluentText : Fluent<FluentText> { }

	// A ref struct of the library: Ring gives a text, the struct is made for the call from the text (its constructor)
	public readonly ref struct Cursor
	{
		private readonly ReadOnlySpan<char> text;
		public Cursor(ReadOnlySpan<char> text) { this.text = text; }
		public int Length { get { return text.Length; } }
		public int Count(char c) { int n = 0; foreach (char x in text) if (x == c) n++; return n; }
	}

	public static class Spans
	{
		public static int CursorLength(Cursor cursor) { return cursor.Length; }
		public static int CountOf(ref Cursor cursor, char c) { return cursor.Count(c); }
		/* a Span result: answered as an array (a text for char) */
		public static ReadOnlySpan<char> Middle(string text) { return text.AsSpan(1, text.Length - 2); }
		public static Span<byte> Head(byte[] data) { return data.AsSpan(0, 2); }
		/* a span that is passed by reference */
		public static bool TrySplit(ReadOnlySpan<char> text, out ReadOnlySpan<char> rest)
		{
			int at = text.IndexOf(',');
			rest = at < 0 ? ReadOnlySpan<char>.Empty : text.Slice(at + 1);
			return at >= 0;
		}
		public static void Skip(ref ReadOnlySpan<char> text, int n) { text = text.Slice(n); }
	}

	public class Counter : Calculator
	{
		public int Count { get; set; }
		public void Increment() { Count++; }
	}
	// An interface that inherits another one, and a class that is not public: Shapes.NewBox returns the interface IBox.
	// The wrapper must be IBox (the interface named after the class), with the members that IBox inherits from IShape.
	public interface IShape
	{
		string Name { get; set; }
		double Area();
	}

	public interface IBox : IShape
	{
		double Side { get; }
	}

	internal class Box : IShape, IBox
	{
		public string Name { get; set; } = "box";
		public double Side { get; private set; }
		public Box(double side) { Side = side; }
		public double Area() { return Side * Side; }
	}

	public static class Shapes
	{
		public static IBox NewBox(double side) { return new Box(side); }
	}
	// A class that is not public and implements a public interface explicitly (a row of Dapper is like this): the methods of the interface
	// are called on the object although the class has no public method of that name.
	public interface IGetter
	{
		string Fetch(string key);
		string Join(string first, string second);
		string Join(string only);
	}

	internal class Hidden : IGetter
	{
		string IGetter.Fetch(string key) { return key + "!"; }
		string IGetter.Join(string first, string second) { return first + "+" + second; }
		string IGetter.Join(string only) { return only; }
	}

	public static class Hiding
	{
		public static object NewGetter() { return new Hidden(); }
	}
	// A class with the name of a class of the library (System.Version): the generator gives it the prefix of its namespace, ToolsVersion,
	// so that both can be defined in one program.
	public class Version
	{
		public string Text { get { return "user version"; } }
	}
	// Extension methods are methods of the Ring class of the type that they extend: calc.Shout("!") is CalculatorExtensions.Shout(calc, "!").
	// Describe has the same name and the same number of parameters as a method of Calculator (the compiler chooses by the type of the value);
	// Add has more parameters than the method of Calculator, so it is not added (an extension never changes the signature of a method).
	public static class CalculatorExtensions
	{
		public static string Shout(this Calculator calc, string suffix) { return calc.Name.ToUpper() + suffix; }
		public static string Describe(this Calculator calc, string format) { return string.Format(format, calc.Total); }
		public static string Add(this Calculator calc, string first, string second) { return first + second; }
	}
	// An extension method of an interface is a method of the classes that implement it (Circle) and of the interfaces that inherit it (IBox).
	public class Circle : IShape
	{
		public string Name { get; set; } = "circle";
		public double Radius { get; set; } = 1;
		public double Area() { return Math.PI * Radius * Radius; }
	}

	public static class ShapeExtensions
	{
		public static string Label(this IShape shape, string prefix) { return prefix + shape.Name; }
	}
}
