# the checks of AddressBook.ring: run with  ring AddressBook.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	for aContact in [["Ann Lee","555-0101","Cairo"],["Bob Stone","555-0102","Oslo"],["Cy Young","555-0103","Cairo"]]
		oName.Text = aContact[1]
		oPhone.Text = aContact[2]
		oCity.Text = aContact[3]
		addContact()
	next
	dnAssert("three contacts",oTable.Rows.Count,3)
	dnAssert("grid shows them",oGrid.Rows.Count,3)
	dnAssert("fields are cleared",oName.Text,"")
	oSearch.Text = "cairo"
	dnAssert("filter by city",oGrid.Rows.Count,2)
	oSearch.Text = "stone"
	dnAssert("filter by name",oGrid.Rows.Item(0).Cells.Item(0).Value,"Bob Stone")
	oSearch.Text = ""
	dnAssert("no filter",oGrid.Rows.Count,3)
	oName.Text = ""
	addContact()
	dnAssert("an empty name is ignored",oTable.Rows.Count,3)
	saveBook()
	dnAssert("saved as xml",new File().Exists(cFile),True)
	oGrid.Rows.Item(1).Selected = True
	deleteSelected()
	dnAssert("deleted",oTable.Rows.Count,2)
	loadBook()
	dnAssert("loaded again",oTable.Rows.Count,3)
	dnAssert("data is back",oTable.Rows.Item(1).Item("Name"),"Bob Stone")
	dnAssert("count text",oCount.Text,"3 of 3 contacts")
	new File().Delete(cFile)
	# loading without a saved file is a message, not a crash
	oTable.Clear()
	loadBook()
	dnAssert("no file message",left(oMessage.Text,15),"Nothing to load")
	dnAssert("nothing was loaded",oTable.Rows.Count,0)
	oName.Text = "Zed"
	addContact()
	saveBook()
	dnAssert("save message",left(oMessage.Text,7),"Saved 1")
	new File().Delete(cFile)
