# Countdown timer with a progress bar (a Windows Forms Timer drives the Ring code)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System"
	"System.Diagnostics"
	"System.Threading"
	"System.Drawing"
	"System.Windows.Forms"
}

nTotal = 0		# seconds when the countdown started
nLeft = 0		# seconds left
lRunning = false

oForm = uiForm("Countdown",330,230)
oForm {
	FormBorderStyle = "FixedDialog"
	MaximizeBox = False
}
uiLabel(oForm,"Minutes",15,18,60,22)
oMinutes = new NumericUpDown() {
	Location = new Point(80,16)
	Size = new Size(55,24)
	Maximum = 99
	Value = 1
}
oForm.Controls.Add(oMinutes)
uiLabel(oForm,"Seconds",150,18,60,22)
oSeconds = new NumericUpDown() {
	Location = new Point(215,16)
	Size = new Size(55,24)
	Maximum = 59
}
oForm.Controls.Add(oSeconds)
oDisplay = uiLabel(oForm,"01:00",15,55,300,60)
oDisplay {
	Font = uiFont("Consolas",36,true)
	TextAlign = "MiddleCenter"
}
oBar = new ProgressBar() {
	Location = new Point(15,120)
	Size = new Size(300,18)
	Maximum = 100
}
oForm.Controls.Add(oBar)
oStart = uiButton(oForm,"Start",15,155,95,34,"startStop()")
uiButton(oForm,"Reset",120,155,95,34,"resetTimer()")
oTimer = uiTimer(1000,"tick()")

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func twoDigits n
	cText = "" + floor(n)
	if len(cText) < 2
		cText = "0" + cText
	ok
	return cText

func showTime
	oDisplay.Text = twoDigits(floor(nLeft / 60)) + ":" + twoDigits(nLeft % 60)
	if nTotal > 0
		oBar.Value = floor((nTotal - nLeft) * 100 / nTotal)
	else
		oBar.Value = 0
	ok

func startStop
	if lRunning
		lRunning = false
		oTimer.Stop()
		oStart.Text = "Start"
	else
		if nLeft = 0
			nTotal = number(oMinutes.Value) * 60 + number(oSeconds.Value)
			nLeft = nTotal
		ok
		if nLeft > 0
			lRunning = true
			oTimer.Start()
			oStart.Text = "Pause"
		ok
	ok
	showTime()

func resetTimer
	lRunning = false
	oTimer.Stop()
	oStart.Text = "Start"
	nTotal = number(oMinutes.Value) * 60 + number(oSeconds.Value)
	nLeft = nTotal
	showTime()

func tick
	if nLeft > 0
		nLeft--
	ok
	showTime()
	if nLeft = 0
		lRunning = false
		oTimer.Stop()
		oStart.Text = "Start"
		uiMessage("Time is up!","Countdown")
	ok

func waitMs nMilliseconds
	oClock = new Stopwatch()
	oClock.Start()
	while oClock.ElapsedMilliseconds < nMilliseconds
		new Application().DoEvents()
		new Thread().Sleep(5)
	end

func selfTest
	oMinutes.Value = 0
	oSeconds.Value = 3
	resetTimer()
	dnAssert("display",oDisplay.Text,"00:03")
	tick()
	dnAssert("one second passed",oDisplay.Text,"00:02")
	dnAssert("progress",oBar.Value,33)
	tick()
	tick()
	dnAssert("finished",oDisplay.Text,"00:00")
	dnAssert("full bar",oBar.Value,100)
	dnAssert("stopped",lRunning,0)
	# the real timer ticks once a second
	oSeconds.Value = 5
	resetTimer()
	oStart.PerformClick()
	dnAssert("button says Pause",oStart.Text,"Pause")
	waitMs(2200)
	oStart.PerformClick()
	dnAssert("two ticks happened",nLeft <= 3 and nLeft >= 2,True)
	resetTimer()
	dnAssert("reset",oDisplay.Text,"00:05")
