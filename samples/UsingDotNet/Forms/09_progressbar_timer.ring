# A progress bar driven by a timer

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}


nPercent = 0
oForm = uiForm("Progress",320,110)
oBar = new ProgressBar() {
	Location = new Point(20,20)
	Size = new Size(270,24)
}
oForm.Controls.Add(oBar)
oText = uiLabel(oForm,"0%",20,55,270,24)
oTimer = uiTimer(100,"advance()")
oTimer.Start()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func advance
	nPercent += 10
	oBar.Value = nPercent
	oText.Text = "" + nPercent + "%"
	if nPercent >= 100
		oTimer.Stop()
		oText.Text = "Done"
	ok

func selfTest
	oTimer.Stop()
	for x = 1 to 10
		advance()
	next
	dnAssert("finished",oText.Text,"Done")
	dnAssert("full bar",oBar.Value,100)
