# the checks of ch11_wpf_binding.ring: run with  ring ch11_wpf_binding.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oSlider = wpfFind(oWindow,"amount")
	oBox = wpfFind(oWindow,"box")
	oBar = wpfFind(oWindow,"bar")
	oText = wpfFind(oWindow,"text")
	oSend = wpfFind(oWindow,"send")
	oAllow = wpfFind(oWindow,"allow")
	oColors = wpfFind(oWindow,"colors")
	oChosen = wpfFind(oWindow,"chosen")

	# the starting values follow the slider
	dnAssert("the text box shows the slider",oBox.Text,"20")
	dnAssert("the bar shows the slider",oBar.Value,20)
	dnAssert("the text shows the slider",oText.Text,"20 percent")

	# moving the slider (the program does what the user does) changes the three of them
	oSlider.Value = 75
	dnAssert("slider to text box",oBox.Text,"75")
	dnAssert("slider to bar",oBar.Value,75)
	dnAssert("slider to text",oText.Text,"75 percent")

	# TwoWay: typing in the text box moves the slider
	oBox.Text = "40"
	dnAssert("text box to slider",oSlider.Value,40)
	dnAssert("and so to the bar",oBar.Value,40)

	# a check box switches the button on and off
	dnAssert("the button is on",oSend.IsEnabled,True)
	oAllow.IsChecked = False
	dnAssert("the button is off",oSend.IsEnabled,False)

	# a list: nothing chosen shows the fallback text, a choice shows the item
	dnAssert("fallback",oChosen.Text,"nothing chosen")
	oColors.SelectedIndex = 1
	dnAssert("the chosen item",oChosen.Text,"Green")
