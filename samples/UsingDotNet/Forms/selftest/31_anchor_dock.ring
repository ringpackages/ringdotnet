# the checks of 31_anchor_dock.ring: run with  ring 31_anchor_dock.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	nBefore = oBox.Height
	oForm.ClientSize = new Size(460,320)
	dnAssert("the docked label stays on top",oTop.Top,0)
	dnAssert("the text box grew",oBox.Height > nBefore,True)
	dnAssert("the button moved right",oOk.Left > 270,True)
