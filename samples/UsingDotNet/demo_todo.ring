load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

# Interactive to-do window (run it with: ring demo_todo.ring)
oForm = new Form() {
	Text = "To-do list (Ring + .NET)"
	ClientSize = new Size(320,220)
	StartPosition = "CenterScreen"
}

oInput = new TextBox() {
	Location = new Point(10,10)
	Width = 200
}
oAdd = new Button() {
	Text = "Add"
	Location = new Point(220,9)
}
oList = new ListBox() {
	Location = new Point(10,45)
	Size = new Size(300,140)
}
oStatus = new Label() {
	Location = new Point(10,195)
	Width = 300
	Text = "0 items"
}

oForm {
	Controls.Add(oInput)
	Controls.Add(oAdd)
	Controls.Add(oList)
	Controls.Add(oStatus)
	AcceptButton = oAdd
}
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
