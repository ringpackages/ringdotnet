# the checks of 04_checkbox.ring: run with  ring 04_checkbox.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oCheck.Checked = True
	changed()
	dnAssert("on",oState.Text,"Notifications are on")
	oCheck.Checked = False
	changed()
	dnAssert("off",oState.Text,"Notifications are off")
