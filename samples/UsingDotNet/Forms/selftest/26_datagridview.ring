# the checks of 26_datagridview.ring: run with  ring 26_datagridview.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	dnAssert("three rows",oGrid.Rows.Count,3)
	dnAssert("two columns",oGrid.Columns.Count,2)
	dnAssert("cell value",oGrid.Rows.Item(1).Cells.Item(0).Value,"Bob")
	oGrid.Sort([ :dataGridViewColumn = oGrid.Columns.Item(1), :direction = "Descending" ])
	dnAssert("sorted by age",oGrid.Rows.Item(0).Cells.Item(0).Value,"Cy")
