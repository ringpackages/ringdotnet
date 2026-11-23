# The forms of "new": without parentheses, with empty parentheses, with arguments (the class body makes the default .NET object)
load "dotnet.ring"

func main

	using {
		"System"
		"System.Text"
		"System.IO"
		"System.Diagnostics"
	}
	# a class without constructor arguments: both forms work
	oStream = new MemoryStream
	oStream.WriteByte(65)
	dnAssert("new MemoryStream (no parentheses)",oStream.Length,1)
	oStream2 = new MemoryStream()
	oStream2.WriteByte(66)
	dnAssert("new MemoryStream() (empty parentheses)",oStream2.Length,1)
	oWatch = new Stopwatch
	oWatch.Start()
	dnAssert("new Stopwatch (no parentheses)",oWatch.IsRunning,True)
	oList = new StringList
	oList.Add("x")
	dnAssert("new StringList (no parentheses)",oList.Count,1)

	# a class whose first argument is optional (init takes one parameter): no parentheses = the default constructor
	oText = new StringBuilder
	oText.Append("plain")
	dnAssert("new StringBuilder (no parentheses)",oText.ToString(),"plain")
	oText2 = new StringBuilder("with text")
	dnAssert("new StringBuilder(text)",oText2.ToString(),"with text")
	oText3 = new StringBuilder("")
	oText3.Append("empty text")
	dnAssert("new StringBuilder(empty text) is still the default constructor",oText3.ToString(),"empty text")
	oText4 = new StringBuilder(NULL)
	oText4.Append("NULL")
	dnAssert("new StringBuilder(NULL)",oText4.ToString(),"NULL")
	dnAssert("new StringBuilder(capacity)",new StringBuilder(64).Capacity,64)
	oRandom = new Random
	dnAssert("new Random (no parentheses)",oRandom.@Next([ :minValue = 5, :maxValue = 6 ]),5)
	dnAssert("new Version(text)",new Version("1.2.3").Major,1)

	# objects that come back from .NET are wrapped as before (the class body must not make a second object)
	oChain = new StringBuilder
	dnAssert("a returned object is wrapped",oChain.Append("x").Append("y").ToString(),"xy")
	dnTestSummary()
