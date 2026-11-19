# the checks of 17_keyboard_events.ring: run with  ring 17_keyboard_events.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	keyDown("Enter")
	keyPress("R")
	keyPress("i")
	dnAssert("key name",oLast.Text,"KeyDown: Enter")
	dnAssert("typed characters",oChars.Text,"Ri")
