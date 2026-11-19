# the checks of ch10_tray.ring: run with  ring ch10_tray.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("the icon is visible",oTray.Visible,True)
	dnAssert("the tip",oTray.Text,"Tray demo (double-click to open)")
	dnAssert("two menu items",oMenu.Items.Count,2)
	dnAssert("the first menu item",oMenu.Items.Item(0).Text,"Open")

	# hide: the window is not visible, the icon still is
	hideToTray()
	dnAssert("the window is hidden",oForm.Visible,False)
	dnAssert("the icon stays",oTray.Visible,True)

	# the double click (or the menu item Open) brings it back
	showFromTray()
	dnAssert("the window is back",oForm.Visible,True)
	dnAssert("the status",oStatus.Text,"Back from the tray 1 time(s)")

	# the menu item runs the same function
	oMenu.Items.Item(0).PerformClick()
	dnAssert("the menu item Open",nShown,2)
