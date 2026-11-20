# The overload that the bridge chooses for a kind of arguments is remembered (Math.Max has 14 overloads). The same call with other
# kinds of arguments must still choose its own overload, and a text must still be read as an enum name where an enum is possible.
load "dotnet.ring"
using {
	"System"
	"System.Text"
}

func main
	oMath = new Math()
	for nRound = 1 to 2          # the second round uses the remembered choices
		dnAssert("whole numbers",oMath.Max(1,2),2)
		dnAssert("a fraction",oMath.Max(1.5,2),2)
		dnAssert("two fractions",oMath.Max(1.5,2.25),2.25)
		dnAssert("negative numbers",oMath.Max(-5,-7),-5)
		dnAssert("bigger than a byte",oMath.Max(300,2),300)
		dnAssert("bigger than an int",oMath.Max(4000000000,1),4000000000)
		dnAssert("Abs of a negative whole number",oMath.Abs(-5),5)
		dnAssert("Abs of a fraction",oMath.Abs(-2.5),2.5)
	next

	oBuilder = new StringBuilder(NULL)
	for nRound = 1 to 2
		oBuilder.Clear()
		oBuilder.Append("a")          # a text of one letter may be a char
		oBuilder.Append("bc")         # a longer text is a string
		oBuilder.Append(12)
		oBuilder.Append(1.5)
		oBuilder.Append(True)
		dnAssert("Append with kinds of values",oBuilder.ToString(),"abc121.51")
	next

	# a text that names an enum value, then one that does not: the choice depends on the text
	oString = new String()
	for nRound = 1 to 2
		dnAssert("an enum name",oString.Equals([ :a = "ABC", :b = "abc", :comparisonType = "OrdinalIgnoreCase" ]),True)
		dnAssert("an enum name, other value",oString.Equals([ :a = "ABC", :b = "abc", :comparisonType = "Ordinal" ]),False)
	next
	nCaught = 0
	try
		oString.Equals([ :a = "ABC", :b = "abc", :comparisonType = "NotAName" ])
	catch
		nCaught = 1
	done
	dnAssert("a text that is no enum name is an error",nCaught,1)
	dnTestSummary()
