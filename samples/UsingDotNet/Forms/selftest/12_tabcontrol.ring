# the checks of 12_tabcontrol.ring: run with  ring 12_tabcontrol.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oTabs.SelectedIndex = 2
	dnAssert("title follows the tab",oForm.Text,"Tabs - About")
	dnAssert("three tabs",oTabs.TabCount,3)
