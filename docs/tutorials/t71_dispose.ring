# Tutorial 71: releasing resources - files that stay locked, Dispose, and cleaning up even when an error happens
load "dotnet.ring"
using {
	"System"
	"System.IO"
}

func main
	cFile = new Path().Combine(new Path().GetTempPath(),"tutorial71.txt")
	new File().WriteAllText(cFile,"some text")

	# 1. A resource is something the operating system lends to your program: a file, a socket, a database connection.
	#    While you hold it, others may not be able to use it. Open the file for writing and try to delete it.
	oStream = new File().Open(cFile,"Open")
	? "1. the file is open. Can we delete it now? " + yesNo(tryDelete(cFile))

	# 2. Dispose gives the resource back. After it the delete works.
	oStream.Dispose()
	? nl + "2. after Dispose. Can we delete it now? " + yesNo(tryDelete(cFile))

	# 3. If an error happens between opening and closing, a Dispose at the end of the code is skipped. Look at this function:
	new File().WriteAllText(cFile,"line 1" + windowsnl() + "line 2")
	? nl + "3. a reader without a clean-up, and an error while reading:"
	oLeaked = readBadly(cFile)
	? "   the file is still locked after the error: " + yesNo(not tryDelete(cFile))
	? "   (Ring forgot the variable when the function ended, but the .NET reader is still open)"
	oLeaked.Dispose()                           # for the tutorial: clean up our own mess

	# 4. The same with try / catch / done: the clean-up goes where it is always reached
	new File().WriteAllText(cFile,"line 1" + windowsnl() + "line 2")
	? nl + "4. the careful way:"
	readCarefully(cFile)
	? "   the file can be deleted after the error: " + yesNo(tryDelete(cFile))

	new File().Delete(cFile)

	# 5. Things that need Dispose: streams, readers, writers, HttpClient, sockets, database contexts, JsonDocument, timers.
	#    A good rule: if you opened it, close it; if the class has a Dispose or Close method, use it.
	? nl + "5. rule: whoever creates a resource releases it, in the same function if possible"

# Opens a reader, fails while reading, and never closes the reader
func readBadly cFile
	oReader = new StreamReader(cFile)
	try
		? "   first line: " + oReader.ReadLine()
		failHere()
		oReader.Dispose()                       # never reached
	catch
		? "   an error: " + left(cCatchError,40)
	done
	return oReader

# The Dispose is after the try block: it runs whether the work failed or not
func readCarefully cFile
	oReader = new StreamReader(cFile)
	try
		? "   first line: " + oReader.ReadLine()
		failHere()
	catch
		? "   an error: " + left(cCatchError,40)
	done
	oReader.Dispose()
	? "   the reader was disposed"

func failHere
	new Int32().Parse("not a number")

# true when the file could be deleted
func tryDelete cFile
	lDeleted = True
	try
		new File().Delete(cFile)
	catch
		lDeleted = False
	done
	if lDeleted
		new File().WriteAllText(cFile,"again")        # put it back for the next step
	ok
	return lDeleted

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
