# Tutorial 1: a first look at .NET from Ring - runtime, types, objects, namespaces
load "dotnet.ring"
using {
	"System"
	"System.Text"
	"System.Collections.Generic"
}

func main
	# 1. The runtime that runs inside your Ring program
	? "Runtime          : .NET " + new Environment().Version.ToString()

	# 2. Everything in .NET is an object of some type (a class)
	oText = new StringBuilder("Hello")
	oType = oText.GetType()
	? "Type of the object: " + oType.FullName
	? "Namespace        : " + oType.Namespace
	? "Is it a class?   : " + oType.IsClass

	# 3. Objects have properties (what they know) and methods (what they can do)
	oText.Append(", .NET")
	? "Property Length  : " + oText.Length
	? "Method ToString(): " + oText.ToString()

	# 4. Some classes are used without creating an object: their members are static
	? "Static Math.Max  : " + new Math().Max(3,9)
	? "Static Math.PI   : " + new Math().PI

	# 5. Structs are small values (a date, a point)
	oDate = new DateTime(2024,12,25)
	? "A DateTime       : " + oDate.ToString_1("yyyy-MM-dd") + " is a " + oDate.DayOfWeek

	# 6. Collections hold many objects
	oNames = new StringList()
	oNames.Add("Ann")
	oNames.Add("Bob")
	? "A list of names  : " + oNames.Count + " items, first is " + oNames.Item(0)

	# 7. null means "no object"
	oMissing = dnNull()
	? "Is it null?      : " + oMissing.isNull()
