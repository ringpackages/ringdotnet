# Radio buttons in a group box

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")


oForm = uiForm("Radio buttons",300,200)
oGroup = new GroupBox()
oGroup.Text = "Size"
oGroup.Location = new Point(15,10)
oGroup.Size = new Size(260,110)
oForm.Controls.Add(oGroup)
aRadios = []
nY = 22
for cSize in ["Small","Medium","Large"]
	oRadio = new RadioButton()
	oRadio.Text = cSize
	oRadio.Location = new Point(15,nY)
	oRadio.Size = new Size(120,24)
	oRadio.setClickEvent("show()")
	oGroup.Controls.Add(oRadio)
	aRadios + oRadio
	nY += 26
next
oChoice = uiLabel(oForm,"Choose a size",15,135,260,24)
aRadios[2].Checked = 1

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func show
	for oRadio in aRadios
		if oRadio.Checked
			oChoice.Text = "You chose " + oRadio.Text
		ok
	next

func selfTest
	aRadios[3].Checked = 1
	show()
	dnAssert("large",oChoice.Text,"You chose Large")
	dnAssert("only one radio is checked",aRadios[2].Checked + aRadios[3].Checked + aRadios[1].Checked,1)
