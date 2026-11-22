using System;
using System.Linq;
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
		/* a method called Init: Ring uses init for the constructor of a generated class, so the method is @Init */
		public string Init(string mode) { return "init " + mode; }
		/* a params array may be left out: it is empty */
		public static string Join(string separator, params string[] parts) { return string.Join(separator, parts); }
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

	// ref structs that a method returns: a ref struct enumerator is answered as a list of its items, a ref struct with a text method as the text
	public ref struct WordEnumerator
	{
		private ReadOnlySpan<char> rest;
		public WordEnumerator(ReadOnlySpan<char> text) { rest = text; Current = default; }
		public ReadOnlySpan<char> Current { get; private set; }
		public WordEnumerator GetEnumerator() { return this; }
		public bool MoveNext()
		{
			rest = rest.TrimStart();
			if (rest.IsEmpty) return false;
			int end = rest.IndexOf(' ');
			if (end < 0) end = rest.Length;
			Current = rest.Slice(0, end);
			rest = rest.Slice(end);
			return true;
		}
	}

	public readonly ref struct Label
	{
		private readonly ReadOnlySpan<char> name;
		public Label(ReadOnlySpan<char> name) { this.name = name; }
		public string Render() { return "[" + name.ToString() + "]"; }
	}

	// properties of a Span, a ref struct and a ref type: read like the results of methods
	// methods that return by reference: Ring gets the value
	public class Slots
	{
		private readonly int[] numbers = { 5, 6, 7 };
		private readonly string[] texts = { "x", "y" };
		private DateTime day = new DateTime(2024, 5, 17);
		public ref int Number(int i) { return ref numbers[i]; }
		public ref string Text(int i) { return ref texts[i]; }
		public ref readonly DateTime Day() { return ref day; }
		public int Sum() { return numbers.Sum(); }
	}

	public class Holder
	{
		private readonly byte[] data = { 1, 2, 3 };
		private int slot = 7;
		public ReadOnlySpan<byte> View { get { return data; } }
		public ReadOnlySpan<char> Name { get { return "abc"; } }
		public Label Tag { get { return new Label("tag"); } }
		public ref int Slot { get { return ref slot; } }
	}

	// indexers with several indexes (and one with a single index): Ring gives the indexes as a list
	public class Grid
	{
		private readonly double[,] cells = new double[3, 4];
		private readonly string[] names = { "a", "b" };
		public double this[int row, int column] { get { return cells[row, column]; } set { cells[row, column] = value; } }
		public string this[string x, string y, string z] { get { return x + y + z; } }
		public string this[int i] { get { return names[i]; } set { names[i] = value; } }
	}

	public class Table2
	{
		public int this[int row, int column] { get { return row * 10 + column; } }
	}

	// a ref struct that only holds values (no ToArray, no enumerator, no text method): answered as its properties, then disposed
	public readonly ref struct Lease
	{
		private readonly byte[] data;
		public Lease(byte[] data) { this.data = data; }
		public int Length { get { return data.Length; } }
		public string Name { get { return "lease"; } }
		public ReadOnlySpan<byte> Data { get { return data; } }
		public void Dispose() { Spans.Disposed++; }
	}

	// constructors with a Span or a ref struct, and a ref struct that has only a static factory
	public readonly ref struct Token
	{
		private readonly string text;
		private Token(string text) { this.text = text; }
		public static Token FromString(string text) { return new Token(text); }
		public int Size { get { return text.Length; } }
	}

	public class Message
	{
		public string Text { get; private set; }
		public int Copies { get; private set; }
		public Message(ReadOnlySpan<char> text, int copies) { Text = text.ToString(); Copies = copies; }
		public Message(Token token) { Text = "token"; Copies = token.Size; }
	}

	public static class Spans
	{
		/* an IAsyncEnumerable result: Ring reads it with toList() or asyncEnumerator() */
		public static async System.Collections.Generic.IAsyncEnumerable<int> CountAsync(int n)
		{
			for (int i = 1; i <= n; i++)
			{
				await System.Threading.Tasks.Task.Delay(1);
				yield return i * 10;
			}
		}
		/* a ref return through the IL path (a Span parameter): the value is read from the reference */
		public static ref int ElementAt(Span<int> data, int index) { return ref data[index]; }
		public static int TokenSize(Token token) { return token.Size; }
		public static int Disposed;
		public static Lease Take() { return new Lease(new byte[] { 9, 8, 7 }); }
		public static WordEnumerator Words(string text) { return new WordEnumerator(text); }
		public static Label MakeLabel(string name) { return new Label(name); }
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

	// compares with IComparable<T> only (no operators, no IComparable): the operators < > of Ring use CompareTo
	public class Rank : IComparable<Rank>
	{
		public int Level { get; set; }
		public Rank(int level) { Level = level; }
		public int CompareTo(Rank other) { return Level.CompareTo(other.Level); }
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
	// a struct with an extension method that takes the struct by reference (this in S): called on the object, the answer is the value, not a list
	public readonly struct Money
	{
		public Money(int cents) { Cents = cents; }
		public int Cents { get; }
	}

	public static class MoneyExtensions
	{
		public static string Show(this in Money m, string currency) { return currency + (m.Cents / 100) + "." + (m.Cents % 100).ToString("00"); }
		public static Money Doubled(this in Money m) { return new Money(m.Cents * 2); }
	}
}
