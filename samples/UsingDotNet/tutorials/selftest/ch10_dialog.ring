# the checks of ch10_dialog.ring: run with  ring ch10_dialog.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	cNextName = "Bob"
	nStep = 0
	editProfile()
	dnAssert("the answer was used",cName,"Bob")
	dnAssert("the age was used",nAge,44)
	dnAssert("shown in the window",oShow.Text,"Bob" + nl + "44 years old")
