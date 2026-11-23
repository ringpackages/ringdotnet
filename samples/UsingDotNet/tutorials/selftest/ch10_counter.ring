# the checks of ch10_counter.ring: run with  ring ch10_counter.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

# The same program tests itself when it is started with --selftest
func selfTest

	oForm.Controls.Item(1).PerformClick()
	oForm.Controls.Item(1).PerformClick()
	oForm.Controls.Item(1).PerformClick()
	dnAssert("three clicks",oLabel.Text,"Clicked 3 times")
	oForm.Controls.Item(2).PerformClick()
	dnAssert("reset",oLabel.Text,"The button was not clicked yet")
