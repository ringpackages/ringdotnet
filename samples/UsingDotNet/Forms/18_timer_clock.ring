# A digital clock with a timer

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Clock",260,100)
oClock = uiLabel(oForm,"",10,20,240,50)
oClock {
	Font = uiFont("Consolas",28,true)
	TextAlign = "MiddleCenter"
}
oTimer = uiTimer(1000,"tick()")
tick()
oTimer.Start()

uiRun(oForm)

# --------------------------------------------------------------------------

func tick
	oNow = dnType("System.DateTime").getProp("Now")
	oClock.Text = oNow.Format("HH:mm:ss")
