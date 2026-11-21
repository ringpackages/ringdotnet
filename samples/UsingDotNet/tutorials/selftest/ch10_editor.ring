# the checks of ch10_editor.ring: run with  ring ch10_editor.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oEditor.Text = "Hello from the test"
	dnAssert("the text changed",lChanged,True)
	cTemp = new Path().Combine([new Path().GetTempPath(),"ringdotnet_editor.txt"])
	cFileName = cTemp
	saveFile()
	dnAssert("saved",new File().ReadAllText(cTemp),"Hello from the test")
	dnAssert("no longer changed",lChanged,False)
	newFile()
	dnAssert("new file is empty",oEditor.Text,"")
	loadFile(cTemp)
	dnAssert("opened again",oEditor.Text,"Hello from the test")
	new File().Delete(cTemp)
