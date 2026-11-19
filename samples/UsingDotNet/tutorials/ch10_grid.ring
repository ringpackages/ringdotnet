# editing a grid - DataGridView with typed columns (text, check box, combo box), a read-only total, cell events and a grand total
load "dotnet.ring"
using {
	"System"
	"System.Drawing"
	"System.Windows.Forms"
}

# controls that the event code uses are global variables
oForm = ""
oGrid = ""
oSum = ""

func main
	oForm = uiForm("Order",560,320)
	oGrid = new DataGridView()
	oGrid.Location = new Point(15,15)
	oGrid.Size = new Size(520,200)
	oGrid.AllowUserToAddRows = False
	oGrid.RowHeadersVisible = False

	# The columns have TYPES: a text column, a check box column, a combo box column. The user edits each in the way that fits it.
	addTextColumn("Item","Item",150,False)
	addTextColumn("Qty","Quantity",70,False)
	addTextColumn("Price","Price",70,False)
	oCheck = new DataGridViewCheckBoxColumn()
	oCheck.Name = "Express"
	oCheck.HeaderText = "Express"
	oCheck.Width = 70
	oGrid.Columns.Add(oCheck)
	oCombo = new DataGridViewComboBoxColumn()
	oCombo.Name = "Size"
	oCombo.HeaderText = "Size"
	oCombo.Width = 80
	for cSize in [ "Small","Medium","Large" ]
		oCombo.Items.Add(cSize)
	next
	oGrid.Columns.Add(oCombo)
	addTextColumn("Total","Total",70,True)                 # read only: the program fills it

	# a rows is made with the values of the cells, in the order of the columns
	oGrid.Rows.Add(["Pens",10,2.5,False,"Small",""])
	oGrid.Rows.Add(["Paper",4,6,True,"Large",""])
	oGrid.Rows.Add(["Glue",3,4,False,"Medium",""])
	oForm.Controls.Add(oGrid)

	oSum = uiLabel(oForm,"",15,230,400,24)
	uiButton(oForm,"Add a row",430,226,105,30,"addRow()")

	# CellValueChanged runs after a cell was changed: the event arguments have the number of the row (RowIndex) and of the column.
	oGrid.setCellValueChangedEvent("rowChanged(aDotNetArgs[2].RowIndex)")
	# a combo box and a check box cell keep the editing state until the cell loses the focus: this makes the change count at once
	oGrid.setCurrentCellDirtyStateChangedEvent("oGrid.CommitEdit('CurrentCellChange')")

	for i = 0 to oGrid.Rows.Count - 1
		rowChanged(i)
	next
	uiRun(oForm)

func addTextColumn cName,cHeader,nWidth,lReadOnly
	oColumn = new DataGridViewTextBoxColumn()
	oColumn.Name = cName
	oColumn.HeaderText = cHeader
	oColumn.Width = nWidth
	oColumn.ReadOnly = lReadOnly
	oGrid.Columns.Add(oColumn)

func addRow
	oGrid.Rows.Add(["New item",1,1,False,"Small",""])

# a cell by row and column name (the value of a cell can be text, a number, a boolean or empty)
func cellText nRow,cColumn
	return "" + oGrid.Rows.Item(nRow).Cells.Item(cColumn).Value

# the number of a cell: a number that was typed arrives as a text, and a text that is not a number counts as 0. (A conversion that fails
# raises a Ring error, which try / catch turns into the answer 0.)
func cellNumber nRow,cColumn
	cText = trim(cellText(nRow,cColumn))
	nNumber = 0
	try
		nNumber = 0 + cText
	catch
		nNumber = 0
	done
	return nNumber

# the total of a row: quantity x price, plus 5 for express, and 10 percent more for the size Large. Then the grand total.
func rowChanged nRow
	if nRow < 0
		return
	ok
	nTotal = cellNumber(nRow,"Qty") * cellNumber(nRow,"Price")
	if oGrid.Rows.Item(nRow).Cells.Item("Express").Value = True
		nTotal += 5
	ok
	if cellText(nRow,"Size") = "Large"
		nTotal = nTotal * 1.1
	ok
	cNew = shortNumber(nTotal)
	if cellText(nRow,"Total") != cNew
		oGrid.Rows.Item(nRow).Cells.Item("Total").Value = cNew      # this raises CellValueChanged again, but the text is the same now
	ok
	showSum()

# two decimals at most, and no decimals for a whole number: 55.00000000000001 -> "55", 31.9 -> "31.90"
func shortNumber nValue
	nRounded = floor(nValue * 100 + 0.5) / 100
	if nRounded = floor(nRounded)
		return "" + floor(nRounded)
	ok
	return "" + nRounded

func showSum
	nSum = 0
	for i = 0 to oGrid.Rows.Count - 1
		nSum += cellNumber(i,"Total")
	next
	oSum.Text = "Rows: " + oGrid.Rows.Count + ", the total is " + nSum
