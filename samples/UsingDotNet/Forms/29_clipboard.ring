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

uiRun(oForm)

# --------------------------------------------------------------------------

func copyText
	oClipboard = new Clipboard()
	oClipboard.SetText(oEdit.Text)

func pasteText
	# (a method call on a new object on the right side of an attribute assignment loses the assignment: use a variable)
	oClipboard = new Clipboard()
	cText = oClipboard.GetText(NULL)
	oPasted.Text = cText
