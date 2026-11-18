# Horizontal and vertical scroll bars

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Scroll bars",320,200)
oH = new HScrollBar() {
	Location = new Point(15,15)
	Size = new Size(280,20)
	Maximum = 100
}
oForm.Controls.Add(oH)
oV = new VScrollBar() {
	Location = new Point(15,50)
	Size = new Size(20,120)
	Maximum = 50
}
oForm.Controls.Add(oV)
oValues = uiLabel(oForm,"H = 0, V = 0",60,80,220,24)
oH.setValueChangedEvent("show()")
oV.setValueChangedEvent("show()")

uiTest(oForm,"oH.Value = 30 oV.Value = 20 dnAssert('both values',oValues.Text,'H = 30, V = 20')")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func show
	oValues.Text = "H = " + oH.Value + ", V = " + oV.Value
