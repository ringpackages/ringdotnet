# two programs talking - a named pipe between processes, and a mutex that allows only one copy
#   ring ch06_processes_talk.ring            the parent: it starts a second copy of this program (the child) and talks to it
#   ring ch06_processes_talk.ring --child    the child (the parent starts it, you do not)
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.IO.Pipes"
	"System.Diagnostics"
	"System.Threading"
}

C_PIPE = "ringdotnet_tutorial79"
C_MUTEX = "ringdotnet_tutorial79_single_copy"

func main
	if find(sysargv,"--child") > 0
		runChild()
		return
	ok
	runParent()

# ---------------------------------------------------------------- the parent

func runParent
	# 1. A named mutex is a lock that the whole computer shares. The first program that gets it is "the only copy".
	oLock = dnNew("Mutex",[ :initiallyOwned = False, :name = C_MUTEX ])
	? "1. the parent got the lock: " + yesNo(oLock.WaitOne(0))              # WaitOne(0): do not wait, just try

	# 2. A named pipe server waits for a client. The pipe has a name that any program of this computer can open.
	oServer = dnNew("NamedPipeServerStream",[ :pipeName = C_PIPE, :direction = "InOut" ])
	? nl + "2. the pipe server is listening on '" + C_PIPE + "'"

	# 3. Start the child: a second copy of this program, with its output redirected so that the parent can read it
	oInfo = dnNew("ProcessStartInfo",[ :fileName = exefilename(), :arguments = '"' + filename() + '" --child' ])
	oInfo {
		UseShellExecute = False
		CreateNoWindow = True
		RedirectStandardOutput = True
	}
	oChild = new Process().Start(oInfo)
	oServer.WaitForConnection()
	? nl + "3. the child connected"

	# 4. Talk: send a request, read the answer. A line is one message.
	oReader = new StreamReader(oServer)
	oWriter = new StreamWriter(oServer)
	oWriter.AutoFlush = True
	? nl + "4. talking over the pipe:"
	for cRequest in ["add 20 22","upper hello pipes","add 1 x","quit"]
		oWriter.WriteLine(cRequest)
		? "   sent '" + cRequest + "' -> " + oReader.ReadLine()
	next

	# 5. The child tried to take the lock too, and printed what happened (its output was redirected to us)
	cOutput = oChild.StandardOutput.ReadToEnd()
	oChild.WaitForExit(NULL)
	? nl + "5. the child says: " + chomp(cOutput)
	? "   the child's exit code: " + oChild.ExitCode
	oLock.ReleaseMutex()
	oServer.Dispose()

# ---------------------------------------------------------------- the child

func runChild
	oLock = dnNew("Mutex",[ :initiallyOwned = False, :name = C_MUTEX ])
	if oLock.WaitOne(0)
		? "I got the lock: no other copy was running"
	else
		? "another copy of the program holds the lock: I am the second copy"
	ok
	oClient = dnNew("NamedPipeClientStream",[ :serverName = ".", :pipeName = C_PIPE, :direction = "InOut" ])
	oClient.Connect(5000)                                  # wait up to 5 seconds for the server
	oReader = new StreamReader(oClient)
	oWriter = new StreamWriter(oClient)
	oWriter.AutoFlush = True
	while True
		cLine = oReader.ReadLine()
		if isobject(cLine) or cLine = "quit"
			oWriter.WriteLine("bye")
			exit
		ok
		oWriter.WriteLine(answer(cLine))
	end
	oClient.Dispose()

func answer cRequest
	aWords = str2list(substr(cRequest," ",nl))
	if aWords[1] = "add" and len(aWords) = 3 and isDigits(aWords[2]) and isDigits(aWords[3])
		return "" + (number(aWords[2]) + number(aWords[3]))
	but aWords[1] = "upper" and len(aWords) >= 2
		return upper(substr(cRequest,7,len(cRequest)))
	ok
	return "error: I do not understand '" + cRequest + "'"

func isDigits cText
	if cText = ""
		return False
	ok
	for nIndex = 1 to len(cText)
		if not isdigit(cText[nIndex])
			return False
		ok
	next
	return True

# a text without the new line at its end
func chomp cText
	while right(cText,1) = char(10) or right(cText,1) = char(13)
		cText = left(cText,len(cText) - 1)
	end
	return cText

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
