# the checks of 18_timer_clock.ring: run with  ring 18_timer_clock.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("time format",len(oClock.Text),8)
	dnAssert("colons",substr(oClock.Text,":") > 0,1)
