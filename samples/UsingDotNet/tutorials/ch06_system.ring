# asking the computer - the operating system, the runtime, processors, memory, drives and running programs
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Diagnostics"
	"System.Text"
	"System.Runtime.InteropServices"
}

func main
	oEnvironment = new Environment()
	oRuntime = new RuntimeInformation()

	# 1. Which system runs the program? A program that must behave differently on Windows, Linux and macOS asks first.
	? "1. platform          : " + oEnvironment.OSVersion.Platform
	? "   runtime           : " + oRuntime.FrameworkDescription
	? "   process type      : " + oRuntime.ProcessArchitecture + ", 64-bit system? " + yesNo(oEnvironment.Is64BitOperatingSystem)
	? "   is it Windows?    : " + yesNo(runsOnWindows(oEnvironment))

	# 2. The machine: processors and how long it has been running
	? nl + "2. logical processors: " + oEnvironment.ProcessorCount
	nSeconds = floor(oEnvironment.TickCount64 / 1000)
	? "   the computer has been on for more than a second: " + yesNo(nSeconds > 1)

	# 3. Who and where: do not print private data in logs, but a program can use it (for example to find the user's folders)
	? nl + "3. the user name and the machine name exist: " + yesNo(len(oEnvironment.UserName) > 0 and len(oEnvironment.MachineName) > 0)
	? "   the current folder exists: " + yesNo(new Directory().Exists(oEnvironment.CurrentDirectory))

	# 4. Drives
	aDrives = new Directory().GetLogicalDrives().toList()
	? nl + "4. there is at least one drive: " + yesNo(len(aDrives) > 0) + ", and its name contains a colon (like C:): " + yesNo(substr(aDrives[1],":") > 0)

	# 5. This program as a process: its id, its name, how much memory it uses
	oProcess = new Process().GetCurrentProcess()
	nMegabytes = floor(oProcess.WorkingSet64 / 1048576)
	? nl + "5. this program is the process '" + oProcess.ProcessName + "'; it uses between 1 and 2000 MB: " + yesNo(nMegabytes >= 1 and nMegabytes < 2000)

	# 6. .NET's memory manager: the memory used by .NET objects, and what happens after a collection
	oGC = new GC()
	nBefore = oGC.GetTotalMemory(False)
	oBig = dnNew("StringBuilder",[ :capacity = 5000000 ])
	nWith = oGC.GetTotalMemory(False)
	? nl + "6. a StringBuilder with 5 million characters made the .NET memory grow: " + yesNo(nWith > nBefore + 1000000)

	# 7. All programs that run now
	aProcesses = new Process().GetProcesses(NULL).toList()
	? nl + "7. more than five programs are running: " + yesNo(len(aProcesses) > 5)
	lFound = False
	for oOther in aProcesses
		if oOther.Id = oProcess.Id
			lFound = True
		ok
	next
	? "   this program is among them: " + yesNo(lFound)

	# 8. A timer you can trust for measuring: Stopwatch uses the high resolution counter of the processor
	? nl + "8. Stopwatch has a high resolution counter: " + yesNo(new Stopwatch().IsHighResolution)

# true when the program runs on Windows (the platform is "Win32NT" there, "Unix" on Linux and macOS)
func runsOnWindows oEnvironment
	cPlatform = oEnvironment.OSVersion.Platform
	return cPlatform = "Win32NT"

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
