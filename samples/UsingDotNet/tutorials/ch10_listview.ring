# a list with columns - ListView in details view: columns, check boxes, sorting by a column header, removing the checked rows
load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

# controls and data that the event code uses are global variables
oForm = ""
oList = ""
oStatus = ""
aTasks = [ ["Write the report",2,"2030-03-14"], ["Call the bank",1,"2030-03-11"], ["Buy tea",3,"2030-03-12"], ["Book the room",1,"2030-03-20"], ["Back up the files",2,"2030-03-09"] ]
nSortColumn = -1                      # no column yet
lAscending = True

func main

	oForm = uiForm("Tasks",520,330)
	oList = new ListView()
	oList.Location = new Point(15,15)
	oList.Size = new Size(485,220)
	oList.View = "Details"                           # columns with titles (the other views: List, SmallIcon, LargeIcon, Tile)
	oList.FullRowSelect = True                       # a click selects the whole row, not only the first cell
	oList.GridLines = True
	oList.CheckBoxes = True                          # a check box in front of each row
	oList.Columns.Add([ :text = "Task", :width = 220 ])
	oList.Columns.Add([ :text = "Priority", :width = 80 ])
	oList.Columns.Add([ :text = "Due", :width = 120 ])
	# a click on a header: the event arguments (aDotNetArgs[2]) have the number of the column
	oList.setColumnClickEvent("sortBy(aDotNetArgs[2].Column)")
	oList.setItemCheckedEvent("showStatus()")
	oForm.Controls.Add(oList)

	uiButton(oForm,"Remove checked",15,248,140,30,"removeChecked()")
	oStatus = uiLabel(oForm,"",170,254,330,22)

	fillList()
	uiRun(oForm)

# the rows come from the Ring list aTasks: the list is the DATA and the ListView only shows it, so sorting means sorting the list
# and filling the view again
func fillList

	oList.Items.Clear()
	for aTask in aTasks
		oItem = new ListViewItem().@New([ :text = aTask[1] ])
		oItem.SubItems.Add("" + aTask[2])
		oItem.SubItems.Add(aTask[3])
		oList.Items.Add(oItem)
	next
	showStatus()

# sort by a column: the same column again turns the order around. A sort with a Ring function: a plain bubble sort on the column.
func sortBy nColumn

	if nColumn = nSortColumn
		lAscending = not lAscending
	else
		nSortColumn = nColumn
		lAscending = True
	ok
	nCount = len(aTasks)
	for i = 1 to nCount - 1
		for j = 1 to nCount - i
			if goesAfter(aTasks[j],aTasks[j + 1])
				aTemp = aTasks[j]
				aTasks[j] = aTasks[j + 1]
				aTasks[j + 1] = aTemp
			ok
		next
	next
	fillList()

# does the first row go after the second? The cells are compared as TEXT with strcmp (it gives a number: less than 0, 0 or more than 0),
# because the signs < and > compare numbers. Dates written as year-month-day sort correctly as text; the priority is a number, so it is
# written with the same number of digits ("2") and compares the same way.
func goesAfter aFirst,aSecond

	nColumn = nSortColumn + 1
	nResult = strcmp("" + aFirst[nColumn],"" + aSecond[nColumn])
	if lAscending
		return nResult > 0
	ok
	return nResult < 0

func removeChecked

	aKept = []
	for i = 1 to len(aTasks)
		if not oList.Items.Item(i - 1).Checked
			aKept + aTasks[i]
		ok
	next
	aTasks = aKept
	fillList()

# the number of checked rows: ask each row (the property Checked)
func checkedCount

	nChecked = 0
	for i = 0 to oList.Items.Count - 1
		if oList.Items.Item(i).Checked
			nChecked++
		ok
	next
	return nChecked

func showStatus

	oStatus.Text = "" + oList.Items.Count + " tasks, " + checkedCount() + " checked"
