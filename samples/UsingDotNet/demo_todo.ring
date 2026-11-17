load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")

# Interactive to-do window (run it with: ring demo_todo.ring)
oForm = new Form()
oForm.Text = "To-do list (Ring + .NET)"
oForm.ClientSize = new Size(320,220)
oForm.StartPosition = "CenterScreen"

oInput = new TextBox()
oInput.Location = new Point(10,10)
oInput.Width = 200
oAdd = new Button()
oAdd.Text = "Add"
oAdd.Location = new Point(220,9)
oList = new ListBox()
oList.Location = new Point(10,45)
oList.Size = new Size(300,140)
oStatus = new Label()
oStatus.Location = new Point(10,195)
oStatus.Width = 300
oStatus.Text = "0 items"

oForm.Controls.Add(oInput)
oForm.Controls.Add(oAdd)
oForm.Controls.Add(oList)
oForm.Controls.Add(oStatus)
oForm.AcceptButton = oAdd
oAdd.setClickEvent("addItem()")
oList.setDoubleClickEvent("removeItem()")

new Application().Run(oForm)

func addItem
	if trim(oInput.Text) != ""
		oList.Items.Add(oInput.Text)
		oInput.Text = ""
		oStatus.Text = string(oList.Items.Count) + " items (double-click an item to remove it)"
	ok
	oInput.Focus()

func removeItem
	if oList.SelectedIndex >= 0
		oList.Items.RemoveAt(oList.SelectedIndex)
		oStatus.Text = string(oList.Items.Count) + " items"
	ok
