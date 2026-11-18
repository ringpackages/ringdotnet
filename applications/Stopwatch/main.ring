# Stopwatch with laps - a port of ring/applications/stopwatch to RingDotNet

load "dotnet.ring"
dnUseDesktop()
using {
	"System"
	"System.Diagnostics"
	"System.Threading"
	"System.Drawing"
	"System.Windows.Forms"
}

oWatch = new Stopwatch()
nLastLap = 0

oForm = uiForm("Stopwatch",300,320)
oTime = uiLabel(oForm,"00:00.00",10,10,280,60)
oTime {
	Font = uiFont("Consolas",32,true)
	TextAlign = "MiddleCenter"
}
oStart = uiButton(oForm,"Start",10,80,85,34,"startStop()")
oLap = uiButton(oForm,"Lap",107,80,85,34,"lap()")
oReset = uiButton(oForm,"Reset",204,80,85,34,"reset()")
oLaps = uiListBox(oForm,10,125,280,185)
oTimer = uiTimer(50,"showTime()")

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func formatTime nMilliseconds
	nSeconds = floor(nMilliseconds / 1000)
	nMinutes = floor(nSeconds / 60)
	return twoDigits(nMinutes) + ":" + twoDigits(nSeconds % 60) + "." + twoDigits(floor((nMilliseconds % 1000) / 10))

func twoDigits n
	cText = "" + floor(n)
	if len(cText) < 2
		cText = "0" + cText
	ok
	return cText

func showTime
	oTime.Text = formatTime(oWatch.ElapsedMilliseconds)

func startStop
	if oWatch.IsRunning
		oWatch.Stop()
		oTimer.Stop()
		oStart.Text = "Start"
	else
		oWatch.Start()
		oTimer.Start()
		oStart.Text = "Stop"
	ok
	showTime()

func lap
	if oWatch.ElapsedMilliseconds > 0
		nNow = oWatch.ElapsedMilliseconds
		oLaps.Items.Add("Lap " + (oLaps.Items.Count + 1) + "   " + formatTime(nNow) + "   (+" + formatTime(nNow - nLastLap) + ")")
		nLastLap = nNow
	ok

func reset
	oWatch.Reset()
	oTimer.Stop()
	oStart.Text = "Start"
	oLaps.Items.Clear()
	nLastLap = 0
	showTime()

# let the form process the timer messages for a while
func waitMs nMilliseconds
	oClock = new Stopwatch()
	oClock.Start()
	while oClock.ElapsedMilliseconds < nMilliseconds
		new Application().DoEvents()
		new Thread().Sleep(5)
	end

func selfTest
	dnAssert("format",formatTime(83450),"01:23.45")
	oStart.PerformClick()
	dnAssert("running",oWatch.IsRunning,1)
	dnAssert("button says Stop",oStart.Text,"Stop")
	waitMs(300)
	oLap.PerformClick()
	dnAssert("one lap",oLaps.Items.Count,1)
	dnAssert("time moved",oWatch.ElapsedMilliseconds >= 250,True)
	dnAssert("display updated by the timer",oTime.Text != "00:00.00",1)
	oStart.PerformClick()
	dnAssert("stopped",oWatch.IsRunning,0)
	oReset.PerformClick()
	dnAssert("reset",oTime.Text,"00:00.00")
	dnAssert("laps cleared",oLaps.Items.Count,0)
