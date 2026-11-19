# drag and drop - moving items between two lists, Ctrl for copy, dropping files on a window, and testing the drop without a mouse
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Windows.Forms"
}

# controls and state that the event code uses are global variables
oForm = ""
oSource = ""
oBasket = ""
oStatus = ""
oFilesList = ""

func main
	oForm = uiForm("Drag and drop",520,360)
	uiLabel(oForm,"Fruits (drag from here)",15,12,230,22)
	oSource = uiListBox(oForm,15,36,230,130)
	uiLabel(oForm,"Basket (drop here)",270,12,230,22)
	oBasket = uiListBox(oForm,270,36,230,130)
	for cFruit in [ "apple","banana","cherry","grape" ]
		oSource.Items.Add(cFruit)
	next

	# The DROP TARGET must say that it accepts drops (AllowDrop), and then it gets three events: DragEnter when the mouse with the data comes
	# in (the program says whether it accepts, with e.Effect), DragOver while it moves, and DragDrop when the button is released.
	oBasket.AllowDrop = True
	oBasket.setDragEnterEvent("dragEnter(aDotNetArgs[2])")
	oBasket.setDragOverEvent("dragEnter(aDotNetArgs[2])")
	oBasket.setDragDropEvent("dragDrop(aDotNetArgs[2])")

	# The SOURCE starts the drag: when the mouse button goes down on an item, DoDragDrop starts the operation and waits until the user
	# drops (or cancels). The data (here a text) and the allowed effects are the arguments.
	oSource.setMouseDownEvent("beginDrag(aDotNetArgs[2].X,aDotNetArgs[2].Y)")

	# A window can accept FILES from the file explorer: the same events, with the data format "FileDrop"
	uiLabel(oForm,"Drop files from the explorer on this list:",15,180,400,22)
	oFilesList = uiListBox(oForm,15,204,485,80)
	oFilesList.AllowDrop = True
	oFilesList.setDragEnterEvent("dragEnter(aDotNetArgs[2])")
	oFilesList.setDragDropEvent("dropFiles(aDotNetArgs[2])")

	oStatus = uiLabel(oForm,"Ready",15,296,485,22)
	uiTest(oForm,"selfTest()")
	uiRun(oForm)
	uiEnd()

# the start of a drag: the item under the mouse is the data. The result of DoDragDrop is the effect that the target chose: "Move" means
# that the item is taken from the source.
func beginDrag nX,nY
	nIndex = oSource.IndexFromPoint([ :x = nX, :y = nY ])
	if nIndex < 0
		return
	ok
	cItem = oSource.Items.Item(nIndex)
	cEffect = oSource.DoDragDrop([ :data = cItem, :allowedEffects = "Copy, Move" ])
	if cEffect = "Move"
		oSource.Items.RemoveAt(nIndex)
	ok

# Does the target accept what comes? Text or files: yes. The Ctrl key (bit 8 of the key state) asks for a copy, and without it the
# effect is a move. Anything else: "None" (the mouse shows a forbidden sign).
func dragEnter oArgs
	if oArgs.Data.GetDataPresent("Text") or oArgs.Data.GetDataPresent("FileDrop")
		if (oArgs.KeyState & 8) != 0
			oArgs.Effect = "Copy"
		else
			oArgs.Effect = "Move"
		ok
	else
		oArgs.Effect = "None"
	ok

# the drop of a text: put it in the basket (once)
func dragDrop oArgs
	cText = oArgs.Data.GetData("Text")
	if oBasket.Items.IndexOf(cText) >= 0
		oStatus.Text = cText + " is already in the basket"
		oArgs.Effect = "None"                              # the answer to the source: nothing was taken
		return
	ok
	oBasket.Items.Add(cText)
	oStatus.Text = "Dropped: " + cText + " (" + oArgs.Effect + ")"

# the drop of files: the data is a list of paths
func dropFiles oArgs
	if not oArgs.Data.GetDataPresent("FileDrop")
		return
	ok
	for cPath in oArgs.Data.GetData("FileDrop").toList()
		oFilesList.Items.Add(new Path().GetFileName(cPath))
	next
	oStatus.Text = "" + oFilesList.Items.Count + " files dropped"

# a drag made by the test: a DataObject with the data, and the arguments that .NET would give to the event
func makeArgs cFormat,xData,nKeys
	oData = new DataObject().New_([ :format = cFormat, :data = xData ])
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
