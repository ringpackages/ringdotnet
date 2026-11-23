# Key events: KeyDown and KeyPress

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Keyboard",340,140)
oForm.KeyPreview = True
oLast = uiLabel(oForm,"Press a key",15,20,300,28)
oLast.Font = uiFont("Segoe UI",14,true)
oChars = uiLabel(oForm,"",15,60,300,24)
oForm {
	setKeyDownEvent("keyDown(aDotNetArgs[2].KeyCode)")
	setKeyPressEvent("keyPress(aDotNetArgs[2].KeyChar)")
}

uiRun(oForm)

# --------------------------------------------------------------------------

func keyDown cKey

	oLast.Text = "KeyDown: " + cKey

func keyPress cChar

	oChars.Text += cChar
