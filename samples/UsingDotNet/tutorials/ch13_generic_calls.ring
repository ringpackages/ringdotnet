# the generic functions - dnType, dnNew, dnStatic, dnNewGeneric, callMethod, getProp, dnNull and dnBuffer: what to use when there is no class
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Collections"
}

func main

	# The tutorials so far wrote OBJECT code: new makes an object, the dot calls a method or reads a property, and braces set properties.
	# That works for every class that was generated, and nearly everything is. A few cases have no class, and for them there are
	# generic functions. They do the same work with the names as texts.

	# 1. A closed generic type with no generated class. LinkedList<string> is not one of the ready classes (StringList and the others are),
	#    so dnNewGeneric makes the object, and the object is a plain DotNetObject: callMethod calls a method and getProp reads a property.
	oLinked = dnNewGeneric("System.Collections.Generic.LinkedList",["System.String"],[])
	oLinked.callMethod("AddLast",["b"])
	oLinked.callMethod("AddLast",["c"])
	oLinked.callMethod("AddFirst",["a"])
	? "1. a LinkedList<string> has " + oLinked.getProp("Count") + " items, the first is " + oLinked.getProp("First").getProp("Value")
	? "   as a Ring list: " + joinList(oLinked.toList())

	# 2. A type that is not wrapped by a class: dnType gives the type, and callMethod calls its static methods (here the class has a
	#    class, so the two ways give the same answer)
	oMath = dnType("System.Math")
	? nl + "2. dnType(...).callMethod: " + oMath.callMethod("Max",[3,9]) + "   the same with a class: " + new Math().Max(3,9)
	? "   a static property: " + oMath.getProp("PI")

	# 3. A constructor with named values. A class that has no constructor without values (FileStream is one) is made without parentheses (new FileStream)
	#    and @New chooses the constructor by the NAMES of its parameters; dnNew("Class",[ :name = value ]) does the same in one call.
	cFile = new Path().Combine([ new Path().GetTempPath(), "ringdotnet-generic.txt" ])
	new File().WriteAllText([ :path = cFile, :contents = "Hello, generic calls" ])
	oStream = dnNew("FileStream",[ :path = cFile, :mode = "Open", :access = "Read" ])
	? nl + "3. a FileStream made by names: " + oStream.Length + " bytes, can read: " + oStream.CanRead
	oStream.Dispose()
	new File().Delete(cFile)

	# 4. A static method of a class that needs values to make an object, or whose name is also a method of every object: dnStatic gives
	#    the static method directly. Convert.ToString(255, 16) is the text of a number in base 16 (ToString is a method of every object).
	? nl + "4. dnStatic: " + dnStatic("System.Convert","ToString",[ 255, 16 ]) + " (255 in base 16), " + dnStatic("System.Convert","ToString",[ 255, 2 ]) + " (in base 2)"

	# 5. dnNull is the .NET null, for a method that expects null: here an ArrayList gets a null item
	oList = new ArrayList()
	oList.Add("text")
	oList.Add(dnNull())
	? nl + "5. an ArrayList with a null item has " + oList.Count + " items; the second is null: " + oList.Item(1).isNull()

	# 6. dnBuffer is a byte[] that .NET can fill (see the tutorial about binary files): the generic function for a type that Ring cannot
	#    make by itself
	oBuffer = dnBuffer(8)
	? nl + "6. a buffer of " + dnBufferSize(oBuffer) + " bytes"

	# 7. When to use what: first an object (new, dot, braces). If a class has no constructor without values, dnNew with names. If a name
	#    is a Ring word or also a method of every object, dnStatic or callMethod. If there is no class, dnNewGeneric, callMethod, getProp.
	? nl + "7. the same call in two styles: " + new Math().Max(3,9) + " and " + dnStatic("System.Math","Max",[3,9])

func joinList aList

	cText = ""
	for item in aList
		if cText != ""
			cText += ", "
		ok
		cText += "" + item
	next
	return cText
