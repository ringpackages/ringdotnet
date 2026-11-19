# Address book - a DataGridView bound to a DataTable, search, edit, delete and save/load as XML

load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Data"
	"System.Drawing"
	"System.Windows.Forms"
}

cFile = ""
if uiSelfTest()
	cFile = new Path().Combine([new Path().GetTempPath(),"addressbook_selftest.xml"])
else
	cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet_addressbook.xml"])
ok

oTable = new DataTable()
oTable.TableName = "Contacts"
oTable.Columns.Add([ :columnName = "Name", :type = "System.String" ])
oTable.Columns.Add([ :columnName = "Phone", :type = "System.String" ])
oTable.Columns.Add([ :columnName = "City", :type = "System.String" ])

oForm = uiForm("Address book",600,420)
uiLabel(oForm,"Search",10,14,50,22)
oSearch = uiTextBox(oForm,65,11,200,26)
oSearch.setTextChangedEvent("applyFilter()")
oGrid = new DataGridView() {
	Location = new Point(10,45)
	Size = new Size(580,250)
	AllowUserToAddRows = False
	ReadOnly = True
	SelectionMode = "FullRowSelect"
	DataSource = oTable
}
oForm.Controls.Add(oGrid)
uiLabel(oForm,"Name",10,312,50,22)
oName = uiTextBox(oForm,65,309,150,26)
uiLabel(oForm,"Phone",230,312,50,22)
oPhone = uiTextBox(oForm,285,309,130,26)
uiLabel(oForm,"City",430,312,40,22)
oCity = uiTextBox(oForm,470,309,120,26)
uiButton(oForm,"Add",65,350,80,30,"addContact()")
uiButton(oForm,"Delete selected",155,350,120,30,"deleteSelected()")
uiButton(oForm,"Save",285,350,70,30,"saveBook()")
uiButton(oForm,"Load",365,350,70,30,"loadBook()")
oCount = uiLabel(oForm,"",450,357,140,22)
oMessage = uiLabel(oForm,"",10,392,580,22)
if new File().Exists(cFile) and not uiSelfTest()
	loadBook()
ok
showCount()

uiRun(oForm)

# --------------------------------------------------------------------------

func showCount
	oCount.Text = string(oTable.DefaultView.Count) + " of " + oTable.Rows.Count + " contacts"

func addContact
	if trim(oName.Text) = ""
		return
	ok
	oTable.Rows.Add([trim(oName.Text),trim(oPhone.Text),trim(oCity.Text)])
	oName.Text = ""
	oPhone.Text = ""
	oCity.Text = ""
	showCount()

func deleteSelected
	if oGrid.SelectedRows.Count > 0
		nIndex = oGrid.SelectedRows.Item(0).Index
		oTable.DefaultView.Delete(nIndex)
		showCount()
	ok

func applyFilter
	cText = trim(oSearch.Text)
	if cText = ""
		oTable.DefaultView.RowFilter = ""
	else
		# quotes in the text are doubled for the filter expression
		cText = substr(cText,"'","''")
		oTable.DefaultView.RowFilter = "Name LIKE '%" + cText + "%' OR City LIKE '%" + cText + "%'"
	ok
	showCount()

func saveBook
	try
		oTable.WriteXml(cFile)
		oMessage.Text = "Saved " + oTable.Rows.Count + " contacts to " + cFile
	catch
		oMessage.Text = "Can't save: " + cCatchError
	done

func loadBook
	if not new File().Exists(cFile)
		oMessage.Text = "Nothing to load yet: save the address book first (" + cFile + ")"
		return
	ok
	try
		oTable.Clear()
		oTable.ReadXml(cFile)
		oMessage.Text = "Loaded " + oTable.Rows.Count + " contacts"
	catch
		oMessage.Text = "Can't load: " + cCatchError
	done
	showCount()
