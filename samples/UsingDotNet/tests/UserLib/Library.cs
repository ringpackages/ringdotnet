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
}
