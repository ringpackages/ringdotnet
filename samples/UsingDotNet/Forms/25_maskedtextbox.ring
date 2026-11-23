# A masked text box for phone numbers and dates

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Masked input",300,130)
uiLabel(oForm,"Phone",15,18,50,22)
oPhone = new MaskedTextBox() {
	Mask = "(000) 000-0000"
	Location = new Point(75,15)
	Size = new Size(140,26)
}
oForm.Controls.Add(oPhone)
uiLabel(oForm,"Date",15,58,50,22)
oDate = new MaskedTextBox() {
	Mask = "00/00/0000"
	Location = new Point(75,55)
	Size = new Size(140,26)
}
oForm.Controls.Add(oDate)

uiRun(oForm)
