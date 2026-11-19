# the checks of ch12_todo.ring: run with  ring ch12_todo.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

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
