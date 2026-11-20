# The release of handles: .NET objects that Ring dropped are released in groups, also the default objects that the class body makes for
# new X(value) and the objects that came back from a method.
load "dotnet.ring"
using {
	"System.Text"
	"System.Collections.Generic"
	"System.Numerics"
}

func main
	nBefore = settle()
	makeObjects(3000)
	nAfter = settle()
	dnAssert("new StringBuilder(value) and new StringList() release their handles",nAfter - nBefore < 40,1)

	oBuilder = new StringBuilder("x")
	nBefore = settle()
	returnObjects(oBuilder,3000)
	nAfter = settle()
	dnAssert("objects that came back from a method release their handles",nAfter - nBefore < 40,1)

	oObject = new Complex().New_([ :real = 3, :imaginary = 4 ])
	dnAssert("a constructor chosen by names works",oObject.Magnitude,5)
	oObject = NULL
	dnTestSummary()

func makeObjects nCount
	for i = 1 to nCount
		oA = new StringBuilder("x")
		oB = new StringList()
		oC = new StringBuilder(NULL)
	next

func returnObjects oBuilder, nCount
	for i = 1 to nCount
		oX = oBuilder.Append("")
	next

# let Ring free what it dropped, send the releases, and count what is left
func settle
	callgc()
	dnFlush()
	return dnHandleCount()
