load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

# A small to-do window. The sample drives itself (Shown event), see demo_todo.ring for the interactive version.
oForm = new Form()
oForm.Text = "To-do list"
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
