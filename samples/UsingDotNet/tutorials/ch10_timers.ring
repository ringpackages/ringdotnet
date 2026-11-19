# timers and progress - a stopwatch and a long job that keeps the window alive
load "dotnet.ring"
using {
	"System"
	"System.Diagnostics"
	"System.Threading"
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = ""
oTime = ""
oBar = ""
oInfo = ""
oClock = ""                     # the timer that updates the time every 50 ms
oJob = ""                       # the timer that does one small part of the job every 20 ms
oWatch = ""                     # a Stopwatch object
nDone = 0                       # how many parts of the job are done
nTotal = 100
lRunning = False

func main
	oWatch = new Stopwatch()
	oForm = uiForm("Timers",360,200)
	oTime = uiLabel(oForm,"0:00.0",20,10,320,44)
	oTime.Font = new Font("Segoe UI",26)
	uiButton(oForm,"Start / Stop",20,64,110,30,"toggleWatch()")
	uiButton(oForm,"Reset",136,64,70,30,"resetWatch()")
	oBar = new ProgressBar() {
		Location = new Point(20,112)
		Size = new Size(320,22)
		Minimum = 0
		Maximum = 100
	}
	oForm.Controls.Add(oBar)
	oInfo = uiLabel(oForm,"The job has not started",20,140,200,22)
	uiButton(oForm,"Run the job",226,136,114,28,"startJob()")

	# TIMER 1: shows the stopwatch time. A Windows Forms timer ticks on the Ring thread: it can use Ring code and controls.
	oClock = uiTimer(50,"showTime()")
	oClock.Start()

	uiRun(oForm)

# ---------------------------------------------------------------- the stopwatch

func toggleWatch
	if oWatch.IsRunning
		oWatch.Stop()
	else
		oWatch.Start()
	ok

func resetWatch
	oWatch.Reset()
	showTime()

func showTime
	nMilliseconds = oWatch.ElapsedMilliseconds
	nSeconds = floor(nMilliseconds / 1000)
	oTime.Text = "" + floor(nSeconds / 60) + ":" + right("0" + (nSeconds % 60),2) + "." + floor((nMilliseconds % 1000) / 100)

# ---------------------------------------------------------------- a long job in small parts
# A job that takes seconds must NOT run in one go: the window would freeze (no repainting, no clicks).
# Instead, do a small part each time a timer ticks, and return to the message loop in between.

func startJob
	if lRunning
		return
	ok
	lRunning = True
	nDone = 0
	oBar.Value = 0
	oJob = uiTimer(20,"jobStep()")
	oJob.Start()
	oInfo.Text = "Working..."

func jobStep
	nDone += 5                       # one small part of the work
	oBar.Value = min(nDone,nTotal)
	oInfo.Text = "Working... " + nDone + "%"
	if nDone >= nTotal
		oJob.Stop()
		lRunning = False
		oInfo.Text = "Finished"
	ok

# ---------------------------------------------------------------- the test: stop the timers, call the steps by hand
