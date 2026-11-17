# Address book - a DataGridView bound to a DataTable, search, edit, delete and save/load as XML

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System")
dnImport("System.IO")
dnImport("System.Data")
dnImport("System.Drawing")
dnImport("System.Windows.Forms")

cFile = ""
if uiSelfTest()
	cFile = new Path().Combine(new Path().GetTempPath(),"addressbook_selftest.xml")
else
	cFile = new Path().Combine(new Path().GetTempPath(),"ringdotnet_addressbook.xml")
ok

oTable = new DataTable()
oTable.TableName = "Contacts"
oTable.Columns.Add_2("Name","System.String")
oTable.Columns.Add_2("Phone","System.String")
oTable.Columns.Add_2("City","System.String")

oForm = uiForm("Address book",600,420)
uiLabel(oForm,"Search",10,14,50,22)
oSearch = uiTextBox(oForm,65,11,200,26)
oSearch.setTextChangedEvent("applyFilter()")
oGrid = new DataGridView()
oGrid.Location = new Point(10,45)
oGrid.Size = new Size(580,250)
oGrid.AllowUserToAddRows = 0
oGrid.ReadOnly = 1
oGrid.SelectionMode = "FullRowSelect"
oGrid.DataSource = oTable
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
showCount()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

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
	oTable.WriteXml(cFile)

func loadBook
	oTable.Clear()
	oTable.ReadXml(cFile)
	showCount()

func selfTest
	for aContact in [["Ann Lee","555-0101","Cairo"],["Bob Stone","555-0102","Oslo"],["Cy Young","555-0103","Cairo"]]
		oName.Text = aContact[1]
		oPhone.Text = aContact[2]
		oCity.Text = aContact[3]
		addContact()
	next
	dnAssert("three contacts",oTable.Rows.Count,3)
	dnAssert("grid shows them",oGrid.Rows.Count,3)
	dnAssert("fields are cleared",oName.Text,"")
	oSearch.Text = "cairo"
	dnAssert("filter by city",oGrid.Rows.Count,2)
	oSearch.Text = "stone"
	dnAssert("filter by name",oGrid.Rows.Item(0).Cells.Item(0).Value,"Bob Stone")
	oSearch.Text = ""
	dnAssert("no filter",oGrid.Rows.Count,3)
	oName.Text = ""
	addContact()
	dnAssert("an empty name is ignored",oTable.Rows.Count,3)
	saveBook()
	dnAssert("saved as xml",new File().Exists(cFile),1)
	oGrid.Rows.Item(1).Selected = 1
	deleteSelected()
	dnAssert("deleted",oTable.Rows.Count,2)
	loadBook()
	dnAssert("loaded again",oTable.Rows.Count,3)
	dnAssert("data is back",oTable.Rows.Item(1).Item("Name"),"Bob Stone")
	dnAssert("count text",oCount.Text,"3 of 3 contacts")
	new File().Delete(cFile)
