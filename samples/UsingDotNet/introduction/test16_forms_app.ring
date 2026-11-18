load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

# A small to-do window. The sample drives itself (Shown event), see demo_todo.ring for the interactive version.
oForm = new Form() {
	Text = "To-do list"
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
}

oAdd.setClickEvent("addItem()")

# the automatic part: type three tasks, click Add, then close
oForm.setShownEvent("autoPlay()")
new Application().Run(oForm)
? "Final list : " + list2str(oList.Items.toList())

func addItem
	if trim(oInput.Text) != ""
		oList.Items.Add(oInput.Text)
		oInput.Text = ""
		oStatus.Text = string(oList.Items.Count) + " items"
	ok

func autoPlay
	for cTask in ["buy milk","write Ring code","call .NET"]
		oInput.Text = cTask
		oAdd.PerformClick()
	next
	? "Status     : " + oStatus.Text
	oForm.Close()
