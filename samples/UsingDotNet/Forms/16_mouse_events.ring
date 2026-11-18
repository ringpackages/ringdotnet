# Mouse position and buttons

load "dotnet.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Mouse",320,160)
oArea = uiPanel(oForm,10,10,300,100)
oArea {
	BackColor = uiColor("LightYellow")
	BorderStyle = "FixedSingle"
}
oInfo = uiLabel(oForm,"Move the mouse over the yellow area",10,120,300,24)
oArea {
	setMouseMoveEvent("moved(aDotNetArgs[2].X,aDotNetArgs[2].Y)")
	setMouseDownEvent("pressed(aDotNetArgs[2].Button,aDotNetArgs[2].X,aDotNetArgs[2].Y)")
}

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func moved nX, nY
	oInfo.Text = "x=" + nX + " y=" + nY

func pressed cButton, nX, nY
	oInfo.Text = cButton + " button at " + nX + "," + nY

func selfTest
	moved(12,34)
	dnAssert("move text",oInfo.Text,"x=12 y=34")
	pressed("Right",5,6)
	dnAssert("press text",oInfo.Text,"Right button at 5,6")
