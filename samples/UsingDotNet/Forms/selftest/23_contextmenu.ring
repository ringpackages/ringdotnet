# the checks of 23_contextmenu.ring: run with  ring 23_contextmenu.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oMenu.Items.Item(2).PerformClick()
	dnAssert("panel is blue",oPanel.BackColor.Name,"Blue")
