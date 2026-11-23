# a form with many controls - text boxes, check box, combo box, list box, validation
load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

# controls that the event code uses are global variables
oForm = ""
oName = ""
oAge = ""
oCountry = ""
oNewsletter = ""
oResult = ""
oPeople = ""

func main

	oForm = uiForm("Registration",400,330)

	uiLabel(oForm,"Name",20,20,80,22)
	oName = uiTextBox(oForm,110,18,260,24)

	uiLabel(oForm,"Age",20,56,80,22)
	oAge = new NumericUpDown() {
		Location = new Point(110,54)
		Size = new Size(80,24)
		Minimum = 1
		Maximum = 120
		Value = 30
	}
	oForm.Controls.Add(oAge)

	uiLabel(oForm,"Country",20,92,80,22)
	oCountry = uiComboBox(oForm,110,90,180,["Egypt","Norway","Japan","Brazil"])
	oCountry.SelectedIndex = -1                        # nothing chosen yet

	oNewsletter = uiCheckBox(oForm,"Send me the newsletter",110,124,200,24,"")

	uiButton(oForm,"Register",110,158,100,30,"register()")
	oResult = uiLabel(oForm,"",20,196,360,22)

	uiLabel(oForm,"Registered people",20,226,150,20)
	oPeople = uiListBox(oForm,20,248,360,70)

	uiRun(oForm)

func register

	cName = trim(oName.Text)
	if cName = ""
		oResult.Text = "Please type a name"
		return
	ok
	if oCountry.SelectedIndex < 0
		oResult.Text = "Please choose a country"
		return
	ok
	cLine = cName + ", " + oAge.Value + ", " + oCountry.Text
	if oNewsletter.Checked
		cLine += " (newsletter)"
	ok
	oPeople.Items.Add(cLine)
	oResult.Text = "Registered: " + cName
	oName.Text = ""
