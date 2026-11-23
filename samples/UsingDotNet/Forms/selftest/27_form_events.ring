# the checks of 27_form_events.ring: run with  ring 27_form_events.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	dnAssert("load event ran first",aLog[1],"Load")
	oForm.Width = 400
	dnAssert("resize event ran",find(aLog,"Resize") > 0,True)
