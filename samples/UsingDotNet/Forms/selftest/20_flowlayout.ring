# the checks of 20_flowlayout.ring: run with  ring 20_flowlayout.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("12 buttons",oFlow.Controls.Count,12)
