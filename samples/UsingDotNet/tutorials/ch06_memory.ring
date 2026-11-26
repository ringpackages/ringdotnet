# memory and the garbage collector - how much memory .NET uses, GC.Collect, WeakReference, generations and a big array
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Text"
}

func main

	oGC = new GC()

	# 1. .NET frees the memory of objects that nothing uses any more: the garbage collector (GC). The numbers depend on the computer and
	#    the moment, so the program prints only what is always true.
	nBefore = oGC.GetTotalMemory(True)
	? "1. the program uses memory: " + (nBefore > 0)
	? "   the number of generations: " + (oGC.MaxGeneration + 1) + "   (0 = new objects, 1 = in between, 2 = old objects)"

	# 2. A list with the capacity of 10 million bytes takes about 10 MB at once. GetTotalMemory(True) collects first and then answers.
	#    release() lets the bridge forget its handle, so nothing keeps the list alive.
	oBig = new List([ :typeArguments = ["System.Byte"], :capacity = 10000000 ])
	nWith = oGC.GetTotalMemory(True)
	? nl + "2. a list with room for 10 million bytes grew the memory by at least 9 MB: " + (nWith - nBefore > 9000000)
	oBig = NULL                     # nothing in Ring uses the list now: Ring frees it, and its handle is released with the next .NET calls
	callgc()                        # ... or at once: Ring collects its garbage (callgc) and the waiting handles are released (dnFlush)
	dnFlush()
	nAfter = oGC.GetTotalMemory(True)
	? "   after the list is dropped and a collection the memory is smaller again: " + (nAfter < nWith - 9000000)

	# 3. Collections are counted: CollectionCount(generation) says how many times the GC ran for that generation
	nCount = oGC.CollectionCount(0)
	oGC.Collect(NULL)
	? nl + "3. GC.Collect() ran a collection: " + (oGC.CollectionCount(0) > nCount)

	# 4. A WeakReference points to an object WITHOUT keeping it alive. It is the tool for a cache: keep it while somebody uses
	#    it, let it go when the memory is needed. IsAlive says whether the object is still there.
	oObject = new MemoryStream()
	oWeak = new WeakReference(oObject)
	? nl + "4. the weak reference is alive while we hold the object: " + oWeak.IsAlive
	oObject = NULL                  # the bridge keeps a handle to the object until Ring frees it: that is now
	callgc()
	dnFlush()
	oGC.Collect(NULL)
	oGC.WaitForPendingFinalizers()
	oGC.Collect(NULL)
	? "   after dropping it and a collection: alive = " + oWeak.IsAlive

	# 5. Which generation is an object in? A new object is in generation 0; after it survives a collection it moves up
	oNew = new StringBuilder("x")
	nGen0 = oGC.GetGeneration(oNew)
	oGC.Collect(NULL)
	nGen1 = oGC.GetGeneration(oNew)
	? nl + "5. generation of a new object: " + nGen0 + ", after one collection: " + nGen1 + " (it survived, so it moved up)"
