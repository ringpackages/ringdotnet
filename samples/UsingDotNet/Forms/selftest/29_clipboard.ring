# the checks of 29_clipboard.ring: run with  ring 29_clipboard.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oForm.Controls.Item(1).PerformClick()
	oForm.Controls.Item(2).PerformClick()
	dnAssert("clipboard round trip",oPasted.Text,"Copied from Ring")
