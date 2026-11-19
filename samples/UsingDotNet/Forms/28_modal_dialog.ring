# A modal dialog form that returns a value

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oDialog = ""	# globals of the dialog (the code of its events runs outside the function that builds it)
oBox = ""
oOk = ""
oForm = uiForm("Main window",320,140)
oResult = uiLabel(oForm,"No name yet",20,70,280,24)
uiButton(oForm,"Ask for a name...",20,20,150,32,"askName()")

uiRun(oForm)

# --------------------------------------------------------------------------

# builds a small dialog; returns the text when OK was pressed, "" otherwise
func askNameDialog cPreset
	# (global variables: the code of an event runs outside this function)
	oDialog = uiForm("What is your name?",300,120)
	oDialog {
		FormBorderStyle = "FixedDialog"
		StartPosition = "CenterParent"
	}
	oBox = uiTextBox(oDialog,15,15,260,26)
	oBox.Text = cPreset
	oOk = uiButton(oDialog,"OK",110,60,80,30,"")
	oOk.DialogResult = "OK"
	oDialog.AcceptButton = oOk
	if uiSelfTest()
		# in a test the dialog confirms itself as soon as it is shown
		oDialog.setShownEvent("oOk.PerformClick()")
	ok
	if oDialog.ShowDialog(NULL) = "OK"
		return oBox.Text
	ok
	return ""

func askName
	cName = askNameDialog("")
	if cName != ""
		oResult.Text = "Hello, " + cName + "!"
	ok
