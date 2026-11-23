# one program for Windows, Linux and macOS - what differs between the systems and how a program asks instead of assuming
#   (the answers are different on each system; the lesson shows the output of Windows and of Linux)
load "dotnet.ring"

using {
	"System"
	"System.IO"
}

# A window needs Windows: on another system, asking for it ends the program at once, so the line that asks is behind a question.
if isWindows()
	using { "System.Windows.Forms" }
ok

func main

	# 1. Which system? Ring answers with isWindows(), isLinux() and isMacOSX(); .NET names the platform
	? "1. windows: " + isWindows() + ", linux: " + isLinux() + ", macos: " + isMacOSX() + ", platform: " + new Environment().OSVersion.Platform

	# 2. Paths. A path separator is \ on Windows and / on Linux and macOS; Path.Combine uses the right one, and a / is accepted by every system.
	? "2. separator: " + new Path().DirectorySeparatorChar + "   Combine: " + new Path().Combine(["data","report.txt"])

	# 3. Case. Windows does not care about upper and lower case in a file name, Linux does (macOS usually does not, but can).
	cFolder = new Path().Combine([new Path().GetTempPath(),"ringdotnet-systems"])
	new Directory().CreateDirectory(cFolder)
	cFile = new Path().Combine([cFolder,"notes.txt"])
	new File().WriteAllText([ :path = cFile, :contents = "x" ])
	? "3. notes.txt exists: " + new File().Exists(cFile) + ", NOTES.TXT exists: " + new File().Exists(new Path().Combine([cFolder,"NOTES.TXT"]))
	new Directory().Delete([ :path = cFolder, :recursive = true ])

	# 4. The end of a line: 2 characters on Windows (13 10), 1 on Linux and macOS (10)
	? "4. the end of a line has " + len(new Environment().NewLine) + " character(s)"

	# 5. The folder of the user is found by asking, not by writing C:\Users\ or /home/
	cHome = new Environment().GetFolderPath("UserProfile")
	? "5. the home folder exists: " + new Directory().Exists(cHome)

	# 6. A feature of one system, behind a question
	if isWindows()
		oForm = new Form
		? "6. a window can be made: " + classname(oForm)
	else
		? "6. no windows here: the program works in the console"
	ok
