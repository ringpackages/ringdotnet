# Anchor and dock: controls follow the size of the form

load "dotnet.ring"
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

uiRun(oForm)

# --------------------------------------------------------------------------
