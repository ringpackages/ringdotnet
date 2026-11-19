# the checks of ch10_controls.ring: run with  ring ch10_controls.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("the label",oLabel.Text,"The button was not clicked yet")
