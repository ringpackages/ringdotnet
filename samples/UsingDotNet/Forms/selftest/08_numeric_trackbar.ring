# the checks of 08_numeric_trackbar.ring: run with  ring 08_numeric_trackbar.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oBar.Value = 40
	dnAssert("number follows",number(oNumber.Value),40)
	oNumber.Value = 75
	dnAssert("bar follows",oBar.Value,75)
