# A split container with two panels

load "dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Split",420,240)
oSplit = new SplitContainer()
oSplit.Dock = "Fill"
oForm.Controls.Add(oSplit)
oSplit.SplitterDistance = 140
oList = new ListBox() {
	Dock = "Fill"
	Items.Add("One")
	Items.Add("Two")
}
oSplit.Panel1.Controls.Add(oList)
oText = new TextBox() {
	Dock = "Fill"
	Multiline = True
}
oSplit.Panel2.Controls.Add(oText)
oList.setSelectedIndexChangedEvent("oText.Text = 'You selected ' + oList.Text")

uiTest(oForm,"oList.SelectedIndex = 1 dnAssert('right panel',oText.Text,'You selected Two') dnAssert('splitter',oSplit.SplitterDistance,140)")
uiRun(oForm)
uiEnd()
