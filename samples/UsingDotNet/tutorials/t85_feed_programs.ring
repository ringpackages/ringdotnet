# working with other programs - feeding standard input, environment variables, errors and exit codes, a time limit and Kill
#   (the examples use the Windows commands sort, find and cmd; on Linux and macOS use sort, grep and sh)
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Diagnostics"
}

func main
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
	oSecond = startProgram("find",'"e"',True)
	oSecond.StandardInput.Write(cText)
	oSecond.StandardInput.Close()
	cFound = oSecond.StandardOutput.ReadToEnd()
	oSecond.WaitForExit(NULL)
	? nl + "2. sorted, and only the lines with an 'e': " + lines(cFound)

	# 3. Environment variables and the working folder of the new program are set before it starts.
	#    (a variable first: a "new" on the right side of an assignment to a property loses the assignment, see Gotchas)
	cTemp = new Path().GetTempPath()
	oInfo = dnNew("ProcessStartInfo",[ :fileName = "cmd.exe", :arguments = "/c echo %GREETING%" ])
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
	oFail = startProgram("cmd.exe","/c dir this_folder_does_not_exist",True)
	cError = oFail.StandardError.ReadToEnd()
	oFail.WaitForExit(NULL)
	? nl + "4. a failing command: exit code " + oFail.ExitCode + ", standard error says '" + chomp(cError) + "'"
	oGood = startProgram("cmd.exe","/c exit 0",True)
	oGood.WaitForExit(NULL)
	? "   a command that succeeds has exit code " + oGood.ExitCode

	# 5. A time limit and Kill: WaitForExit(ms) answers false when the program is still running; Kill stops it.
	oSlow = startProgram("cmd.exe","/c ping -n 6 127.0.0.1 > nul",False)
	lFinished = oSlow.WaitForExit(300)
	? nl + "5. waited 300 ms for a program that runs about 5 seconds: finished = " + yesNo(lFinished)
	oSlow.Kill(NULL)
	oSlow.WaitForExit(NULL)
	? "   after Kill it has exited: " + yesNo(oSlow.HasExited)

# start a program; lRedirect = True gives the program's three streams to this program (input, output, error)
func startProgram cFile, cArguments, lRedirect
	oInfo = dnNew("ProcessStartInfo",[ :fileName = cFile, :arguments = cArguments ])
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
