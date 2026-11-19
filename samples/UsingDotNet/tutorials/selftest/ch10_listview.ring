# the checks of ch10_listview.ring: run with  ring ch10_listview.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func firstColumn
	cText = ""
	for i = 0 to oList.Items.Count - 1
		if cText != ""
			cText += ", "
		ok
		cText += oList.Items.Item(i).Text
	next
	return cText

func selfTest
	dnAssert("five rows",oList.Items.Count,5)
	dnAssert("the cells of a row",oList.Items.Item(1).SubItems.Item(2).Text,"2030-03-11")

	# sort by the task name (column 0), then again for the other direction
	sortBy(0)
	dnAssert("by name",firstColumn(),"Back up the files, Book the room, Buy tea, Call the bank, Write the report")
	sortBy(0)
	dnAssert("by name, descending",left(firstColumn(),16),"Write the report")

	# sort by the due date (column 2): the text of a date in the form year-month-day sorts like the dates
	sortBy(2)
	dnAssert("by date",oList.Items.Item(0).SubItems.Item(2).Text,"2030-03-09")
	dnAssert("by date, the last",oList.Items.Item(4).SubItems.Item(2).Text,"2030-03-20")

	# check two rows and remove them
	oList.Items.Item(0).Checked = True
	oList.Items.Item(1).Checked = True
	dnAssert("two checked",oStatus.Text,"5 tasks, 2 checked")
	removeChecked()
	dnAssert("three left",oStatus.Text,"3 tasks, 0 checked")
