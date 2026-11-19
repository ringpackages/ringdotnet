# the checks of 22_toolbar.ring: run with  ring 22_toolbar.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oBar.Items.Item(1).PerformClick()
	dnAssert("toolbar click",oStatus.Text,"Clicked Open")
