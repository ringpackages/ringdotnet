# the checks of main.ring: run with  ring main.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func typeKeys cKeys
	for nIndex = 1 to len(cKeys)
		press(cKeys[nIndex])
	next

func selfTest
	typeKeys("12+30=")
	dnAssert("12+30",oScreen.Text,"42")
	press("C")
	typeKeys("9/3=")
	dnAssert("9/3",oScreen.Text,"3")
	press("C")
	typeKeys("0.1+0.2=")
	dnAssert("floating point",oScreen.Text,"0.30000000000000004")
	press("C")
	typeKeys("81")
	press("√")
	dnAssert("square root",oScreen.Text,"9")
	press("C")
	typeKeys("5/0=")
	dnAssert("division by zero",oScreen.Text,"Cannot divide by zero")
	press("C")
	# the buttons of the window work
	oKeys = wpfFind(oWindow,"keys")
	dnAssert("20 buttons",oKeys.Children.Count,20)
	oEvent = dnNew("RoutedEventArgs",[ :routedEvent = new WpfButtonBase().ClickEvent ])
	oSeven = oKeys.Children.Item(4)
	dnAssert("the 5th key is a 7",oKeys.Children.Item(4).Content,"7")
	oSeven.RaiseEvent(oEvent)
	oSeven.RaiseEvent(oEvent)
	dnAssert("two clicks on 7",oScreen.Text,"77")
	dnAssert("history",oHistory.Text,"")
