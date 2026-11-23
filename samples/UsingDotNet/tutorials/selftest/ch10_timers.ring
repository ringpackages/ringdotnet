# the checks of ch10_timers.ring: run with  ring ch10_timers.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oClock.Stop()
	toggleWatch()                                   # start
	new Thread().Sleep(150)
	toggleWatch()                                   # stop
	showTime()
	dnAssert("the stopwatch measured time",oWatch.ElapsedMilliseconds >= 100,True)
	resetWatch()
	dnAssert("reset",oTime.Text,"0:00.0")
	startJob()
	for nStep = 1 to 20
		jobStep()
	next
	dnAssert("the job finished",oInfo.Text,"Finished")
	dnAssert("the bar is full",oBar.Value,100)
