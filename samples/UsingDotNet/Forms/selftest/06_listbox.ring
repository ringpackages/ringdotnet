# the checks of 06_listbox.ring: run with  ring 06_listbox.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	for cName in ["red","green","blue"]
		oEdit.Text = cName
		addItem()
	next
	dnAssert("three items",oList.Items.Count,3)
	oList.SelectedIndex = 1
	dnAssert("selected text",oSelected.Text,"Selected: green")
	removeItem()
	dnAssert("removed",oList.Items.Count,2)
