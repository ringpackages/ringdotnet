# the checks of 11_menu_status.ring: run with  ring 11_menu_status.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oMenuItem = oForm.MainMenuStrip.Items.Item(0).DropDownItems.Item(1)
	oMenuItem.PerformClick()
	dnAssert("menu click",oMessage.Text,"Open file")
	dnAssert("menu count",oForm.MainMenuStrip.Items.Count,2)
