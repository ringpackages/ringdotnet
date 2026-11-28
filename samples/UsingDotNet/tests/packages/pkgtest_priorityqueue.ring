# OptimizedPriorityQueue: a priority queue of text items (the smallest priority comes out first): enqueue, dequeue, first, update, remove, contains
load "pkg.ring"
pkgUse("priorityqueue",[["OptimizedPriorityQueue","5.1.0"]],[["PriorityQueue.dll",["Priority_Queue"]]])
pkgImport("priorityqueue","PriorityQueue.dll","Priority_Queue")

oQueue = dnNewGeneric("Priority_Queue.SimplePriorityQueue",["System.String"],[])
dnAssert("a new queue is empty",oQueue.getProp("Count"),0)
oQueue.callMethod("Enqueue",["write the report",5])
oQueue.callMethod("Enqueue",["fix the build",1])
oQueue.callMethod("Enqueue",["lunch",3])
oQueue.callMethod("Enqueue",["answer the mail",4])
dnAssert("four items",oQueue.getProp("Count"),4)
dnAssert("the first item is the smallest priority",oQueue.getProp("First"),"fix the build")
dnAssert("the priority of an item",oQueue.callMethod("GetPriority",["lunch"]),3)
dnAssert("the queue contains an item",oQueue.callMethod("Contains",["lunch"]),True)
dnAssert("the queue does not contain an item",oQueue.callMethod("Contains",["sleep"]),False)

# the priority of an item is changed: lunch becomes the most important
oQueue.callMethod("UpdatePriority",["lunch",0])
dnAssert("the changed item is first",oQueue.getProp("First"),"lunch")

# items come out in the order of their priorities
aOrder = []
while oQueue.getProp("Count") > 0
	aOrder + oQueue.callMethod("Dequeue",[])
end
dnAssert("the order of the items",list2str(aOrder),"lunch" + nl + "fix the build" + nl + "answer the mail" + nl + "write the report")
dnAssert("an empty queue again",oQueue.getProp("Count"),0)

# remove an item that is waiting
oQueue.callMethod("Enqueue",["a",2])
oQueue.callMethod("Enqueue",["b",1])
oQueue.callMethod("Remove",["b"])
dnAssert("an item is removed",oQueue.callMethod("Contains",["b"]),False)
dnAssert("the other item is left",oQueue.getProp("First"),"a")
lError = 0
try
	oQueue.callMethod("Remove",["zzz"])
catch
	lError = 1
done
dnAssert("an item that is not there is an error",lError,1)

# an item that is there is not added twice by the method that checks
dnAssert("a new item is added",oQueue.callMethod("EnqueueWithoutDuplicates",["c",7]),True)
dnAssert("an item that is there is not added",oQueue.callMethod("EnqueueWithoutDuplicates",["a",9]),False)
dnAssert("the count has no repeat",oQueue.getProp("Count"),2)

# an empty queue
oEmpty = dnNewGeneric("Priority_Queue.SimplePriorityQueue",["System.String"],[])
lError = 0
try
	oEmpty.callMethod("Dequeue",[])
catch
	lError = 1
done
dnAssert("dequeue of an empty queue is an error",lError,1)

dnTestSummary()
