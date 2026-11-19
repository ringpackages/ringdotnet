# the checks of ch11_wpf_layout.ring: run with  ring ch11_wpf_layout.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	clickKey("key4")
	clickKey("key2")
	dnAssert("two digits",oDisplay.Text,"42")
	clickKey("back")
	dnAssert("backspace",oDisplay.Text,"4")
	clickKey("clear")
	dnAssert("clear shows zero",oDisplay.Text,"0")
	clickKey("key0")
	clickKey("key7")
	dnAssert("zero then seven",oDisplay.Text,"07")
	# the style was applied to all buttons: the keys have the margin of the Style
	dnAssert("the style: Margin of a key",wpfFind(oWindow,"key5").Margin.Left,4)

func clickKey cName
	wpfFind(oWindow,cName).RaiseEvent(new RoutedEventArgs().New_([ :routedEvent = new WpfButtonBase().ClickEvent ]))
