# The calls that return a text, a number, a yes/no or nothing are packed and read in C (dotnet_call, dotnet_callv). Everything the C code
# does not finish (an object as an argument, an object or null as the answer, a .NET error) goes the Ring way: the results must be the same.
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Text"
	"System.Collections.Generic"
}

nTotal = 0          # the code of a callback sees only global variables

func main
	oMath = new Math()
	oList = new StringList()

	# numbers: whole, negative, a fraction, big (a double travels as 8 bytes)
	dnAssert("whole",oMath.Max(7,9),9)
	dnAssert("negative",oMath.Max(-7,-9),-7)
	dnAssert("fraction",oMath.Max(1.25,0.5),1.25)
	dnAssert("big whole number",oMath.Max(2000000000000,1),2000000000000)
	dnAssert("an answer with decimals",oMath.Sqrt(2) > 1.41421 and oMath.Sqrt(2) < 1.41422,1)

	# text: binary safe in both directions, and the empty text
	cOdd = "a" + char(0) + "b" + char(255) + char(254) + "z"
	cBase64 = new Convert().ToBase64String(cOdd)
	dnAssert("a text with a NUL and bytes that are not UTF-8",cBase64,"YQBi//56")
	dnAssert("the empty text",new String().IsNullOrEmpty(""),True)
	dnAssert("an answer that is a text",new Path().GetFileName("c:/work/report.txt"),"report.txt")

	# yes/no and nothing
	oList.Add("a")
	oList.Add("b")
	dnAssert("a yes",oList.Contains("a"),True)
	dnAssert("a no",oList.Contains("z"),False)
	dnAssert("a number answer",oList.Count,2)
	oList.Clear()
	dnAssert("a method that returns nothing",oList.Count,0)

	# an object as an argument (the Ring way), with an answer that C reads
	oOther = new StringList()
	oOther.Add("x")
	oOther.Add("y")
	oList.AddRange(oOther)
	dnAssert("an object as an argument of a method that returns nothing",oList.Count,2)
	oBuilder = new StringBuilder("same")
	oSame = oBuilder
	dnAssert("an object as an argument, a yes/no answer",oBuilder.Equals(oSame),True)

	# a list as an argument
	dnAssert("a list as an argument",new String().Join([ :separator = "-", :value = ["a","b"] ]),"a-b")

	# null as an answer: an object that answers isNull()
	oMissing = new Environment().GetEnvironmentVariable("RINGDOTNET_NO_SUCH_VARIABLE_XYZ")
	dnAssert("null as the answer of a method that returns a text",isobject(oMissing) and oMissing.isNull(),1)

	# a property: read, write, and write with a text
	oBuilder = new StringBuilder("abcdef")
	dnAssert("a property that is a number",oBuilder.Length,6)
	oBuilder.Length = 3
	dnAssert("a property written with a number",oBuilder.ToString(),"abc")

	# an error is a Ring error with the .NET message
	cError = ""
	try
		new Int32().Parse("abc")
	catch
		cError = cCatchError
	done
	dnAssert("a .NET error",substr(cError,"FormatException") > 0,1)
	dnAssert("the message starts like the others",substr(cError,"DotNet Error:") > 0,1)
	cError = ""
	try
		new Math().Max("a","b")
	catch
		cError = cCatchError
	done
	dnAssert("no method matches",substr(cError,"MissingMethodException") > 0,1)
	# a static method that the extension reads, called again (the handle of the type is remembered), with an argument that is a list
	# (nothing is sent: dnLate makes the request the Ring way, from the name of the type)
	dnAssert("a static method, again",oMath.Max(3,4),4)
	dnAssert("a static method with an object argument",new String().Concat([ :str0 = new StringBuilder("a").ToString(), :str1 = "b" ]),"ab")
	dnAssert("a static method called with a list",len(new Path().Combine(["a","b"])),3)
	# a callback and a list of texts as arguments (packed in C too)
	oNames = new StringList()
	oNames.Add("ab")
	oNames.Add("cde")
	oNames.ForEach_(dnCallback("nTotal += len(aDotNetArgs[1])"))
	dnAssert("a callback as an argument",nTotal,5)
	oNames.InsertRange(0,["x","y"])
	dnAssert("a list of texts as an argument",oNames.Count,4)
	dnAssert("the first inserted text",oNames.Item(0),"x")

	# an object as the answer: the same class as before, null as an object that answers isNull(), and the object keeps working
	oBuilder2 = new StringBuilder("abc")
	oChained = oBuilder2.Append("d").Append("e")
	dnAssert("an object as the answer (a chained call)",oChained.ToString(),"abcde")
	dnAssert("the object is of its class",oChained.Length,5)
	oNothing = new Environment().GetEnvironmentVariable("RINGDOTNET_NO_SUCH_VARIABLE_XYZ")
	dnAssert("null is an object that answers isNull()",oNothing.isNull(),True)
	dnTestSummary()
