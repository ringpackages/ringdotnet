# Nito.AsyncEx: asynchronous coordination types; the tasks they return are waited for from Ring, the generic queue is made with its type argument
load "pkg.ring"
pkgUse("nitoasyncex",[["Nito.AsyncEx","5.1.2"]],[["Nito.AsyncEx.Coordination.dll",["Nito.AsyncEx"]],["Nito.AsyncEx.Tasks.dll",[]],["Nito.AsyncEx.Context.dll",[]],["Nito.AsyncEx.Interop.WaitHandles.dll",[]],["Nito.AsyncEx.Oop.dll",[]],["Nito.Cancellation.dll",[]],["Nito.Collections.Deque.dll",["Nito.Collections"]],["Nito.Disposables.dll",["Nito.Disposables"]]])
pkgImport("nitoasyncex","Nito.AsyncEx.Coordination.dll","Nito.AsyncEx")
pkgImport("nitoasyncex","Nito.Collections.Deque.dll","Nito.Collections")

oLock = new AsyncLock()
oHold = oLock.Lock(NULL)
dnAssert("a lock is taken",oHold.typeName() != "",1)
oHold.Dispose()

# the lock is taken again after it was released
oAgain = oLock.Lock(NULL)
dnAssert("the lock was taken again after it was released",oAgain.typeName() != "",1)
oAgain.Dispose()

# a double ended queue of numbers (the generic type is made with its type argument)
oDeque = dnNew("Nito.Collections.Deque`1[[System.Int32]]",[])
oDeque.AddToBack(2)
oDeque.AddToBack(3)
oDeque.AddToFront(1)
dnAssert("the count of the deque",oDeque.Count,3)
dnAssert("the first item",oDeque.Item(0),1)
dnAssert("the last item",oDeque.Item(2),3)
dnAssert("an item is removed from the front",oDeque.RemoveFromFront(),1)
dnAssert("an item is removed from the back",oDeque.RemoveFromBack(),3)
dnAssert("one item is left",oDeque.Count,1)
oDeque.Insert(0,9)
dnAssert("an item inserted at a place",oDeque.Item(0),9)
dnAssert("the items as a Ring list",oDeque.toList()[2],2)

# the producer and consumer queue: the consumer waits for a task, the producer adds items
oQueue = dnNew("Nito.AsyncEx.AsyncProducerConsumerQueue`1[[System.Int32]]",[])
oQueue.Enqueue(10)
oQueue.Enqueue(20)
oTask = oQueue.DequeueAsync(NULL)
dnAssert("the first item that was added comes out first",oTask.Result,10)
dnAssert("the second",oQueue.DequeueAsync(NULL).Result,20)
oEmpty = oQueue.DequeueAsync(NULL)
dnAssert("a task for an empty queue is not done",oEmpty.IsCompleted,0)
oQueue.Enqueue(30)
dnAssert("it completes when an item arrives",oEmpty.Result,30)

# an event that waits for a count
oCountdown = dnNew("Nito.AsyncEx.AsyncCountdownEvent",[2])
dnAssert("the count of the event",oCountdown.CurrentCount,2)
oWait = oCountdown.WaitAsync(NULL)
dnAssert("the wait is not done while the count is above zero",oWait.IsCompleted,0)
oCountdown.Signal(NULL)
oCountdown.Signal(NULL)
dnAssert("the wait is done when the count is zero",oWait.IsCompleted,1)
dnTestSummary()
