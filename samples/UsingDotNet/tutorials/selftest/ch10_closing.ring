# the checks of ch10_closing.ring: run with  ring ch10_closing.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	# no changes yet: closing would not ask anything
	dnAssert("no changes",lChanged,False)

	# a change, and the user answers Cancel: the form stays open
	oEdit.Text = "my notes, changed"
	dnAssert("the change is known",lChanged,True)
	cTestAnswer = "Cancel"
	oForm.Close()
	dnAssert("asked once",nCloseAttempts,1)
	dnAssert("not closed after Cancel",lClosed,False)
	dnAssert("the file was not written",new File().Exists(cFile),False)

	# the user answers Yes: the changes are saved, and the form closes (here the test form is closed by uiTest after this code)
	cTestAnswer = "Yes"
	oForm.Close()
	dnAssert("asked again",nCloseAttempts,2)
	dnAssert("saved on Yes",new File().ReadAllText(cFile),"my notes, changed")
	dnAssert("the form closed",lClosed,True)
	dnAssert("no changes left",lChanged,False)
