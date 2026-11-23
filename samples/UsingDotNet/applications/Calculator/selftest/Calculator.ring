# the checks of Calculator.ring: run with  ring Calculator.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func typeKeys cKeys

	for x = 1 to len(cKeys)
		press(cKeys[x])
	next

func selfTest

	typeKeys("12+30=")
	dnAssert("12+30",oScreen.Text,"42")
	press("C")
	typeKeys("9/3=")
	dnAssert("9/3",oScreen.Text,"3")
	press("C")
	typeKeys("5*0.5=")
	dnAssert("5*0.5",oScreen.Text,"2.5")
	press("C")
	typeKeys("1+2+3=")
	dnAssert("chained",oScreen.Text,"6")
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
	typeKeys("50")
	press("%")
	dnAssert("percent",oScreen.Text,"0.5")
	press("C")
	typeKeys("7")
	press("±")
	dnAssert("sign",oScreen.Text,"-7")
	dnAssert("the history is empty after a sign change",oHistory.Text,"")
	press("C")
	# the buttons work as well
	for oControl in oForm.Controls.toList()
		if classname(oControl) = "button" and oControl.Text = "7"
			oControl.PerformClick()
			exit
		ok
	next
	dnAssert("button click",oScreen.Text,"7")
	press("C")
	# real key presses while a button has the focus (Enter used to press that button again)
	oFocused = ""
	for oControl in oForm.Controls.toList()
		if classname(oControl) = "button" and oControl.Text = "7"
			oFocused = oControl
		ok
	next
	oFocused.Focus()
	if uiSendKeys(oForm,"12{+}30{ENTER}")
		dnAssert("typing 12+30 and Enter",oScreen.Text,"42")
		uiSendKeys(oForm,"{ESC}")
		dnAssert("Escape clears",oScreen.Text,"0")
		uiSendKeys(oForm,"123{BACKSPACE}")
		dnAssert("Backspace removes a digit",oScreen.Text,"12")
		uiSendKeys(oForm,"{ESC}9{/}3{ENTER}")
		dnAssert("division with the keyboard",oScreen.Text,"3")
	ok
