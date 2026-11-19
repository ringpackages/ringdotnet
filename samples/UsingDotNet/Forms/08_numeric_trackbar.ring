# A track bar and a numeric box that follow each other

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Slider",320,130)
oBar = new TrackBar() {
	Location = new Point(15,15)
	Size = new Size(200,40)
	Maximum = 100
}
oForm.Controls.Add(oBar)
oNumber = new NumericUpDown() {
	Location = new Point(230,18)
	Size = new Size(65,26)
	Maximum = 100
}
oForm.Controls.Add(oNumber)
oBar.setValueChangedEvent("oNumber.Value = oBar.Value")
oNumber.setValueChangedEvent("oBar.Value = oNumber.Value")

uiRun(oForm)
