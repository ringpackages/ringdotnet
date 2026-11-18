# A button that counts its clicks

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}


nClicks = 0
oForm = uiForm("Click counter",260,130)
oCount = uiLabel(oForm,"0 clicks",20,15,220,24)
uiButton(oForm,"Click me",20,50,100,32,"clicked()")

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func clicked
	nClicks++
	oCount.Text = "" + nClicks + " clicks"

func selfTest
	oForm.Controls.Item(1).PerformClick()
	oForm.Controls.Item(1).PerformClick()
	oForm.Controls.Item(1).PerformClick()
	dnAssert("three clicks",oCount.Text,"3 clicks")
