# Notepad - a text editor (menu, file dialogs, status bar, find) written with RingDotNet

load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Windows.Forms"
}

cFileName = ""		# the file being edited ("" = untitled)
lModified = false
lLoading = false

oForm = uiForm("Untitled - Notepad",640,440)

uiMenu(oForm,[
	["File",[["New","newFile()","Control, N"],["Open...","openDialog()","Control, O"],["Save","saveFile()","Control, S"],["Save As...","saveAsDialog()"],["-",""],["Exit","oForm.Close()"]]],
	["Edit",[["Cut","oEditor.Cut()","Control, X"],["Copy","oEditor.Copy()","Control, C"],["Paste","oEditor.Paste()","Control, V"],["Select All","oEditor.SelectAll()","Control, A"],["-",""],["Find...","toggleFind()","Control, F"]]],
	["Format",[["Word Wrap","toggleWrap()"]]],
	["Help",[["About","uiMessage('Notepad written in Ring with RingDotNet','About')"]]]
])

oEditor = uiMemo(oForm,0,24,640,370)
oEditor {
	Dock = "Fill"
	Font = new Font("Consolas",11)
	setTextChangedEvent("textChanged()")
	setKeyUpEvent("showPosition()")
	setMouseUpEvent("showPosition()")
}

oStatus = new StatusStrip()
oPosition = new ToolStripStatusLabel()
oPosition.Text = "Ln 1, Col 1"
oStatus.Items.Add(oPosition)
oForm.Controls.Add(oStatus)
oEditor.BringToFront()		# the editor fills what is left, so it is sent to the front and docked first

# find bar
oFindPanel = uiPanel(oForm,0,0,640,30)
oFindPanel {
	Dock = "Bottom"
	Visible = False
}
uiLabel(oFindPanel,"Find:",6,6,40,20)
oFindText = uiTextBox(oFindPanel,50,4,200,24)
uiButton(oFindPanel,"Find next",260,3,80,26,"findNext()")
oFound = uiLabel(oFindPanel,"",350,6,200,20)

oForm.setFormClosingEvent("closing(aDotNetArgs[2])")

uiRun(oForm)

# --------------------------------------------------------------------------

func textChanged

	if not lLoading
		lModified = true
	ok
	updateTitle()
	showPosition()

func updateTitle

	cName = "Untitled"
	if cFileName != ""
		cName = new Path().GetFileName(cFileName)
	ok
	if lModified
		cName += "*"
	ok
	oForm.Text = cName + " - Notepad"

func showPosition

	nIndex = oEditor.SelectionStart
	nLine = oEditor.GetLineFromCharIndex(nIndex)
	nColumn = nIndex - oEditor.GetFirstCharIndexFromLine(nLine)
	oPosition.Text = "Ln " + (nLine + 1) + ", Col " + (nColumn + 1)

# true when it is fine to throw away the current text
func canDiscard

	if not lModified
		return true
	ok
	return uiAsk("Discard the changes?","Notepad")

func newFile

	if canDiscard()
		setText("")
		cFileName = ""
		lModified = false
		updateTitle()
	ok

func setText cText

	lLoading = true
	oEditor.Text = cText
	lLoading = false

func openDialog

	if canDiscard()
		cName = uiOpenFileName("Open","Text files (*.txt)|*.txt|All files (*.*)|*.*")
		if cName != ""
			loadFile(cName)
		ok
	ok

func loadFile cName

	try
		cContent = new File().ReadAllText(cName)
	catch
		uiMessage("Can't open " + cName + nl + cCatchError,"Notepad")
		return
	done
	setText(cContent)
	cFileName = cName
	lModified = false
	updateTitle()

func saveFile

	if cFileName = ""
		saveAsDialog()
	else
		saveTo(cFileName)
	ok

func saveAsDialog

	cName = uiSaveFileName("Save As","Text files (*.txt)|*.txt|All files (*.*)|*.*")
	if cName != ""
		saveTo(cName)
	ok

func saveTo cName

	try
		new File().WriteAllText([ :path = cName, :contents = oEditor.Text ])
	catch
		uiMessage("Can't save " + cName + nl + cCatchError,"Notepad")
		return
	done
	cFileName = cName
	lModified = false
	updateTitle()

func toggleWrap

	oEditor.WordWrap = not oEditor.WordWrap
	if oEditor.WordWrap
		oEditor.ScrollBars = "Vertical"
	else
		oEditor.ScrollBars = "Both"
	ok

func toggleFind

	oFindPanel.Visible = not oFindPanel.Visible
	if oFindPanel.Visible
		oFindText.Focus()
	ok

func findNext

	cWhat = oFindText.Text
	if cWhat = ""
		return
	ok
	cText = oEditor.Text
	nStart = oEditor.SelectionStart + oEditor.SelectionLength
	nIndex = findFrom(cText,cWhat,nStart)
	if nIndex < 0 and nStart > 0
		nIndex = findFrom(cText,cWhat,0)	# wrap around
	ok
	if nIndex < 0
		oFound.Text = "Not found"
	else
		oFound.Text = ""
		oEditor.Select([ :start = nIndex, :length = len(cWhat) ])
		oEditor.ScrollToCaret()
		oEditor.Focus()
	ok

# 0-based position of cWhat in cText at or after nStart (-1 = not found); positions are bytes, so it is meant for ASCII text
func findFrom cText, cWhat, nStart

	if nStart >= len(cText)
		return -1
	ok
	cRest = substr(cText,nStart + 1,len(cText) - nStart)
	nPos = substr(cRest,cWhat)
	if nPos = 0
		return -1
	ok
	return nStart + nPos - 1

func closing oArgs

	if not canDiscard()
		oArgs.Cancel = True
	ok
