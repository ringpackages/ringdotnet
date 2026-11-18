# Named arguments: Name([ :parameter = value, ... ]) and dnNew("Class",[ ... ])
load "dotnetlib.ring"

func main
	using {
		"System"
		"System.Text"
		"System.IO"
		"System.Diagnostics"
		"System.Collections.Generic"
	}
	oMath = new Math()
	dnAssert("Round with names",oMath.Round([ :value = 3.14159, :digits = 2 ]),3.14)
	dnAssert("the order does not matter",oMath.Round([ :digits = 1, :value = 2.74 ]),2.7)
	dnAssert("Max keeps its positional form (all overloads have 2 parameters)",oMath.Max(3,9),9)

	dnAssert("a constructor by names",dnNew("DateTime",[ :year = 2024, :month = 12, :day = 25 ]).DayOfWeek,"Wednesday")
	oSB = dnNew("StringBuilder",[ :value = "Hello" ])
	dnAssert("StringBuilder by names",oSB.ToString(),"Hello")
	oSB.Append([ :value = "!" ])
	dnAssert("Append by names",oSB.ToString(),"Hello!")

	oDate = new DateTime(2024,7,4)
	dnAssert("ToString keeps ToString() and ToString_1(format)",oDate.ToString_1("yyyy-MM-dd"),"2024-07-04")
	dnAssert("a method whose plain form takes 2 parameters keeps its positional form",new Path().Combine("a","b"),"a" + "\" + "b")

	# inside braces
	oBuilder = new StringBuilder("a") {
		Append([ :value = "b" ])
		Append([ :value = "c" ])
	}
	dnAssert("named arguments inside braces",oBuilder.ToString(),"abc")

	# a Process started with named arguments
	oInfo = new ProcessStartInfo() {
		FileName = "cmd"
		Arguments = "/c echo named"
		RedirectStandardOutput = True
		UseShellExecute = False
		CreateNoWindow = True
	}
	oProcess = new Process().Start([ :startInfo = oInfo ])
	dnAssert("Process.Start by names",substr(oProcess.StandardOutput.ReadToEnd(),"named") > 0,True)
	oProcess.WaitForExit(NULL)

	# a wrong name is an error that says what was given
	lFailed = False
	cMessage = ""
	try
		oMath.Round([ :nope = 1 ])
	catch
		lFailed = True
		cMessage = cCatchError
	done
	dnAssert("an unknown parameter is an error",lFailed,True)
	dnAssert("the message names the parameters",substr(cMessage,"nope") > 0,True)

	# a missing required parameter
	lFailed = False
	try
		oMath.Round([ :digits = 2 ])
	catch
		lFailed = True
	done
	dnAssert("a required parameter is missing",lFailed,True)
	dnTestSummary()
