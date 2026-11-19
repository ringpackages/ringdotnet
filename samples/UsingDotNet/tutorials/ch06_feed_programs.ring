# working with other programs - feeding standard input, environment variables, errors and exit codes, a time limit and Kill
#   (the commands are chosen for the system: sort, find and cmd on Windows; sort, grep and sh on Linux and macOS)
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Diagnostics"
}

# the shell of this system (set in main, used by shellArgs)
cShell = ""
cShellOption = ""

func main
	# the program that keeps the lines with an "e", and the shell, for this system
	cFilter = "grep"
	cFilterArgs = "e"
	cShell = "sh"
	cShellOption = "-c"
	cDirError = "ls this_folder_does_not_exist"
	cWait = "sleep 5"
	if isWindows()
		cFilter = "find"
		cFilterArgs = '"e"'
		cShell = "cmd.exe"
		cShellOption = "/c"
		cDirError = "dir this_folder_does_not_exist"
		cWait = "ping -n 6 127.0.0.1 > nul"
	ok

	# 1. Standard input: send lines to a program that reads its input, close the input, and read what it answers.
	#    The program "sort" reads lines and prints them sorted.
	oSort = startProgram("sort","",True)
	oSort.StandardInput.WriteLine("pear")
	oSort.StandardInput.WriteLine("apple")
	oSort.StandardInput.WriteLine("fig")
	oSort.StandardInput.Close()                            # closing the input tells sort that there is no more
	cSorted = oSort.StandardOutput.ReadToEnd()
	oSort.WaitForExit(NULL)
	? "1. sort answered: " + lines(cSorted) + "   (exit code " + oSort.ExitCode + ")"

	# 2. Chaining: the output of one program is the input of another. sort, then find keeps the lines that contain an 'e'.
	oFirst = startProgram("sort","",True)
	for cFruit in ["fig","pear","plum","apple","kiwi"]
		oFirst.StandardInput.WriteLine(cFruit)
	next
	oFirst.StandardInput.Close()
	cText = oFirst.StandardOutput.ReadToEnd()
	oFirst.WaitForExit(NULL)
	oSecond = startProgram(cFilter,cFilterArgs,True)
	oSecond.StandardInput.Write(cText)
	oSecond.StandardInput.Close()
	cFound = oSecond.StandardOutput.ReadToEnd()
	oSecond.WaitForExit(NULL)
	? nl + "2. sorted, and only the lines with an 'e': " + lines(cFound)

	# 3. Environment variables and the working folder of the new program are set before it starts.
	#    (a variable first: a "new" on the right side of an assignment to a property loses the assignment, see Gotchas)
	cTemp = new Path().GetTempPath()
	cEcho = "echo %GREETING%"
	if not isWindows()
		cEcho = "echo $GREETING"
	ok
	oInfo = new ProcessStartInfo().New_([ :fileName = cShell, :arguments = shellArgs(cEcho) ])
	oInfo {
		UseShellExecute = False
		RedirectStandardOutput = True
		CreateNoWindow = True
	}
	oInfo.EnvironmentVariables.Add("GREETING","hello from the parent program")
	oInfo.WorkingDirectory = cTemp
	oEnvironment = new Process().Start(oInfo)
	cGreeting = oEnvironment.StandardOutput.ReadToEnd()
	oEnvironment.WaitForExit(NULL)
	? nl + "3. the child read the variable that the parent set: " + chomp(cGreeting)

	# 4. Errors: a program writes errors to a SECOND stream (standard error) and ends with an exit code. 0 means success.
	oFail = startProgram(cShell,shellArgs(cDirError),True)
	cError = oFail.StandardError.ReadToEnd()
	oFail.WaitForExit(NULL)
	? nl + "4. a failing command: exit code " + oFail.ExitCode + ", standard error says '" + chomp(cError) + "'"
	oGood = startProgram(cShell,shellArgs("exit 0"),True)
	oGood.WaitForExit(NULL)
	? "   a command that succeeds has exit code " + oGood.ExitCode

	# 5. A time limit and Kill: WaitForExit(ms) answers false when the program is still running; Kill stops it.
	oSlow = startProgram(cShell,shellArgs(cWait),False)
	lFinished = oSlow.WaitForExit(300)
	? nl + "5. waited 300 ms for a program that runs about 5 seconds: finished = " + yesNo(lFinished)
	oSlow.Kill(NULL)
	oSlow.WaitForExit(NULL)
	? "   after Kill it has exited: " + yesNo(oSlow.HasExited)

# the arguments that make the shell run a command: cmd /c "command" or sh -c "command"
func shellArgs cCommand
	return cShellOption + ' "' + cCommand + '"'

# start a program; lRedirect = True gives the program's three streams to this program (input, output, error)
func startProgram cFile, cArguments, lRedirect
	oInfo = new ProcessStartInfo().New_([ :fileName = cFile, :arguments = cArguments ])
	oInfo.UseShellExecute = False
	oInfo.CreateNoWindow = True
	if lRedirect
		oInfo.RedirectStandardInput = True
		oInfo.RedirectStandardOutput = True
		oInfo.RedirectStandardError = True
	ok
	return new Process().Start(oInfo)

# the lines of a text as one line: "apple, fig, pear"
func lines cText
	cResult = ""
	for cLine in str2list(substr(substr(cText,char(13),""),char(10),nl))
		if trim(cLine) != ""
			if cResult != ""
				cResult += ", "
			ok
			cResult += trim(cLine)
		ok
	next
	return cResult

func chomp cText
	while right(cText,1) = char(10) or right(cText,1) = char(13) or right(cText,1) = " "
		cText = left(cText,len(cText) - 1)
	end
	return cText

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
