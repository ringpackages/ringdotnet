# A check box changes a label

load "dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Check box",300,120)
oCheck = uiCheckBox(oForm,"Enable notifications",20,15,240,24,"changed()")
oState = uiLabel(oForm,"Notifications are off",20,55,240,24)

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func changed
	if oCheck.Checked
		oState.Text = "Notifications are on"
	else
		oState.Text = "Notifications are off"
	ok

func selfTest
	oCheck.Checked = True
	changed()
	dnAssert("on",oState.Text,"Notifications are on")
	oCheck.Checked = False
	changed()
	dnAssert("off",oState.Text,"Notifications are off")
