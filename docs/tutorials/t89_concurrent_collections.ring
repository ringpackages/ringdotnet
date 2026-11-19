# collections for many threads - ConcurrentQueue, ConcurrentStack, BlockingCollection and ConcurrentDictionary
load "dotnet.ring"
using {
	"System"
	"System.Collections.Concurrent"
}

func main
	# The collections of System.Collections.Concurrent are safe when several threads use them at the same time: the 'is it
	# there? then change it' steps are done as ONE step. They are generic, so they are made with dnNewGeneric (a type name,
	# the type arguments, the constructor values).
	cInt = "System.Int32"
	cText = "System.String"

	# 1. ConcurrentQueue: first in, first out. TryDequeue answers [ success, item ] (an out parameter comes back as a list).
	oQueue = dnNewGeneric("System.Collections.Concurrent.ConcurrentQueue",[cText],[])
	for cName in ["Ann","Bob","Cy"]
		oQueue.Enqueue(cName)
	next
	? "1. queue of " + oQueue.Count + " names, first = " + oQueue.TryPeek()[2]
	while not oQueue.IsEmpty
		aItem = oQueue.TryDequeue()
		? "   dequeued " + aItem[2]
	end
	? "   an empty queue answers: success = " + oQueue.TryDequeue()[1]

	# 2. ConcurrentStack: last in, first out. This closed generic type has no Ring class, so the objects of dnNewGeneric are
	#    used in the plain style: callMethod(name, [arguments]) and getProp(name).
	oStack = dnNewGeneric("System.Collections.Concurrent.ConcurrentStack",[cInt],[])
	for n = 1 to 3
		oStack.callMethod("Push",[n])
	next
	nFirst = oStack.callMethod("TryPop",[])[2]
	nSecond = oStack.callMethod("TryPop",[])[2]
	? nl + "2. stack: pop gives " + nFirst + " then " + nSecond + ", " + oStack.getProp("Count") + " left"

	# 3. BlockingCollection: a queue for a producer and a consumer. Take waits while the queue is empty; CompleteAdding says
	#    that nothing more will come, and then IsCompleted becomes true when the queue is empty.
	oBlocking = dnNewGeneric("System.Collections.Concurrent.BlockingCollection",[cInt],[])
	for n = 1 to 5
		oBlocking.callMethod("Add",[n * n])
	next
	oBlocking.callMethod("CompleteAdding",[])
	cTaken = ""
	while not oBlocking.getProp("IsCompleted")
		cTaken += "" + oBlocking.callMethod("Take",[]) + " "
	end
	? nl + "3. blocking collection, taken in order: " + cTaken

	# 4. A bounded queue holds at most N items: Add waits when it is full, TryAdd answers at once
	oSmall = dnNewGeneric("System.Collections.Concurrent.BlockingCollection",[cInt],[2])
	? nl + "4. bounded to 2: TryAdd gives " + oSmall.callMethod("TryAdd",[10]) + ", " + oSmall.callMethod("TryAdd",[20]) + ", " + oSmall.callMethod("TryAdd",[30]) + " (the third does not fit)"

	# 5. ConcurrentDictionary: TryAdd, TryUpdate (key, new value, the value we expect) and TryRemove
	oCount = dnNewGeneric("System.Collections.Concurrent.ConcurrentDictionary",[cText,cInt],[])
	for cWord in ["red","green","red","blue","red","green"]
		oCount.callMethod("TryAdd",[cWord,0])          # does nothing when the key exists
		nOld = oCount.callMethod("get_Item",[cWord])
		oCount.callMethod("TryUpdate",[cWord,nOld + 1,nOld])
	next
	? nl + "5. word counts: red = " + oCount.callMethod("get_Item",["red"]) + ", green = " + oCount.callMethod("get_Item",["green"]) + ", blue = " + oCount.callMethod("get_Item",["blue"])
	? "   TryAdd of an existing key: " + oCount.callMethod("TryAdd",["red",99]) + " (the value stays " + oCount.callMethod("get_Item",["red"]) + ")"
	aRemoved = oCount.callMethod("TryRemove",["blue"])
	? "   TryRemove(blue): success = " + aRemoved[1] + ", the removed value was " + aRemoved[2] + ", keys left: " + oCount.getProp("Count")
