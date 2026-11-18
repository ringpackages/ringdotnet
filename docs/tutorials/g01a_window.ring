# Tutorial 11, step 1: the smallest window
load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()                       # Windows Forms needs the desktop runtime: call it first
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("My first window",320,120)

uiTest(oForm,"dnAssert('the title',oForm.Text,'My first window')")
uiRun(oForm)                         # show the window and wait until the user closes it
uiEnd()
