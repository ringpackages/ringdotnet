# Named arguments: NameWith([ :parameter = value, ... ]) and NewWith([ ... ])
load "../libraries/dotnetlib/dotnetlib.ring"

func main
	using {
		"System"
		"System.Text"
		"System.IO"
		"System.Diagnostics"
		"System.Collections.Generic"
	}
	oMath = new Math()
	dnAssert("Round with names",oMath.RoundWith([ :value = 3.14159, :digits = 2 ]),3.14)
	dnAssert("the order does not matter",oMath.RoundWith([ :digits = 1, :value = 2.74 ]),2.7)
	dnAssert("Max by names",oMath.MaxWith([ :val1 = 3, :val2 = 9 ]),9)

	dnAssert("a constructor by names",dnNewWith("DateTime",[ :year = 2024, :month = 12, :day = 25 ]).DayOfWeek,"Wednesday")
	oSB = dnNewWith("StringBuilder",[ :value = "Hello" ])
	dnAssert("StringBuilder by names",oSB.ToString(),"Hello")
	oSB.AppendWith([ :value = "!" ])
	dnAssert("Append by names",oSB.ToString(),"Hello!")

	oDate = new DateTime(2024,7,4)
	dnAssert("ToString with a format",oDate.ToStringWith([ :format = "yyyy-MM-dd" ]),"2024-07-04")
	dnAssert("optional parameters can be left out",new Path().CombineWith([ :path1 = "a", :path2 = "b" ]),"a" + "\" + "b")

	# a Process started with named arguments
	oInfo = new ProcessStartInfo() {
		FileName = "cmd"
		Arguments = "/c echo named"
		RedirectStandardOutput = True
		UseShellExecute = False
		CreateNoWindow = True
	}
	oProcess = new Process().StartWith([ :startInfo = oInfo ])
	dnAssert("Process.Start by names",substr(oProcess.StandardOutput.ReadToEnd(),"named") > 0,True)
	oProcess.WaitForExit()

	# a wrong name is an error that says what was given
	lFailed = False
	cMessage = ""
	try
		oMath.RoundWith([ :nope = 1 ])
	catch
		lFailed = True
		cMessage = cCatchError
	done
	dnAssert("an unknown parameter is an error",lFailed,True)
	dnAssert("the message names the parameters",substr(cMessage,"nope") > 0,True)

	# a missing required parameter
	lFailed = False
	try
		oMath.RoundWith([ :digits = 2 ])
	catch
		lFailed = True
	done
	dnAssert("a required parameter is missing",lFailed,True)
	dnTestSummary()
