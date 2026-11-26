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
	oStack = new ConcurrentStack([ :typeArguments = [cInt] ])
	for n = 1 to 3
		oStack.Push(n)
	next
	nFirst = oStack.TryPop()[2]
	nSecond = oStack.TryPop()[2]
	? nl + "2. stack: pop gives " + nFirst + " then " + nSecond + ", " + oStack.getProp("Count") + " left"

	# 3. BlockingCollection: a queue for a producer and a consumer. Take waits while the queue is empty; CompleteAdding says
	#    that nothing more will come, and then IsCompleted becomes true when the queue is empty.
	oBlocking = new BlockingCollection([ :typeArguments = [cInt] ])
	for n = 1 to 5
		oBlocking.Add(n * n)
	next
	oBlocking.CompleteAdding()
	cTaken = ""
	while not oBlocking.getProp("IsCompleted")
		cTaken += "" + oBlocking.callMethod("Take",[]) + " "
	end
	? nl + "3. blocking collection, taken in order: " + cTaken

	# 4. A bounded queue holds at most N items: Add waits when it is full, TryAdd answers at once
	oSmall = new BlockingCollection([ :typeArguments = [cInt], :boundedCapacity = 2 ])
	? nl + "4. bounded to 2: TryAdd gives " + oSmall.TryAdd(10) + ", " + oSmall.TryAdd(20) + ", " + oSmall.TryAdd(30) + " (the third does not fit)"

	# 5. ConcurrentDictionary: TryAdd, TryUpdate (key, new value, the value we expect) and TryRemove
	oCount = new ConcurrentDictionary([ :typeArguments = [cText,cInt] ])
	for cWord in ["red","green","red","blue","red","green"]
		oCount.TryAdd(cWord,0)          # does nothing when the key exists
		nOld = oCount.Item(cWord)
		oCount.TryUpdate(cWord,nOld + 1,nOld)
	next
	? nl + "5. word counts: red = " + oCount.Item("red") + ", green = " + oCount.Item("green") + ", blue = " + oCount.Item("blue")
	? "   TryAdd of an existing key: " + oCount.TryAdd("red",99) + " (the value stays " + oCount.Item("red") + ")"
	aRemoved = oCount.TryRemove("blue")
	? "   TryRemove(blue): success = " + aRemoved[1] + ", the removed value was " + aRemoved[2] + ", keys left: " + oCount.getProp("Count")
