# the checks of 04_checkbox_radio.ring: run with  ring 04_checkbox_radio.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oCheck.IsChecked = True
	oCheck.IsChecked = False
	dnAssert("events",cLog,"on off ")
	aRadios[2].IsChecked = True
	aRadios[3].IsChecked = True
	dnAssert("exclusive",aRadios[2].IsChecked,0)
	dnAssert("selected",aRadios[3].IsChecked,1)
