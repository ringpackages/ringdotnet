# A list box: add, remove and the selected item

load "dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("List box",320,260)
oEdit = uiTextBox(oForm,15,12,160,26)
uiButton(oForm,"Add",185,10,60,28,"addItem()")
uiButton(oForm,"Remove",250,10,60,28,"removeItem()")
oList = uiListBox(oForm,15,48,290,150)
oSelected = uiLabel(oForm,"",15,205,290,24)
oList.setSelectedIndexChangedEvent("oSelected.Text = 'Selected: ' + oList.Text")

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func addItem
	if trim(oEdit.Text) != ""
		oList.Items.Add(oEdit.Text)
		oEdit.Text = ""
	ok

func removeItem
	if oList.SelectedIndex >= 0
		oList.Items.RemoveAt(oList.SelectedIndex)
	ok

func selfTest
	for cName in ["red","green","blue"]
		oEdit.Text = cName
		addItem()
	next
	dnAssert("three items",oList.Items.Count,3)
	oList.SelectedIndex = 1
	dnAssert("selected text",oSelected.Text,"Selected: green")
	removeItem()
	dnAssert("removed",oList.Items.Count,2)
