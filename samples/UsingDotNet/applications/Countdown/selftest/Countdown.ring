# the checks of Countdown.ring: run with  ring Countdown.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func waitMs nMilliseconds

	oClock = new Stopwatch()
	oClock.Start()
	while oClock.ElapsedMilliseconds < nMilliseconds
		new Application().DoEvents()
		new Thread().Sleep(5)
	end

func selfTest

	oMinutes.Value = 0
	oSeconds.Value = 3
	resetTimer()
	dnAssert("display",oDisplay.Text,"00:03")
	tick()
	dnAssert("one second passed",oDisplay.Text,"00:02")
	dnAssert("progress",oBar.Value,33)
	tick()
	tick()
	dnAssert("finished",oDisplay.Text,"00:00")
	dnAssert("full bar",oBar.Value,100)
	dnAssert("stopped",lRunning,0)
	# the real timer ticks once a second
	oSeconds.Value = 5
	resetTimer()
	oStart.PerformClick()
	dnAssert("button says Pause",oStart.Text,"Pause")
	waitMs(2200)
	oStart.PerformClick()
	dnAssert("two ticks happened",nLeft <= 3 and nLeft >= 2,True)
	resetTimer()
	dnAssert("reset",oDisplay.Text,"00:05")
