# tracing - Trace and listeners: messages with an indent, a listener that collects them in memory, a listener that writes a file, and levels
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Diagnostics"
	"System.Threading.Tasks"
}

func main
	# TRACING writes messages about what a program does, for the person who looks for a problem. A program sends a message to the class
	# Trace, and the LISTENERS that were added to Trace decide where it goes: the console, a file, a window, a log service. The program
	# that writes the messages does not know where they go, and a listener can be added or removed without changing the code.
	cTrace = "System.Diagnostics.Trace"

	# 1. A listener that writes into memory: a TextWriterTraceListener on a StringWriter. (A StringWriter is a text writer that keeps
	#    its text in memory; the tutorial about text readers and writers uses it.)
	oWriter = new StringWriter()
	oMemory = dnNew("TextWriterTraceListener",[ oWriter ])
	dnStatic(cTrace,"get_Listeners",[]).Add(oMemory)
	dnStatic(cTrace,"set_AutoFlush",[ True ])               # write each message at once
	dnStatic(cTrace,"WriteLine",[ "program started" ])
	dnStatic(cTrace,"WriteLine",[ "reading the settings" ])
	? "1. the memory listener has:"
	showLines(oWriter.ToString())

	# 2. Indent: the messages of a step are pushed to the right, so that a long trace shows the structure of the work
	oWriter.GetStringBuilder().Clear()
	dnStatic(cTrace,"WriteLine",[ "checking the files" ])
	dnStatic(cTrace,"Indent",[])
	dnStatic(cTrace,"WriteLine",[ "a.txt: ok" ])
	dnStatic(cTrace,"WriteLine",[ "b.txt: missing" ])
	dnStatic(cTrace,"Indent",[])
	dnStatic(cTrace,"WriteLine",[ "tried the backup folder" ])
	dnStatic(cTrace,"Unindent",[])
	dnStatic(cTrace,"Unindent",[])
	dnStatic(cTrace,"WriteLine",[ "done" ])
	? nl + "2. with Indent and Unindent:"
	showLines(oWriter.ToString())

	# 3. WriteLineIf: the message is written only when a condition is true, and a category can come in front of it
	oWriter.GetStringBuilder().Clear()
	for nSize in [ 10, 5000, 90000 ]
		dnStatic(cTrace,"WriteLineIf",[ nSize > 1000, "the file is big: " + nSize + " bytes" ])
	next
	dnStatic(cTrace,"WriteLine",[ "slow query", "database" ])
	? nl + "3. WriteLineIf and a category:"
	showLines(oWriter.ToString())

	# 4. A second listener, on a file: now each message goes to two places. The file keeps the trace after the program ended.
	oPath = new Path()
	cFile = oPath.Combine([ oPath.GetTempPath(), "ringdotnet-trace-" + oPath.GetRandomFileName() + ".log" ])
	oFileListener = dnNew("TextWriterTraceListener",[ cFile ])
	dnStatic(cTrace,"get_Listeners",[]).Add(oFileListener)
	oWriter.GetStringBuilder().Clear()
	dnStatic(cTrace,"WriteLine",[ "one message, two listeners" ])
	dnStatic(cTrace,"Flush",[])
	? nl + "4. the same message in memory and in the file:"
	? "   memory: " + oneLine(oWriter.ToString())
	oFileListener.Flush()
	oFileListener.Dispose()
	? "   file:   " + oneLine(readText(cFile))

	# 5. Removing a listener: the messages stop going to it
	dnStatic(cTrace,"get_Listeners",[]).Remove(oFileListener)
	new File().Delete(cFile)
	oWriter.GetStringBuilder().Clear()
	dnStatic(cTrace,"WriteLine",[ "after the file listener was removed" ])
	? nl + "5. the memory listener still gets messages: " + yesNo(len(oneLine(oWriter.ToString())) > 0)

	# 6. A trace with the time of each step: tracing is most useful when the messages say how long something took
	oWatch = new Stopwatch()
	oWatch.Start()
	oWriter.GetStringBuilder().Clear()
	dnStatic(cTrace,"WriteLine",[ "step 1 started" ])
	new Task().Delay(150).Wait(NULL)
	dnStatic(cTrace,"WriteLine",[ "step 2: after the pause, at least 100 ms: " + yesNo(oWatch.ElapsedMilliseconds >= 100) ])
	? nl + "6. messages with the time:"
	showLines(oWriter.ToString())

# the lines of a text, each one indented by three spaces (the trace output has the line ending of the system)
func showLines cText
	for cLine in str2list(substr(cText,char(13),""))
		if cLine != ""
			? "   [" + cLine + "]"
		ok
	next

# a text without its line ending (the trace adds one after each message)
func oneLine cText
	return trim(substr(substr(cText,char(13),""),nl,""))

func readText cFile
	return new File().ReadAllText(cFile)

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
