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
	uiRun(oForm)

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
