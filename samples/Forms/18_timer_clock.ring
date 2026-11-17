# A digital clock with a timer

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Clock",260,100)
oClock = uiLabel(oForm,"",10,20,240,50)
oClock.Font = uiFont("Consolas",28,true)
oClock.TextAlign = "MiddleCenter"
oTimer = uiTimer(1000,"tick()")
tick()
oTimer.Start()

uiTest(oForm,"dnAssert('time format',len(oClock.Text),8) dnAssert('colons',substr(oClock.Text,':') > 0,1)")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func tick
	oNow = dnType("System.DateTime").getProp("Now")
	oClock.Text = oNow.ToString_1("HH:mm:ss")
