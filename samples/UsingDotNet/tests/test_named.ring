# Named arguments: Name([ :parameter = value, ... ]) and dnNew("Class",[ ... ])
load "dotnet.ring"

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
	dnAssert("ToString keeps ToString() and Format(format)",oDate.Format("yyyy-MM-dd"),"2024-07-04")
	cSep = "/"
	if iswindows()
		cSep = "\"
	ok
	oPath = new Path()
	dnAssert("a params array takes a plain list",oPath.Combine(["a","b","c"]),"a" + cSep + "b" + cSep + "c")
	dnAssert("the same method by parameter names",oPath.Combine([ :path1 = "a", :path2 = "b" ]),"a" + cSep + "b")
	dnAssert("an overloaded name has no numbered methods",isattribute(new Path(),"Combine_3") = 0 and ismethod(oPath,"Combine_3") = 0,True)
	dnAssert("a constructor by names: @New",new StringBuilder("x").@New([ :value = "abc", :capacity = 16 ]).ToString(),"abc")

	# inside braces
	oBuilder = new StringBuilder("a") {
		Append([ :value = "b" ])
		Append([ :value = "c" ])
	}
	dnAssert("named arguments inside braces",oBuilder.ToString(),"abc")

	# a Process started with named arguments
	cShell = "sh"
	cShellArg = "-c"
	if iswindows()
		cShell = "cmd"
		cShellArg = "/c"
	ok
	oInfo = new ProcessStartInfo() {
		FileName = cShell
		Arguments = cShellArg + ' "echo named"'
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


	# constructors: a class whose init() takes one argument also has the parameterless constructor, reached with NULL
	oBuilder = new StringBuilder(NULL)
	oBuilder.Append("ab")
	dnAssert("new StringBuilder(NULL) is the empty builder",oBuilder.ToString(),"ab")
	oText = new StringBuilder("xy")
	dnAssert("new StringBuilder(text) starts with the text",oText.ToString(),"xy")
	oRandom = new Random(NULL)
	dnAssert("new Random(NULL) works",oRandom.@Next(10) < 10,True)
	oFirst = new Random(42)
	oSecond = new Random(42)
	dnAssert("new Random(seed) still works",oFirst.@Next(100) = oSecond.@Next(100),True)
	oZero = new Version(NULL)
	dnAssert("new Version(NULL) is 0.0",oZero.ToString(),"0.0")
	oParsed = new Version("1.2.3")
	dnAssert("new Version(text) parses the text",oParsed.ToString(),"1.2.3")
	# a call without arguments of a name that is a property or a field reads it
	dnAssert("dnStatic of a static property",dnStatic("System.Int32","MaxValue",[]),2147483647)
	dnAssert("dnStatic of a static property, a double",floor(dnStatic("System.Math","PI",[]) * 1000),3141)
	dnAssert("callMethod of a property",dnNew("System.Text.StringBuilder",["abc"]).callMethod("Length",[]),3)
	# a whole number that goes to an object is an Int32 (Ring has one kind of number): formats that need an int work
	dnAssert("String.Format with D3",dnStatic("System.String","Format",["{0:D3}",5]),"005")
	dnAssert("String.Format with a hexadecimal number",dnStatic("System.String","Format",["{0:X}",255]),"FF")
	dnAssert("a number with a fraction stays a double",dnStatic("System.String","Format",["{0:F2}",2.5]),"2.50")
	dnAssert("the items of a list for params object[]",dnStatic("System.String","Format",["{0:D2}-{1:X}",[7,255]]),"07-FF")
	dnAssert("a list for params object[], with a number that has a fraction",dnStatic("System.String","Format",["{0:D2} {1:F1}",[7,2.5]]),"07 2.5")
	dnAssert("a whole number for an object is an Int32",dnStatic("System.Convert","GetTypeCode",[5]),"Int32")
	dnAssert("a number with a fraction for an object is a Double",dnStatic("System.Convert","GetTypeCode",[2.5]),"Double")
	dnAssert("dnBox makes an exact Double for an object",dnStatic("System.Convert","GetTypeCode",[dnBox("System.Double",5)]),"Double")
	dnAssert("dnBox makes an exact Int64 for an object",dnStatic("System.Convert","GetTypeCode",[dnBox("System.Int64",5)]),"Int64")
	dnAssert("an exact value is the one that String.Format gets",dnStatic("System.String","Format",["{0:F1}",dnBox("System.Double",5)]),"5.0")
	dnAssert("a number beyond Int32 for an object is a Double",dnStatic("System.Convert","GetTypeCode",[3000000000]),"Double")

	dnTestSummary()
