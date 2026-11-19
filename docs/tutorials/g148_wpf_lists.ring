# WPF lists and dynamic content - a ListBox that the program fills, selection, moving and removing items, and controls made in code
load "dotnet.ring"
using {
	"System.Windows"
	"System.Windows.Controls"
	"System"
}

oWindow = ""

func main
	# The window has a text box to type into, buttons, a ListBox and a WrapPanel. The ListBox is empty in the XAML: the program fills it.
	cXaml = '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Lists" Width="420" Height="420" Background="#F4F2FB">'
	cXaml += '<StackPanel Margin="12">'
	cXaml += '<DockPanel><Button x:Name="add" Content="Add" Width="70" DockPanel.Dock="Right" Margin="6,0,0,0"/><TextBox x:Name="input"/></DockPanel>'
	cXaml += '<ListBox x:Name="list" Height="130" Margin="0,8,0,8"/>'
	cXaml += '<StackPanel Orientation="Horizontal">'
	cXaml += '<Button x:Name="remove" Content="Remove" Width="80" Margin="0,0,6,0"/><Button x:Name="up" Content="Up" Width="60" Margin="0,0,6,0"/>'
	cXaml += '<Button x:Name="down" Content="Down" Width="60" Margin="0,0,6,0"/><Button x:Name="clear" Content="Clear" Width="60"/>'
	cXaml += '</StackPanel>'
	cXaml += '<TextBlock x:Name="count" Margin="0,8,0,4" Text="0 items"/>'
	cXaml += '<WrapPanel x:Name="chips"/>'
	cXaml += '</StackPanel></Window>'
	oWindow = wpfXaml(cXaml)

	wpfFind(oWindow,"add").setClickEvent("addItem()")
	wpfFind(oWindow,"remove").setClickEvent("removeItem()")
	wpfFind(oWindow,"up").setClickEvent("moveItem(-1)")
	wpfFind(oWindow,"down").setClickEvent("moveItem(1)")
	wpfFind(oWindow,"clear").setClickEvent("clearItems()")

	wpfTest(oWindow,"selfTest()")
	wpfRun(oWindow)
	wpfEnd()

func listBox
	return wpfFind(oWindow,"list")

# Items is the collection of the items of a list control. Add puts an item at the end, Insert at a place, RemoveAt takes one away.
func addItem
	cText = trim(wpfFind(oWindow,"input").Text)
	if cText = ""
		return
	ok
	listBox().Items.Add(cText)
	wpfFind(oWindow,"input").Text = ""
	refresh()

# SelectedIndex is -1 when nothing is selected
func removeItem
	nIndex = listBox().SelectedIndex
	if nIndex >= 0
		listBox().Items.RemoveAt(nIndex)
		refresh()
	ok

# move the selected item up (-1) or down (1): take it out and put it in at the new place
func moveItem nStep
	nIndex = listBox().SelectedIndex
	nNew = nIndex + nStep
	if nIndex < 0 or nNew < 0 or nNew >= listBox().Items.Count
		return
	ok
	cText = listBox().Items.Item(nIndex)
	listBox().Items.RemoveAt(nIndex)
	listBox().Items.Insert(nNew,cText)
	listBox().SelectedIndex = nNew
	refresh()

func clearItems
	listBox().Items.Clear()
	refresh()

# the count, and a button for each item in the WrapPanel: controls MADE BY THE PROGRAM, as many as there are items. The panel is emptied
# first, and each button gets the code that shows its item.
func refresh
	nCount = listBox().Items.Count
	wpfFind(oWindow,"count").Text = "" + nCount + " items"
	oChips = wpfFind(oWindow,"chips")
	oChips.Children.Clear()
	for i = 0 to nCount - 1
		oChip = wpfButton(listBox().Items.Item(i),"showItem(" + i + ")")
		oChip.Margin = new Thickness(0,2,4,2)
		oChips.Children.Add(oChip)
	next

func showItem nIndex
	wpfFind(oWindow,"count").Text = "Item " + (nIndex + 1) + ": " + listBox().Items.Item(nIndex)

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
	oButton.RaiseEvent(new RoutedEventArgs().New_([ :routedEvent = new WpfButtonBase().ClickEvent ]))

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
