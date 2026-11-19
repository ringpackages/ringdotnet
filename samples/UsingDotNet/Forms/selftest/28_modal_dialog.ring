# the checks of 28_modal_dialog.ring: run with  ring 28_modal_dialog.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("dialog returns the text",askNameDialog("Ring"),"Ring")
