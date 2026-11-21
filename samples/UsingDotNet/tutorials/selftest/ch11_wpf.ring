# the checks of ch11_wpf.ring: run with  ring ch11_wpf.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	wpfFind(oWindow,"greet").RaiseEvent(new RoutedEventArgs().@New([ :routedEvent = new WpfButtonBase().ClickEvent ]))
	dnAssert("greeting",oGreet.Text,"Hello, Ring!")
	oSlider.Value = 100
	dnAssert("binding",oValue.Text,"100")
	dnAssert("the circle follows the slider",oShape.Width,100)
