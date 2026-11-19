# the checks of 16_mouse_events.ring: run with  ring 16_mouse_events.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	moved(12,34)
	dnAssert("move text",oInfo.Text,"x=12 y=34")
	pressed("Right",5,6)
	dnAssert("press text",oInfo.Text,"Right button at 5,6")
