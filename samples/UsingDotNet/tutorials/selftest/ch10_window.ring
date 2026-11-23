# the checks of ch10_window.ring: run with  ring ch10_window.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	dnAssert("the title",oForm.Text,"My first window")
