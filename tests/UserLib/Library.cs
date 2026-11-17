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
}
