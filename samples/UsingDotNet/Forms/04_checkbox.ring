# A check box changes a label

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Check box",300,120)
oCheck = uiCheckBox(oForm,"Enable notifications",20,15,240,24,"changed()")
oState = uiLabel(oForm,"Notifications are off",20,55,240,24)

uiRun(oForm)

# --------------------------------------------------------------------------

func changed
	if oCheck.Checked
		oState.Text = "Notifications are on"
	else
		oState.Text = "Notifications are off"
	ok
