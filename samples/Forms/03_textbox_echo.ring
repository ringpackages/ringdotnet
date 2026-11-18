# Type in the text box: the label follows (TextChanged event)

load "dotnet.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Echo",320,120)
oEdit = uiTextBox(oForm,20,15,270,26)
oEcho = uiLabel(oForm,"",20,55,270,26)
oEdit.setTextChangedEvent("oEcho.Text = 'You typed: ' + oEdit.Text")

uiTest(oForm,"oEdit.Text = 'Ring' dnAssert('echo',oEcho.Text,'You typed: Ring') oEdit.Text = '' dnAssert('empty',oEcho.Text,'You typed: ')")
uiRun(oForm)
uiEnd()
