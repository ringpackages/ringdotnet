# the checks of 09_menu_tabs.ring: run with  ring 09_menu_tabs.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oEvent = (new RoutedEventArgs).@New([ :routedEvent = new MenuItem().ClickEvent ])
	oOpen.RaiseEvent(oEvent)
	dnAssert("menu item click",cLast,"open")
	oTabs.SelectedIndex = 1
	dnAssert("second tab selected",oTabs.SelectedIndex,1)
	dnAssert("tabs",oTabs.Items.Count,2)
