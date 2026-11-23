# the checks of 02_button_click.ring: run with  ring 02_button_click.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oForm.Controls.Item(1).PerformClick()
	oForm.Controls.Item(1).PerformClick()
	oForm.Controls.Item(1).PerformClick()
	dnAssert("three clicks",oCount.Text,"3 clicks")
