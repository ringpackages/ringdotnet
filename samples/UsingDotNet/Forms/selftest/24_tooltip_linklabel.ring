# the checks of 24_tooltip_linklabel.ring: run with  ring 24_tooltip_linklabel.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("tooltip",oTip.GetToolTip(oButton),"This button only has a tooltip")
	linkClicked()
	dnAssert("link handler",oOpened.Text,"link clicked")
