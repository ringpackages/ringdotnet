# A grid of labels in a table layout panel

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")


oForm = uiForm("Table layout",300,200)
oTable = new TableLayoutPanel()
oTable.Dock = "Fill"
oTable.ColumnCount = 3
oTable.RowCount = 3
for nRow = 1 to 3
	for nColumn = 1 to 3
		oCell = new Label()
		oCell.Text = "" + (nRow * nColumn)
		oCell.Dock = "Fill"
		oCell.TextAlign = "MiddleCenter"
		oTable.Controls.Add_3(oCell,nColumn - 1,nRow - 1)
	next
next
oForm.Controls.Add(oTable)

uiTest(oForm,"dnAssert('9 cells',oTable.Controls.Count,9) dnAssert('cell position',oTable.GetRow(oTable.Controls.Item(5)),1)")
uiRun(oForm)
uiEnd()
