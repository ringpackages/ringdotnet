# the checks of 09_progressbar_timer.ring: run with  ring 09_progressbar_timer.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oTimer.Stop()
	for x = 1 to 10
		advance()
	next
	dnAssert("finished",oText.Text,"Done")
	dnAssert("full bar",oBar.Value,100)
