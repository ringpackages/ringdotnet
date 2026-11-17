# A data grid bound to a DataTable

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


using { "System.Data" }
oTable = new DataTable()
oTable.Columns.Add@([ :columnName = "Name", :type = "System.String" ])
oTable.Columns.Add@([ :columnName = "Age", :type = "System.Int32" ])
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

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func selfTest
	dnAssert("three rows",oGrid.Rows.Count,3)
	dnAssert("two columns",oGrid.Columns.Count,2)
	dnAssert("cell value",oGrid.Rows.Item(1).Cells.Item(0).Value,"Bob")
	oGrid.Sort(oGrid.Columns.Item(1),"Descending")
	dnAssert("sorted by age",oGrid.Rows.Item(0).Cells.Item(0).Value,"Cy")
