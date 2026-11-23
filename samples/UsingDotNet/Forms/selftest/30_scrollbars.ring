# the checks of 30_scrollbars.ring: run with  ring 30_scrollbars.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oH.Value = 30
	oV.Value = 20
	dnAssert("both values",oValues.Text,"H = 30, V = 20")
