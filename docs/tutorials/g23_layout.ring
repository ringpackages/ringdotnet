# Tutorial 23: layout and richer controls - SplitContainer, TabControl, TableLayoutPanel, DataGridView with a filter
load "dotnetlib.ring"
dnUseDesktop()
using {
	"System.Data"
	"System.Drawing"
	"System.Windows.Forms"
}

# the controls that event code uses
oForm = ""
oList = ""
oNameValue = ""
oCityValue = ""
oCountValue = ""
oGrid = ""
oView = ""
aCustomers = [["Ann","Cairo"],["Bob","Oslo"],["Cy","Tokyo"]]

func main
	oForm = uiForm("Customers",620,300)

	# A SplitContainer has two panels with a bar between them that the user can drag.
	oSplit = new SplitContainer() {
		Dock = "Fill"
	}
	oForm.Controls.Add(oSplit)
	oSplit.SplitterDistance = 150                  # set it after the control is in the form and has its real size

	# Left panel: the list of customers, filling its panel
	oList = new ListBox() {
		Dock = "Fill"
	}
	for aCustomer in aCustomers
		oList.Items.Add(aCustomer[1])
	next
	oSplit.Panel1.Controls.Add(oList)

	# Right panel: tabs
	oTabs = new TabControl() {
		Dock = "Fill"
	}
	oSplit.Panel2.Controls.Add(oTabs)
	oDetails = new TabPage() {
		Text = "Details"
	}
	oOrders = new TabPage() {
		Text = "Orders"
	}
	oTabs.TabPages.Add(oDetails)
	oTabs.TabPages.Add(oOrders)

	# Details page: a table with two columns, labels left and values right
	oTable = new TableLayoutPanel() {
		Dock = "Top"
		ColumnCount = 2
		RowCount = 3
		Height = 90
	}
	oNameValue = addRow(oTable,0,"Name")
	oCityValue = addRow(oTable,1,"City")
	oCountValue = addRow(oTable,2,"Orders")
	oDetails.Controls.Add(oTable)

	# Orders page: a grid showing a DataTable through a DataView that can filter
	oData = new DataTable()
	oData.Columns.Add([ :columnName = "Customer", :type = "System.String" ])
	oData.Columns.Add([ :columnName = "Item", :type = "System.String" ])
	oData.Columns.Add([ :columnName = "Quantity", :type = "System.Int32" ])
	oData {
		Rows.Add(["Ann","Pens",12])
		Rows.Add(["Ann","Paper",5])
		Rows.Add(["Bob","Ink",2])
		Rows.Add(["Cy","Pens",30])
		Rows.Add(["Cy","Glue",4])
		Rows.Add(["Cy","Tape",9])
	}
	oView = oData.DefaultView
	oGrid = new DataGridView() {
		Dock = "Fill"
		DataSource = oView
		ReadOnly = True
		AllowUserToAddRows = False
	}
	oOrders.Controls.Add(oGrid)

	oList.setSelectedIndexChangedEvent("customerChosen()")
	oList.SelectedIndex = 0

	uiTest(oForm,"selfTest()")
	uiRun(oForm)
	uiEnd()

# a label and a value in one row of the table
func addRow oTable, nRow, cTitle
	oTitle = new Label() {
		Text = cTitle
		Dock = "Fill"
		TextAlign = "MiddleLeft"
	}
	oValue = new Label() {
		Dock = "Fill"
		TextAlign = "MiddleLeft"
		Font = new Font("Segoe UI",11)
		ForeColor = new Color().SteelBlue
	}
	oTable.Controls.Add([ :control = oTitle, :column = 0, :row = nRow ])
	oTable.Controls.Add([ :control = oValue, :column = 1, :row = nRow ])
	return oValue

func customerChosen
	nIndex = oList.SelectedIndex + 1
	if nIndex < 1
		return
	ok
	cName = aCustomers[nIndex][1]
	oNameValue.Text = cName
	oCityValue.Text = aCustomers[nIndex][2]
	oView.RowFilter = "Customer = '" + cName + "'"          # the grid shows only this customer's rows
	oCountValue.Text = "" + oView.Count

func selfTest
	oList.SelectedIndex = 2
	dnAssert("details follow the list",oNameValue.Text,"Cy")
	dnAssert("the city",oCityValue.Text,"Tokyo")
	dnAssert("Cy has three orders",oGrid.Rows.Count,3)
	oList.SelectedIndex = 1
	dnAssert("Bob has one order",oGrid.Rows.Count,1)
