# the checks of ch10_layout.ring: run with  ring ch10_layout.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oList.SelectedIndex = 2
	dnAssert("details follow the list",oNameValue.Text,"Cy")
	dnAssert("the city",oCityValue.Text,"Tokyo")
	dnAssert("Cy has three orders",oGrid.Rows.Count,3)
	oList.SelectedIndex = 1
	dnAssert("Bob has one order",oGrid.Rows.Count,1)
