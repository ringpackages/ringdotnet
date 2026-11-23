# using { "Namespace" ... } imports namespaces like dnImport
load "dotnet.ring"

func main

	using {
		"System"
		"System.Text"
		"System.IO"
	}
	dnAssert("StringBuilder from using",new StringBuilder("Hi").Append("!").ToString(),"Hi!")
	dnAssert("Path from using",new Path().GetFileName("a/b/c.txt"),"c.txt")

	using { "System.Collections.Generic" "System.Linq" }
	dnAssert("several on a line",new StringList().Count,0)

	# importing twice is fine
	using { "System" }

	lFailed = false
	try
		using { 42 }
	catch
		lFailed = true
		cMessage = cCatchError
	done
	dnAssert("a number is an error",lFailed,1)
	dnAssert("the message says what is expected",substr(cMessage,"namespace names") > 0,1)

	lFailed = false
	try
		using { "No.Such.Namespace" }
	catch
		lFailed = true
	done
	dnAssert("an unknown namespace is an error",lFailed,1)
	dnTestSummary()
