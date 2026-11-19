# the checks of ch12_addressbook.ring: run with  ring ch12_addressbook.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	for aPerson in [["Ann","555-0101","Cairo"],["Bob","555-0102","Oslo"],["Cy","555-0103","Cairo"]]
		oName.Text = aPerson[1]
		oPhone.Text = aPerson[2]
		oCity.Text = aPerson[3]
		addContact()
	next
	dnAssert("three contacts in the database",oDb.count("Contacts"),3)
	dnAssert("three rows in the grid",oGrid.Rows.Count,3)
	oName.Text = ""
	addContact()
	dnAssert("a name is required",oStatus.Text,"  A contact needs a name")
	oSearch.Text = "cairo"
	dnAssert("the search narrows the grid (case does not matter)",oGrid.Rows.Count,2)
	oSearch.Text = ""
	oGrid.Rows.Item(1).Selected = True
	dnAssert("choosing a row fills the fields",oName.Text,"Bob")
	oName.Text = "Robert"
	updateContact()
	dnAssert("an update reaches the database",dbValue(oDb.byKey("Contacts",2),"Name"),"Robert")
	oGrid.Rows.Item(1).Selected = True              # reload() cleared the selection: choose Robert again
	deleteContact()                                  # a test answers the question with yes
	dnAssert("a delete",oDb.count("Contacts"),2)
	dnAssert("Robert is gone",oDb.byKey("Contacts",2),"")
	dnAssert("and the grid follows",oGrid.Rows.Count,2)
