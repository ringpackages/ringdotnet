# To-do list with check boxes, saved to a text file

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System")
dnImport("System.IO")
dnImport("System.Drawing")
dnImport("System.Windows.Forms")

cFile = new Path().Combine(new Path().GetTempPath(),"ringdotnet_todo.txt")
if uiSelfTest()
	cFile = new Path().Combine(new Path().GetTempPath(),"ringdotnet_todo_selftest.txt")
ok

oForm = uiForm("To-do list",360,420)
oInput = uiTextBox(oForm,10,10,250,26)
uiButton(oForm,"Add",268,9,80,28,"addTask()")
oList = new CheckedListBox()
oList.Location = new Point(10,46)
oList.Size = new Size(338,290)
oList.CheckOnClick = 1
# ItemCheck fires before the state changes, so the counters are refreshed after the mouse or key press
oList.setMouseUpEvent("updateInfo()")
oList.setKeyUpEvent("updateInfo()")
oForm.Controls.Add(oList)
uiButton(oForm,"Remove checked",10,345,120,28,"removeDone()")
uiButton(oForm,"Save",140,345,80,28,"saveTasks()")
oInfo = uiLabel(oForm,"",10,382,338,22)
oForm.AcceptButton = oForm.Controls.Item(1)
loadTasks()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func updateInfo
	nDone = oList.CheckedItems.Count
	oInfo.Text = string(oList.Items.Count) + " tasks, " + nDone + " done"

func addTask
	cTask = trim(oInput.Text)
	if cTask != ""
		oList.Items.Add_2(cTask,0)
		oInput.Text = ""
		updateInfo()
	ok

func removeDone
	for nIndex = oList.Items.Count - 1 to 0 step -1
		if oList.GetItemChecked(nIndex)
			oList.Items.RemoveAt(nIndex)
		ok
	next
	updateInfo()

# one line per task: "[x] text" or "[ ] text"
func saveTasks
	cText = ""
	for nIndex = 0 to oList.Items.Count - 1
		if oList.GetItemChecked(nIndex)
			cText += "[x] "
		else
			cText += "[ ] "
		ok
		cText += oList.Items.Item(nIndex) + nl
	next
	new File().WriteAllText(cFile,cText)

func loadTasks
	oList.Items.Clear()
	if new File().Exists(cFile)
		for cLine in str2list(new File().ReadAllText(cFile))
			cLine = trim(cLine)
			if len(cLine) > 4
				oList.Items.Add_2(substr(cLine,5),left(cLine,3) = "[x]")
			ok
		next
	ok
	updateInfo()

func selfTest
	if new File().Exists(cFile)
		new File().Delete(cFile)
	ok
	loadTasks()
	dnAssert("starts empty",oList.Items.Count,0)
	oInput.Text = "write Ring code"
	addTask()
	oInput.Text = "call .NET"
	addTask()
	oInput.Text = "   "
	addTask()
	dnAssert("two tasks (blank is ignored)",oList.Items.Count,2)
	oList.SetItemChecked(0,1)
	updateInfo()
	dnAssert("one task done",oList.CheckedItems.Count,1)
	dnAssert("info label",oInfo.Text,"2 tasks, 1 done")
	saveTasks()
	oList.Items.Clear()
	loadTasks()
	dnAssert("reloaded two tasks",oList.Items.Count,2)
	dnAssert("check state restored",oList.GetItemChecked(0),1)
	dnAssert("text restored",oList.Items.Item(1),"call .NET")
	removeDone()
	dnAssert("checked task removed",oList.Items.Count,1)
	dnAssert("the other one stays",oList.Items.Item(0),"call .NET")
	new File().Delete(cFile)
