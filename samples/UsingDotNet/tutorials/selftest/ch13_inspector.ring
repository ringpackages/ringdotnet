# the checks of ch13_inspector.ring: run with  ring ch13_inspector.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

# the value of a property that the list shows, found by the name of the property
func valueOf cName

	for i = 0 to oList.Items.Count - 1
		if oList.Items.Item(i).Text = cName
			return oList.Items.Item(i).SubItems.Item(2).Text
		ok
	next
	return "(not in the list)"

func selfTest

	# the Uri
	dnAssert("the host",valueOf("Host"),"example.com")
	dnAssert("the port",valueOf("Port"),"8080")
	dnAssert("the scheme",valueOf("Scheme"),"https")
	dnAssert("the fragment",valueOf("Fragment"),"#top")

	# a DateTime: choose it in the combo box (the event fills the list again)
	oChoice.SelectedIndex = 1
	dnAssert("the year",valueOf("Year"),"2030")
	dnAssert("the day of the week",valueOf("DayOfWeek"),"Saturday")
	dnAssert("the hour",valueOf("Hour"),"14")

	# a FileInfo of a real file
	oChoice.SelectedIndex = 2
	dnAssert("the name",valueOf("Name"),"ringdotnet-inspect.txt")
	dnAssert("the length",valueOf("Length"),"16")
	dnAssert("it exists",valueOf("Exists"),"1")

	# a StringBuilder: the property Chars is an indexer and is not listed
	oChoice.SelectedIndex = 3
	dnAssert("the length of the text",valueOf("Length"),"5")
	dnAssert("an indexer is skipped",valueOf("Chars"),"(not in the list)")
