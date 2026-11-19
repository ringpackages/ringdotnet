# the checks of ch10_windows.ring: run with  ring ch10_windows.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("one window at the start",openForms(),1)

	# open the tool window: two windows, and the tool has the main window as owner
	openTool()
	dnAssert("two windows",openForms(),2)
	dnAssert("the owner",oTool.Owner.Text,"Main window")

	# a second click on the button does not make a second window
	openTool()
	dnAssert("still two windows",openForms(),2)
	dnAssert("one tool window was made",nToolOpened,1)

	# the tool talks to the main window
	oToolBox.Text = "blue"
	applyTool()
	dnAssert("the main window shows it",oShown.Text,"Applied: blue")
	dnAssert("the tool says so",oToolStatus.Text,"Sent to the main window")

	# closing the tool: the main window stays; the tool can be opened again (a new window)
	oTool.Close()
	dnAssert("the tool closed",cApplied,"[tool closed]")
	dnAssert("one window again",openForms(),1)
	openTool()
	dnAssert("a new tool window",nToolOpened,2)
	dnAssert("two windows again",openForms(),2)
	# the form of this test is closed by uiTest after this code: the owned tool window closes with its owner
