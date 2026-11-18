# Tutorial 10: time, tasks and other programs - Stopwatch, Task, Process, Environment
load "dotnet.ring"
using {
	"System"
	"System.Diagnostics"
	"System.Threading.Tasks"
	"System.Threading"
}

func main
	# Measuring time: Stopwatch
	oWatch = new Stopwatch()
	oWatch.Start()
	new Thread().Sleep(120)
	oWatch.Stop()
	? "Slept about 120 ms, measured at least 100: " + (oWatch.ElapsedMilliseconds >= 100)

	# Tasks run work in the background; Wait() waits for the end on the Ring thread
	oTask = new Task().Delay(100)
	? "Task finished at once?   : " + oTask.IsCompleted
	oTask.Wait(NULL)
	? "Task finished after Wait : " + oTask.IsCompleted

	# A task that has a result
	oResult = new Task().FromResult("done")
	? "Task result              : " + oResult.getProp("Result")

	# The environment
	oEnvironment = new Environment()
	? nl + "Machine name             : " + (len(oEnvironment.MachineName) > 0)
	? "Number of processors      : " + (oEnvironment.ProcessorCount >= 1)
	? "A variable (PATH) exists  : " + (len(oEnvironment.GetEnvironmentVariable("PATH")) > 0)
	? "Current folder is known   : " + (len(oEnvironment.CurrentDirectory) > 0)

	# Running another program and reading what it prints
	oInfo = new ProcessStartInfo() {
		FileName = "cmd"
		Arguments = "/c echo hello from another program"
		RedirectStandardOutput = True
		UseShellExecute = False
		CreateNoWindow = True
	}
	oProcess = new Process().Start([ :startInfo = oInfo ])
	cOutput = oProcess.StandardOutput.ReadToEnd()
	oProcess.WaitForExit(NULL)
	? nl + "The other program said: " + trim(cOutput)
	? "Its exit code            : " + oProcess.ExitCode

	# Important: Ring code runs on ONE thread. A task is good for waiting or for pure .NET work.
	# A callback that .NET runs on another thread can not call Ring (see 'Gotchas & limits').
