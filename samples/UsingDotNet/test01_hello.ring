load "dotnetlib.ring"

? "Runtime : " + dnVersion()

# Static members
oConsole = dnType("System.Console")
oConsole.callMethod("WriteLine",["Hello from .NET (Console.WriteLine)"])

? "Math.Max(3,9)    = " + dnStatic("System.Math","Max",[3,9])
? "Math.Sqrt(144)   = " + dnStatic("System.Math","Sqrt",[144])
? "Math.PI          = " + dnType("System.Math").getProp("PI")
? "Environment.OS   = " + dnType("System.Environment").getProp("OSVersion").toString()

# Instances
oSB = dnNew("System.Text.StringBuilder",["Hello"])
oSB.callMethod("Append",[", "])
oSB.callMethod("Append",["Ring"])
oSB.callMethod("Append",["!"])
? oSB.toString()
? "Length = " + oSB.getProp("Length")
? "Type   = " + oSB.typeName()

# Collections
oList = dnNew("System.Collections.Generic.List`1[[System.String]]",[])
oList.callMethod("Add",["one"])
oList.callMethod("Add",["two"])
? "Count = " + oList.getProp("Count")
? oList.toList()

# Errors become Ring errors
try
	dnStatic("System.Int32","Parse",["abc"])
catch
	? "Caught: " + cCatchError
done
