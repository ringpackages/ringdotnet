# the checks of 08_grid_layout.ring: run with  ring 08_grid_layout.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("9 cells",oGrid.Children.Count,9)
	dnAssert("3 rows",oGrid.RowDefinitions.Count,3)
	oFifth = oGrid.Children.Item(4)
	dnAssert("attached row",oGrid.GetRow(oFifth),1)
	dnAssert("attached column",oGrid.GetColumn(oFifth),1)
