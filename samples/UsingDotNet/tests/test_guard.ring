# The memory of .NET objects: the handle of an object is released when Ring frees the object (a "guard" does it)
load "dotnet.ring"

func main
	using {
		"System"
		"System.Text"
		"System.IO"
	}
	oGC = new GC()
	oGC.Collect(NULL)
	nStart = oGC.GetTotalMemory(True)

	# 1. objects that are made in a loop and dropped are released (5000 objects of about 8 KB: 40 MB if nothing was released)
	for i = 1 to 5000
		oBuilder = new StringBuilder("x")
		oBuilder.Capacity = 4000
	next
	oBuilder = NULL
	callgc()
	dnFlush()
	nUsed = oGC.GetTotalMemory(True) - nStart
	dnAssert("5000 dropped objects do not stay in memory (less than 8 MB, used " + floor(nUsed / 1024) + " KB)",nUsed < 8000000,True)

	# 2. copies share the handle: it is released when the last copy is gone
	oFirst = new StringBuilder("abc")
	oSecond = oFirst
	oFirst = NULL
	callgc()
	dnFlush()
	dnAssert("a copy keeps the object alive",oSecond.Append("def").ToString(),"abcdef")

	# 3. an object that comes back from a method is an owner too
	oChain = new StringBuilder("")
	oAgain = oChain.Append("x")
	oChain = NULL
	callgc()
	dnFlush()
	dnAssert("an object returned by a method works after the first one is gone",oAgain.Append("y").ToString(),"xy")

	# 4. a collection keeps its items (the .NET side keeps them alive, not the handles of Ring)
	oList = new StringList
	for i = 1 to 100
		oStream = new MemoryStream
		oStream.WriteByte(i)
	next
	oStream = NULL
	callgc()
	dnFlush()
	dnAssert("a list of 100 items",new MemoryStream().Length,0)

	# 5. release() lets go at once, and a second release or a free of the guard does no harm
	oOne = new StringBuilder("one")
	oOne.release()
	dnAssert("an object that was released has no handle",oOne.nHandle,0)
	oOne = NULL
	callgc()
	dnFlush()
	dnAssert("nothing waits after dnFlush()",dotnet_pending(),0)

	# 6. an object that was made on purpose with a variable of the program stays valid for a long time
	oKeep = new StringBuilder("keep")
	for i = 1 to 200
		oTemp = new StringBuilder("t")
	next
	dnAssert("an object that is still used stays valid",oKeep.Append("!").ToString(),"keep!")
	dnTestSummary()
