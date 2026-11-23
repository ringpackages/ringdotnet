# the checks of 07_combobox.ring: run with  ring 07_combobox.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oCombo.SelectedIndex = 2
	dnAssert("item",oChoice.Text,"Language: Lua")
	dnAssert("count",oCombo.Items.Count,4)
