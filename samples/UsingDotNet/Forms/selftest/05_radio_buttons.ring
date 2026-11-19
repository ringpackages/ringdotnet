# the checks of 05_radio_buttons.ring: run with  ring 05_radio_buttons.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	aRadios[3].Checked = True
	show()
	dnAssert("large",oChoice.Text,"You chose Large")
	dnAssert("only one radio is checked",aRadios[2].Checked + aRadios[3].Checked + aRadios[1].Checked,True)
