# the checks of TodoList.ring: run with  ring TodoList.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

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
