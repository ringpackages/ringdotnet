# the checks of ch10_clipboard.ring: run with  ring ch10_clipboard.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func waitForImage
	oClipboard = new Clipboard()
	for nTry = 1 to 20
		if oClipboard.ContainsImage()
			return True
		ok
		new Task().Delay(50).Wait(NULL)
	next
	return False

func selfTest
	oClipboard = new Clipboard()
	cBefore = readText()                                    # keep what the user had on the clipboard

	# text: copy, change the box, paste
	oForm.Controls.Item(1).PerformClick()
	oEdit.Text = "something else"
	oForm.Controls.Item(2).PerformClick()
	dnAssert("text round trip",oEdit.Text,"Copied from Ring")
	dnAssert("text status",oStatus.Text,"Pasted")

	# the table: tabs between the cells, a new line after each row
	oForm.Controls.Item(3).PerformClick()
	cTable = readText()
	dnAssert("table text",substr(cTable,char(9),"|"),"Item|Price" + nl + "Tea|2.50" + nl + "Coffee|3.20" + nl + "Juice|4.00" + nl)

	# the picture
	oForm.Controls.Item(4).PerformClick()
	dnAssert("has image",waitForImage(),True)
	dnAssert("image size",oClipboard.GetImage().Width,120)

	# clear: nothing left, and pasting says so
	oForm.Controls.Item(5).PerformClick()
	dnAssert("has no text",oClipboard.ContainsText(NULL),False)
	oForm.Controls.Item(2).PerformClick()
	dnAssert("paste of nothing",oStatus.Text,"The clipboard has no text")

	if cBefore != ""
		oClipboard.SetText(cBefore)                         # put it back
	ok
