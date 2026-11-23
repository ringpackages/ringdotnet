# the checks of ch10_menus.ring: run with  ring ch10_menus.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	# the same action from the menu, the toolbar and the context menu
	oText.Text = "hello menus"
	oForm.MainMenuStrip.Items.Item(2).DropDownItems.Item(0).PerformClick()       # Text > Upper case
	dnAssert("the menu item ran the action",oText.Text,"HELLO MENUS")
	oText.Text = "second"
	oForm.Controls.Item(1).Items.Item(0).PerformClick()                           # the toolbar (the 2nd control added): button "Upper"
	dnAssert("the toolbar button ran the same action",oText.Text,"SECOND")
	oText.Text = "third"
	oText.ContextMenuStrip.Items.Item(1).PerformClick()                           # the context menu "Upper case"
	dnAssert("the context menu too",oText.Text,"THIRD")
	dnAssert("three actions were reported",nActions,3)
	# the ticked item
	oWrapItem.Checked = False
	dnAssert("word wrap off",oText.WordWrap,False)
	dnAssert("and the status says so",oStatus.Items.Item(0).Text,"Word wrap is off")
	# the shortcut keys are properties of the items
	dnAssert("a shortcut key (a combination of flags: C and Control)",oForm.MainMenuStrip.Items.Item(1).DropDownItems.Item(1).ShortcutKeys,"C, Control")
