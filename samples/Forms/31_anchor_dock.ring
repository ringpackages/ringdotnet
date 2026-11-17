# Anchor and dock: controls follow the size of the form

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")


oForm = uiForm("Anchoring",360,220)
oTop = uiLabel(oForm,"Docked to the top",0,0,360,28)
oTop.Dock = "Top"
oTop.BackColor = uiColor("LightSteelBlue")
oTop.TextAlign = "MiddleCenter"
oBox = uiTextBox(oForm,15,40,330,120)
oBox.Multiline = 1
oBox.Anchor = "Top, Bottom, Left, Right"
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
	dnAssert("the text box grew",oBox.Height > nBefore,1)
	dnAssert("the button moved right",oOk.Left > 270,1)
