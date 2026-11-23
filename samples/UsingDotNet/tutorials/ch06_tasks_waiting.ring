# tasks that wait - Task.Delay, WhenAll, WhenAny, time limits and cancellation (System.Threading.Tasks)
load "dotnet.ring"

using {
	"System"
	"System.Diagnostics"
	"System.Threading"
	"System.Threading.Tasks"
}

func main

	oTasks = new Task()

	# 1. A Task is "something that finishes later". Task.Delay(ms) is a task that finishes after that time, without using a thread to sleep.
	oWatch = new Stopwatch()
	oWatch.Start()
	oOne = oTasks.Delay(300)
	? "1. the task was made at once (under 100 ms): " + yesNo(oWatch.ElapsedMilliseconds < 100) + ", finished already? " + yesNo(oOne.IsCompleted)
	oOne.Wait(NULL)
	? "   after Wait it is finished (" + oOne.Status + ") and about 300 ms have passed: " + yesNo(oWatch.ElapsedMilliseconds >= 280)

	# 2. WhenAll: one task that finishes when ALL of them did. Three waits of 300 ms together take about 300 ms, not 900.
	oWatch.Restart()
	oAll = oTasks.WhenAll([oTasks.Delay(300),oTasks.Delay(300),oTasks.Delay(300)])
	oAll.Wait(NULL)
	nAll = oWatch.ElapsedMilliseconds
	? nl + "2. three waits of 300 ms, started together, took less than 700 ms: " + yesNo(nAll < 700) + " (and at least 300: " + yesNo(nAll >= 280) + ")"

	# 3. WhenAny: finishes when the FIRST one does. The task that finished is the result.
	oFast = oTasks.Delay(100)
	oSlow = oTasks.Delay(1000)
	oFirst = oTasks.WhenAny([oSlow,oFast])
	oFirst.Wait(NULL)
	? nl + "3. WhenAny finished when the fast task did: fast is done " + yesNo(oFast.IsCompleted) + ", slow is done " + yesNo(oSlow.IsCompleted)

	# 4. A time limit: Wait(ms) gives up after that time and answers false when the task is not finished
	oLong = oTasks.Delay(2000)
	lDone = oLong.Wait(200)
	? nl + "4. waited 200 ms for a task of 2 seconds: finished = " + yesNo(lDone) + " (the task keeps running; you stopped waiting)"

	# 5. Cancellation: a CancellationTokenSource says "stop". CancelAfter(ms) says it later. A task that got the token ends as canceled.
	oSource = new CancellationTokenSource()
	oSource.CancelAfter(100)
	oCancellable = oTasks.Delay([ :millisecondsDelay = 5000, :cancellationToken = oSource.Token ])
	lError = False
	try
		oCancellable.Wait(NULL)
	catch
		lError = True
	done
	? nl + "5. a delay of 5 seconds canceled after 100 ms: the wait raised an error " + yesNo(lError) + ", the task is canceled: " + yesNo(oCancellable.IsCanceled) + ", status " + oCancellable.Status
	oSource.Dispose()

	# 6. Many waits, one result: wait for all pages of a list (here: delays standing for downloads) and see that they ran together
	aDelays = [50,120,80,200,30]
	aList = []
	for nDelay in aDelays
		aList + oTasks.Delay(nDelay)
	next
	oWatch.Restart()
	oTasks.WhenAll(aList).Wait(NULL)
	nTotal = 0
	for nDelay in aDelays
		nTotal += nDelay
	next
	? nl + "6. five waits that add up to " + nTotal + " ms were over in less than that: " + yesNo(oWatch.ElapsedMilliseconds < nTotal)

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"
