# the checks of 19_splitcontainer.ring: run with  ring 19_splitcontainer.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oList.SelectedIndex = 1
	dnAssert("right panel",oText.Text,"You selected Two")
	dnAssert("splitter",oSplit.SplitterDistance,140)
