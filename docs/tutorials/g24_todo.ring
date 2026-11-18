# Tutorial 24: a project - a to-do list that remembers its tasks (Windows Forms + JSON + files)
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Text.Json"
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = ""
oNew = ""
oTasks = ""
oStatus = ""
cFile = ""
lLoading = False

func main
	# the tasks are saved here (a test uses a temporary file)
	cFile = new Path().Combine([new Path().GetTempPath(),"tutorial24-tasks.json"])
	if uiSelfTest()
		cFile = new Path().Combine([new Path().GetTempPath(),"tutorial24-test.json"])
		if new File().Exists(cFile)
			new File().Delete(cFile)
		ok
	ok

	oForm = uiForm("My tasks",360,320)

	# The window: a text box and a button on top, the list in the middle, a status line at the bottom.
	# (The control that fills is added FIRST: see tutorial 13.)
	oTasks = new CheckedListBox() {
		Dock = "Fill"
		CheckOnClick = True
		setMouseUpEvent("tasksChanged()")           # after a click the state of the item is up to date
	}
	oForm.Controls.Add(oTasks)
	oTop = uiPanel(oForm,0,0,360,36)
	oTop.Dock = "Top"
	oNew = uiTextBox(oTop,8,6,230,24)
	uiButton(oTop,"Add",246,5,50,26,"addTask()")
	uiButton(oTop,"Remove",300,5,56,26,"removeTask()")
	oStatus = uiLabel(oForm,"",0,0,360,22)
	oStatus.Dock = "Bottom"

	loadTasks()
	refreshStatus()

	oForm.setFormClosingEvent("saveTasks()")
	uiTest(oForm,"selfTest()")
	uiRun(oForm)
	uiEnd()

func addTask
	cText = trim(oNew.Text)
	if cText = ""
		return
	ok
	oTasks.Items.Add([ :item = cText, :isChecked = False ])
	oNew.Text = ""
	saveTasks()
	refreshStatus()

func removeTask
	nIndex = oTasks.SelectedIndex
	if nIndex >= 0
		oTasks.Items.RemoveAt(nIndex)
		saveTasks()
		refreshStatus()
	ok

func tasksChanged
	saveTasks()
	refreshStatus()

func refreshStatus
	nDone = oTasks.CheckedItems.Count
	oStatus.Text = "  " + nDone + " of " + oTasks.Items.Count + " done"

# ---------------------------------------------------------------- saving and loading (JSON: [[1 or 0, "text"], ...])
# Note: the number comes FIRST. A list like [["Buy milk",1]] (a list of [text, value] pairs) passed alone to a method is read as
# NAMED ARGUMENTS ( :name = value ), so JsonSerializer.Serialize would look for a parameter called "Buy milk".

func saveTasks
	if lLoading
		return
	ok
	aList = []
	for nIndex = 0 to oTasks.Items.Count - 1
		aList + [oTasks.GetItemChecked(nIndex),oTasks.Items.Item(nIndex)]      # [done, text]: see the note about pairs
	next
	cJson = new JsonSerializer().Serialize(aList)
	new File().WriteAllText([ :path = cFile, :contents = cJson ])

func loadTasks
	if not new File().Exists(cFile)
		return
	ok
	lLoading = True
	oDocument = new JsonDocument().Parse(new File().ReadAllText(cFile))
	oRoot = oDocument.RootElement
	for nIndex = 0 to oRoot.GetArrayLength() - 1
		oTask = oRoot.Item(nIndex)
		oTasks.Items.Add([ :item = oTask.Item(1).GetString(), :isChecked = oTask.Item(0).GetInt32() = 1 ])
	next
	oDocument.Dispose()
	lLoading = False

func selfTest
	oNew.Text = "Buy milk"
	addTask()
	oNew.Text = "Write the tutorial"
	addTask()
	oNew.Text = "   "
	addTask()                                         # blank: ignored
	dnAssert("two tasks",oTasks.Items.Count,2)
	oTasks.SetItemChecked(0,True)
	saveTasks()
	refreshStatus()
	dnAssert("status",oStatus.Text,"  1 of 2 done")
	# the file holds the tasks
	dnAssert("saved as JSON",new File().ReadAllText(cFile),'[[1,"Buy milk"],[0,"Write the tutorial"]]')
	# a second load shows the same tasks
	oTasks.Items.Clear()
	loadTasks()
	dnAssert("loaded again",oTasks.Items.Count,2)
	dnAssert("the checked state",oTasks.GetItemChecked(0),True)
	oTasks.SelectedIndex = 1
	removeTask()
	dnAssert("removed",oTasks.Items.Count,1)
	new File().Delete(cFile)
