# A grid of labels in a table layout panel

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Table layout",300,200)
oTable = new TableLayoutPanel() {
	Dock = "Fill"
	ColumnCount = 3
	RowCount = 3
}
for nRow = 1 to 3
	for nColumn = 1 to 3
		oCell = new Label() {
			Text = "" + (nRow * nColumn)
			Dock = "Fill"
			TextAlign = "MiddleCenter"
		}
		oTable.Controls.Add([ :control = oCell, :column = nColumn - 1, :row = nRow - 1 ])
	next
next
oForm.Controls.Add(oTable)

uiRun(oForm)
