# the checks of ch10_keyboard.ring: run with  ring ch10_keyboard.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	# the keys go to the box that has the focus, through the real key processing
	oForm.ActiveControl = oAge
	uiSendKeys(oForm,"1a2-3")
	dnAssert("only digits",oAge.Text,"123")
	dnAssert("the other keys were refused",nRejected,2)

	# MaxLength: a fourth digit is not accepted
	uiSendKeys(oForm,"9")
	dnAssert("at most three characters",oAge.Text,"123")

	# Backspace works, because the filter lets it through
	uiSendKeys(oForm,"{BACKSPACE}")
	dnAssert("backspace",oAge.Text,"12")

	# Enter presses the OK button (the AcceptButton) from any box: with the name empty the program asks for it
	oForm.ActiveControl = oAge
	uiSendKeys(oForm,"{ENTER}")
	dnAssert("an empty name",oResult.Text,"Please fill in both boxes")
	oName.Text = "Ann"                                   # (letters typed by a test depend on the keyboard layout of the computer, so it is set)
	oForm.ActiveControl = oName
	uiSendKeys(oForm,"{ENTER}")
	dnAssert("the result",oResult.Text,"Ann is 12 years old")

	# the tab order: Tab goes name -> age -> OK
	oForm.ActiveControl = oName
	uiSendKeys(oForm,"{TAB}")
	dnAssert("tab to the age box",oForm.ActiveControl.TabIndex,2)

	# Escape presses the CancelButton: the form closes
	uiSendKeys(oForm,"{ESC}")
	dnAssert("escape closed the form",lClosed,True)
