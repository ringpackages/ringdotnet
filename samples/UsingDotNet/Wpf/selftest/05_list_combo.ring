# the checks of 05_list_combo.ring: run with  ring 05_list_combo.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oList.SelectedIndex = 1
	dnAssert("list",cPicked,"list:Python")
	oCombo.SelectedIndex = 2
	dnAssert("combo",cPicked,"combo:Lua")
	dnAssert("count",oList.Items.Count,3)
