# Type in the text box: the label follows (TextChanged event)

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Echo",320,120)
oEdit = uiTextBox(oForm,20,15,270,26)
oEcho = uiLabel(oForm,"",20,55,270,26)
oEdit.setTextChangedEvent("oEcho.Text = 'You typed: ' + oEdit.Text")

uiRun(oForm)
