# Radio buttons in a group box

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Radio buttons",300,200)
oGroup = new GroupBox() {
	Text = "Size"
	Location = new Point(15,10)
	Size = new Size(260,110)
}
oForm.Controls.Add(oGroup)
aRadios = []
nY = 22
for cSize in ["Small","Medium","Large"]
	oRadio = new RadioButton() {
		Text = cSize
		Location = new Point(15,nY)
		Size = new Size(120,24)
		setClickEvent("show()")
	}
	oGroup.Controls.Add(oRadio)
	aRadios + oRadio
	nY += 26
next
oChoice = uiLabel(oForm,"Choose a size",15,135,260,24)
aRadios[2].Checked = True

uiRun(oForm)

# --------------------------------------------------------------------------

func show

	for oRadio in aRadios
		if oRadio.Checked
			oChoice.Text = "You chose " + oRadio.Text
		ok
	next
