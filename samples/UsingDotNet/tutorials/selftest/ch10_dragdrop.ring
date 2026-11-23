# the checks of ch10_dragdrop.ring: run with  ring ch10_dragdrop.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

# a drag made by the test: a DataObject with the data, and the arguments that .NET would give to the event
func makeArgs cFormat,xData,nKeys

	oData = new DataObject().@New([ :format = cFormat, :data = xData ])
	return new DragEventArgs(oData, nKeys, 10, 10, "Copy, Move", "None")

func selfTest

	dnAssert("four fruits",oSource.Items.Count,4)
	dnAssert("the basket accepts drops",oBasket.AllowDrop,True)

	# the mouse comes in with a text: without Ctrl the effect is Move, with Ctrl it is Copy
	oArgs = makeArgs("Text","apple",0)
	dragEnter(oArgs)
	dnAssert("a move",oArgs.Effect,"Move")
	oArgs = makeArgs("Text","apple",8)
	dragEnter(oArgs)
	dnAssert("a copy with Ctrl",oArgs.Effect,"Copy")

	# data that the target does not understand (a picture format): refused
	oArgs = makeArgs("Bitmap","not a text",0)
	dragEnter(oArgs)
	dnAssert("refused",oArgs.Effect,"None")

	# the drop: the text is in the basket
	oArgs = makeArgs("Text","banana",0)
	dragEnter(oArgs)
	dragDrop(oArgs)
	dnAssert("the basket has it",oBasket.Items.Item(0),"banana")
	dnAssert("the status",oStatus.Text,"Dropped: banana (Move)")

	# the same fruit again: not added twice, and the source is told that nothing was taken
	oArgs = makeArgs("Text","banana",0)
	dragEnter(oArgs)
	dragDrop(oArgs)
	dnAssert("not twice",oBasket.Items.Count,1)
	dnAssert("nothing taken",oArgs.Effect,"None")

	# the drop of files
	oArgs = makeArgs("FileDrop",[ "C:/work/report.txt","C:/work/photo.png" ],0)
	dropFiles(oArgs)
	dnAssert("two files",oFilesList.Items.Count,2)
	dnAssert("the first name",oFilesList.Items.Item(0),"report.txt")
	dnAssert("the files status",oStatus.Text,"2 files dropped")
