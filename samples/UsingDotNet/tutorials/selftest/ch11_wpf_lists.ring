# the checks of ch11_wpf_lists.ring: run with  ring ch11_wpf_lists.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

# the items as one text, for the test
func itemsText

	cText = ""
	for i = 0 to listBox().Items.Count - 1
		if cText != ""
			cText += ","
		ok
		cText += listBox().Items.Item(i)
	next
	return cText

func clickButton oButton

	oButton.RaiseEvent(new RoutedEventArgs().@New([ :routedEvent = new WpfButtonBase().ClickEvent ]))

func selfTest

	# add three items through the text box and the Add button
	for cText in [ "tea","coffee","milk" ]
		wpfFind(oWindow,"input").Text = cText
		clickButton(wpfFind(oWindow,"add"))
	next
	dnAssert("three items",itemsText(),"tea,coffee,milk")
	dnAssert("the count",wpfFind(oWindow,"count").Text,"3 items")
	dnAssert("the text box is empty again",wpfFind(oWindow,"input").Text,"")
	dnAssert("an empty text adds nothing",itemsText(),"tea,coffee,milk")

	# a button was made for each item
	dnAssert("three chips",wpfFind(oWindow,"chips").Children.Count,3)
	dnAssert("the chip text",wpfFind(oWindow,"chips").Children.Item(1).Content,"coffee")
	clickButton(wpfFind(oWindow,"chips").Children.Item(2))
	dnAssert("a chip was clicked",wpfFind(oWindow,"count").Text,"Item 3: milk")

	# selecting and moving: coffee down, then up twice
	listBox().SelectedIndex = 1
	clickButton(wpfFind(oWindow,"down"))
	dnAssert("coffee down",itemsText(),"tea,milk,coffee")
	dnAssert("the selection follows",listBox().SelectedIndex,2)
	clickButton(wpfFind(oWindow,"up"))
	clickButton(wpfFind(oWindow,"up"))
	clickButton(wpfFind(oWindow,"up"))                       # the first place: nothing to do
	dnAssert("coffee up",itemsText(),"coffee,tea,milk")

	# remove the selected item, and with nothing selected remove nothing
	clickButton(wpfFind(oWindow,"remove"))
	dnAssert("removed",itemsText(),"tea,milk")
	listBox().SelectedIndex = -1
	clickButton(wpfFind(oWindow,"remove"))
	dnAssert("nothing selected, nothing removed",itemsText(),"tea,milk")

	# clear
	clickButton(wpfFind(oWindow,"clear"))
	dnAssert("empty",wpfFind(oWindow,"count").Text,"0 items")
	dnAssert("no chips",wpfFind(oWindow,"chips").Children.Count,0)
