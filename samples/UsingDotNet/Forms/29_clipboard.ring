# Copy text to the clipboard and read it back

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Clipboard",320,130)
oEdit = uiTextBox(oForm,15,15,280,26)
oEdit.Text = "Copied from Ring"
uiButton(oForm,"Copy",15,55,80,30,"copyText()")
uiButton(oForm,"Paste",105,55,80,30,"pasteText()")
oPasted = uiLabel(oForm,"",15,95,280,24)

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func copyText
	oClipboard = new Clipboard()
	oClipboard.SetText(oEdit.Text)

func pasteText
	# (a method call on a new object can't be on the right side of an attribute assignment: use a variable)
	oClipboard = new Clipboard()
	cText = oClipboard.GetText(NULL)
	oPasted.Text = cText

func selfTest
	oForm.Controls.Item(1).PerformClick()
	oForm.Controls.Item(2).PerformClick()
	dnAssert("clipboard round trip",oPasted.Text,"Copied from Ring")
