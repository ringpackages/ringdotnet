# the checks of 01_hello_window.ring: run with  ring 01_hello_window.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	dnAssert("title",oWindow.Title,"Hello WPF")
	dnAssert("text",oText.Text,"Hello from Ring and WPF!")
	dnAssert("size",oWindow.Width,320)
