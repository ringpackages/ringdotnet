# A data grid bound to a DataTable

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

using { "System.Data" }
oTable = new DataTable()
oTable.Columns.Add([ :columnName = "Name", :type = "System.String" ])
oTable.Columns.Add([ :columnName = "Age", :type = "System.Int32" ])
oTable {
	Rows.Add(["Ann",31])
	Rows.Add(["Bob",17])
	Rows.Add(["Cy",45])
}
oForm = uiForm("Data grid",340,200)
oGrid = new DataGridView() {
	Dock = "Fill"
	DataSource = oTable
	ReadOnly = True
	AllowUserToAddRows = False
}
oForm.Controls.Add(oGrid)

uiRun(oForm)

# --------------------------------------------------------------------------
