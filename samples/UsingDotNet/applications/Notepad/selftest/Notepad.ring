# the checks of Notepad.ring: run with  ring Notepad.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oEditor.Text = "Hello" + windowsnl() + "Ring and .NET"
	dnAssert("modified after typing",lModified,1)
	dnAssert("title has a star","*" = right(left(oForm.Text,len("Untitled*")),1),True)
	cTemp = new Path().Combine([new Path().GetTempPath(),"notepad_selftest.txt"])
	saveTo(cTemp)
	dnAssert("saved",new File().Exists(cTemp),True)
	dnAssert("not modified after save",lModified,0)
	dnAssert("title is the file name",oForm.Text,"notepad_selftest.txt - Notepad")
	oEditor.Text = "other"
	dnAssert("modified again",lModified,1)
	lModified = false
	loadFile(cTemp)
	dnAssert("loaded text",left(oEditor.Text,5),"Hello")
	dnAssert("line count",oEditor.Lines.Length,2)
	new File().Delete(cTemp)
	oEditor.SelectionStart = 3
	showPosition()
	dnAssert("status position",oPosition.Text,"Ln 1, Col 4")
	oEditor {
		Text = "one two three two"
		SelectionStart = 0
		SelectionLength = 0
	}
	oFindText.Text = "two"
	findNext()
	dnAssert("find first",oEditor.SelectionStart,4)
	findNext()
	dnAssert("find next",oEditor.SelectionStart,14)
	findNext()
	dnAssert("find wraps",oEditor.SelectionStart,4)
	oFindText.Text = "zzz"
	findNext()
	dnAssert("not found message",oFound.Text,"Not found")
	lModified = false
