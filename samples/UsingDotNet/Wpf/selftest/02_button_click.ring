# the checks of 02_button_click.ring: run with  ring 02_button_click.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oEvent = (new RoutedEventArgs).@New([ :routedEvent = new WpfButtonBase().ClickEvent ])
	oButton.RaiseEvent(oEvent)
	oButton.RaiseEvent(oEvent)
	dnAssert("two clicks",oInfo.Content,"2 clicks")
