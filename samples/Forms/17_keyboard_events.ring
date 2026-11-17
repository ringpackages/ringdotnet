# Key events: KeyDown and KeyPress

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Keyboard",340,140)
oForm.KeyPreview = 1
oLast = uiLabel(oForm,"Press a key",15,20,300,28)
oLast.Font = uiFont("Segoe UI",14,true)
oChars = uiLabel(oForm,"",15,60,300,24)
oForm.setKeyDownEvent("keyDown(aDotNetArgs[2].KeyCode)")
oForm.setKeyPressEvent("keyPress(aDotNetArgs[2].KeyChar)")

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func keyDown cKey
	oLast.Text = "KeyDown: " + cKey

func keyPress cChar
	oChars.Text += cChar

func selfTest
	keyDown("Enter")
	keyPress("R")
	keyPress("i")
	dnAssert("key name",oLast.Text,"KeyDown: Enter")
	dnAssert("typed characters",oChars.Text,"Ri")
