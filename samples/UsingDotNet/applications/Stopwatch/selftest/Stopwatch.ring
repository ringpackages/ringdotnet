# the checks of Stopwatch.ring: run with  ring Stopwatch.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

# let the form process the timer messages for a while
func waitMs nMilliseconds

	oClock = new Stopwatch()
	oClock.Start()
	while oClock.ElapsedMilliseconds < nMilliseconds
		new Application().DoEvents()
		new Thread().Sleep(5)
	end

func selfTest

	dnAssert("format",formatTime(83450),"01:23.45")
	oStart.PerformClick()
	dnAssert("running",oWatch.IsRunning,1)
	dnAssert("button says Stop",oStart.Text,"Stop")
	waitMs(300)
	oLap.PerformClick()
	dnAssert("one lap",oLaps.Items.Count,1)
	dnAssert("time moved",oWatch.ElapsedMilliseconds >= 250,True)
	dnAssert("display updated by the timer",oTime.Text != "00:00.00",1)
	oStart.PerformClick()
	dnAssert("stopped",oWatch.IsRunning,0)
	oReset.PerformClick()
	dnAssert("reset",oTime.Text,"00:00.00")
	dnAssert("laps cleared",oLaps.Items.Count,0)
