# the checks of 06_xaml_window.ring: run with  ring 06_xaml_window.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("title from XAML",oWindow.Title,"From XAML")
	oEvent = dnNew("RoutedEventArgs",[ :routedEvent = new WpfButtonBase().ClickEvent ])
	oPress.RaiseEvent(oEvent)
	dnAssert("event handler",oMessage.Text,"The XAML button was pressed")
