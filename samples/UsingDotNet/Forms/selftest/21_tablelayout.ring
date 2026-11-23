# the checks of 21_tablelayout.ring: run with  ring 21_tablelayout.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	dnAssert("9 cells",oTable.Controls.Count,9)
	dnAssert("cell position",oTable.GetRow(oTable.Controls.Item(5)),1)
