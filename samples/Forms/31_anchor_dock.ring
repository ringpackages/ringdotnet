# Anchor and dock: controls follow the size of the form

load "dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Anchoring",360,220)
oTop = uiLabel(oForm,"Docked to the top",0,0,360,28)
oTop {
	Dock = "Top"
	BackColor = uiColor("LightSteelBlue")
	TextAlign = "MiddleCenter"
}
oBox = uiTextBox(oForm,15,40,330,120)
oBox {
	Multiline = True
	Anchor = "Top, Bottom, Left, Right"
}
oOk = uiButton(oForm,"OK",270,175,75,30,"")
oOk.Anchor = "Bottom, Right"

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func selfTest
	nBefore = oBox.Height
	oForm.ClientSize = new Size(460,320)
	dnAssert("the docked label stays on top",oTop.Top,0)
	dnAssert("the text box grew",oBox.Height > nBefore,True)
	dnAssert("the button moved right",oOk.Left > 270,True)
