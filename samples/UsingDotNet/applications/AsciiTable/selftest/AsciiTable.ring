# the checks of AsciiTable.ring: run with  ring AsciiTable.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	dnAssert("all 128 rows",oList.Items.Count,128)
	dnAssert("row 65 is A",oList.Items.Item(65).SubItems.Item(3).Text,"A")
	dnAssert("hex of 65",oList.Items.Item(65).SubItems.Item(1).Text,"41")
	dnAssert("binary of 65",oList.Items.Item(65).SubItems.Item(2).Text,"01000001")
	dnAssert("control name",oList.Items.Item(10).SubItems.Item(3).Text,"LF")
	oFilter.Text = "esc"
	dnAssert("filter by name",oList.Items.Count,1)
	oFilter.Text = "7f"
	dnAssert("filter by hex",oList.Items.Count,1)
	oFilter.Text = ""
	dnAssert("all rows again",oList.Items.Count,128)
	dnAssert("count label",oCount.Text,"128 characters")
