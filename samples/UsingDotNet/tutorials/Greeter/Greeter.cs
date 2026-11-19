using System;

namespace Tutorial.Greetings
{
	// An enum: Ring uses its values as texts ("Polite", "Casual")
	public enum Style { Polite, Casual, Shout }

	// A class written in C#: the properties, methods and events below are what Ring can use
	public class Greeter
	{
		// a property that can be read and written
		public string Name { get; set; } = "World";

		// a property that can only be read
		public int Greetings { get; private set; }

		// a method without parameters, and a method with parameters (an overload)
		public string Hello()
		{
			return Hello(Name, Style.Polite);
		}

		public string Hello(string name, Style style = Style.Polite)
		{
			Greetings++;
			string text = style == Style.Casual ? "Hey " + name : "Hello, " + name;
			if (style == Style.Shout) text = text.ToUpper() + "!";
			Greeted?.Invoke(this, text);
			return text;
		}

		// a static method: no object needed
		public static int Add(int a, int b)
		{
			return a + b;
		}

		// a method with an out parameter: Ring gets [result, value]
		public bool TryDivide(double a, double b, out double result)
		{
			result = 0;
			if (b == 0) return false;
			result = a / b;
			return true;
		}

		// an event: Ring sets its handler with setGreetedEvent("...")
		public event EventHandler<string> Greeted;
	}
}
