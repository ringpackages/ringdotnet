# the checks of 03_textbox_echo.ring: run with  ring 03_textbox_echo.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oEdit.Text = "Ring"
	dnAssert("echo",oEcho.Text,"You typed: Ring")
	oEdit.Text = ""
	dnAssert("empty",oEcho.Text,"You typed: ")
