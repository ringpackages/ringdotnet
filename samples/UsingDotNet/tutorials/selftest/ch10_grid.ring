# the checks of ch10_grid.ring: run with  ring ch10_grid.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	# the starting totals: 10 x 2.5 = 25; 4 x 6 + 5 (express) = 29, and 10 percent more for Large = 31.9; 3 x 4 = 12
	dnAssert("pens",cellText(0,"Total"),"25")
	dnAssert("paper",cellText(1,"Total"),"31.90")
	dnAssert("glue",cellText(2,"Total"),"12")
	dnAssert("the sum",oSum.Text,"Rows: 3, the total is 68.90")

	# the user types a new quantity in a cell: the total of the row and the sum follow
	oGrid.Rows.Item(0).Cells.Item("Qty").Value = 20
	dnAssert("pens, 20",cellText(0,"Total"),"50")
	dnAssert("the sum changed",oSum.Text,"Rows: 3, the total is 93.90")

	# a check box: express adds 5
	oGrid.Rows.Item(2).Cells.Item("Express").Value = True
	dnAssert("glue, express",cellText(2,"Total"),"17")

	# a combo box: the size Large adds 10 percent
	oGrid.Rows.Item(0).Cells.Item("Size").Value = "Large"
	dnAssert("pens, large",cellText(0,"Total"),"55")

	# a wrong text counts as 0 and does not stop the program
	oGrid.Rows.Item(1).Cells.Item("Price").Value = "abc"
	dnAssert("a wrong price",cellText(1,"Total"),"5.50")

	# a new row
	addRow()
	dnAssert("four rows",oGrid.Rows.Count,4)
	dnAssert("the new row",cellText(3,"Total"),"")
	rowChanged(3)
	dnAssert("the new row, calculated",cellText(3,"Total"),"1")
