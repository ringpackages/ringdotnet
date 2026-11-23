# the checks of ch11_wpf_menu.ring: run with  ring ch11_wpf_menu.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

# a menu item is clicked by raising its Click event, as a user would
func clickItem cName

	wpfFind(oWindow,cName).RaiseEvent(new RoutedEventArgs().@New([ :routedEvent = new MenuItem().ClickEvent ]))

func selfTest

	# a menu item runs its code
	clickItem("newItem")
	dnAssert("new order",wpfFind(oWindow,"message").Text,"New order 1")
	clickItem("exitItem")
	dnAssert("exit",wpfFind(oWindow,"message").Text,"Exit was chosen")

	# a checkable item: unchecking hides the status bar, checking shows it
	dnAssert("the status bar is visible",wpfFind(oWindow,"status").Visibility,"Visible")
	wpfFind(oWindow,"statusItem").IsChecked = False
	dnAssert("the status bar is hidden",wpfFind(oWindow,"status").Visibility,"Collapsed")
	wpfFind(oWindow,"statusItem").IsChecked = True
	dnAssert("the status bar is back",wpfFind(oWindow,"status").Visibility,"Visible")

	# the tabs
	dnAssert("the first tab",wpfFind(oWindow,"tabs").SelectedIndex,0)
	wpfFind(oWindow,"tabs").SelectedIndex = 1
	dnAssert("the tab changed",wpfFind(oWindow,"message").Text,"Tab 1")
	wpfFind(oWindow,"tabs").SelectedIndex = 0

	# a combo box, an expander and a check box inside it
	wpfFind(oWindow,"speed").SelectedIndex = 2
	dnAssert("the chosen speed",wpfFind(oWindow,"speed").Text,"Overnight")
	dnAssert("the expander is closed",wpfFind(oWindow,"more").IsExpanded,False)
	wpfFind(oWindow,"more").IsExpanded = True
	wpfFind(oWindow,"gift").IsChecked = True
	dnAssert("gift wrap",wpfFind(oWindow,"gift").IsChecked,True)

	# a date picker: SelectedDate is a DateTime (empty until a date is chosen)
	wpfFind(oWindow,"day").SelectedDate = new DateTime(2030,5,10)
	dnAssert("the chosen date",wpfFind(oWindow,"day").SelectedDate.Format("yyyy-MM-dd"),"2030-05-10")

	# the menu item New puts everything back
	clickItem("newItem")
	dnAssert("the speed is reset",wpfFind(oWindow,"speed").SelectedIndex,0)
	dnAssert("the gift is reset",wpfFind(oWindow,"gift").IsChecked,False)
