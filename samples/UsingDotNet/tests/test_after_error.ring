# After an error that was caught, the next call on a .NET object still reaches that object.
# (A call is made with "new DotNetObject(...)" of the handle of the object; the arguments of new are read together with the new object, so
# the plain name nHandle could be looked up in the wrong object after a caught error, and the call arrived at a null object. The generated
# classes write this.nHandle.)
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Text"
}

func main

	oStream = new MemoryStream()
	oBuilder = new StringBuilder("x")

	# 1. the error is raised by a call of another object, caught by a try with only an assignment in catch, and the very next statement
	#    calls a method of an object that was made before the try
	nCaught = 0
	try
		new Int32().Parse("not a number")
	catch
		nCaught = 1
	done
	oBuilder.Append("y")
	dnAssert("the error was caught",nCaught,1)
	dnAssert("the next call works",oBuilder.ToString(),"xy")

	# 2. the same with an error from a method of a generated class, then Dispose of an object made before
	nCaught = 0
	try
		oStream.Seek([ :offset = -5, :origin = "Begin" ])
	catch
		nCaught = 1
	done
	oStream.Dispose()
	dnAssert("the second error was caught",nCaught,1)
	dnAssert("Dispose reached the stream",oStream.CanRead,False)

	# 3. in a function, as a program would write it
	dnAssert("a function with try and catch",afterCatch(),"disposed")
	dnTestSummary()

func afterCatch

	oClient = new MemoryStream()
	try
		new Int32().Parse("abc")
	catch
		nX = 1
	done
	oClient.Dispose()
	return "disposed"
