# A track bar and a numeric box that follow each other

load "dotnet.ring"
dnUseDesktop()
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

uiTest(oForm,"oBar.Value = 40 dnAssert('number follows',number(oNumber.Value),40) oNumber.Value = 75 dnAssert('bar follows',oBar.Value,75)")
uiRun(oForm)
uiEnd()
