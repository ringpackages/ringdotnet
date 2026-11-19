# a small text editor - menus, a status bar, files and a message when you quit with unsaved text
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = ""
oEditor = ""
oStatus = ""
cFileName = ""
lChanged = False

func main
	oForm = uiForm("Tiny editor",560,360)

	# The editor fills the window. Add the control that fills FIRST: Windows Forms docks the controls added later
	# (the menu and the status bar) before it, so the editor gets what is left.
	oEditor = uiMemo(oForm,0,0,560,338)
	oEditor {
		Dock = "Fill"
		Font = new Font("Consolas",11)
		setTextChangedEvent("textChanged()")
	}

	# A menu is a list: [title, [ [item, code], ... ]]  ("-" is a separator)
	uiMenu(oForm,[
		["File",[["New","newFile()"],["Open...","openFile()"],["Save","saveFile()"],["-",""],["Exit","oForm.Close()"]]],
		["Help",[["About","uiMessage('Tiny editor - made with Ring and .NET','About')"]]]
	])

	# A status bar at the bottom
	oStatus = new StatusStrip()
	oLabel = new ToolStripStatusLabel()
	oLabel.Text = "Ready"
	oStatus.Items.Add(oLabel)
	oForm.Controls.Add(oStatus)

	uiRun(oForm)

func textChanged
	lChanged = True
	oStatus.Items.Item(0).Text = "" + len(oEditor.Text) + " characters (not saved)"

func newFile
	oEditor.Text = ""
	cFileName = ""
	lChanged = False
	oForm.Text = "Tiny editor"

func openFile
	cChosen = uiOpenFileName("Open a text file","Text files|*.txt|All files|*.*")
	if cChosen = ""
		return
	ok
	loadFile(cChosen)

func loadFile cPath
	# (a method of a new object on the right side of an assignment to a property loses the assignment: use a variable)
	cContent = new File().ReadAllText(cPath)
	oEditor.Text = cContent
	cFileName = cPath
	lChanged = False
	cShortName = new Path().GetFileName(cPath)
	oForm.Text = "Tiny editor - " + cShortName
	oStatus.Items.Item(0).Text = "Opened " + cPath

func saveFile
	if cFileName = ""
		cFileName = uiSaveFileName("Save the text","Text files|*.txt|All files|*.*")
		if cFileName = ""
			return
		ok
	ok
	new File().WriteAllText([ :path = cFileName, :contents = oEditor.Text ])
	lChanged = False
	cShortName = new Path().GetFileName(cFileName)
	oForm.Text = "Tiny editor - " + cShortName
	oStatus.Items.Item(0).Text = "Saved " + cFileName
