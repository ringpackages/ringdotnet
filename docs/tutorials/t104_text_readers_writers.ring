# Tutorial 104: text readers and writers - StringWriter and StringReader, TextWriter in functions, and capturing Console output
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Text"
}

func main
	# 1. A StringWriter is a TextWriter that writes into a string in memory. Code that writes to "a TextWriter" does not care whether it
	#    is a file, the console or a string: that makes it easy to test and to reuse.
	oWriter = new StringWriter
	oWriter.WriteLine("first line")
	oWriter.Write("second ")
	oWriter.Write("line")
	oWriter.WriteLine(NULL)
	oWriter.WriteLine("third line")
	cText = substr(oWriter.ToString(),char(13),"")          # (Windows ends a line with two characters, Linux with one: the same text is shown)
	aLines = str2list(cText)
	? "1. the writer collected three lines of text:"
	for cLine in aLines
		if cLine != ""
			? "   " + cLine
		ok
	next

	# 2. StringReader reads a string line by line or all at once, like a file. Peek looks at the next character without taking it:
	#    -1 means that nothing is left
	oReader = new StringReader("alpha" + nl + "beta" + nl + "gamma")
	? nl + "2. reading line by line:"
	nNumber = 0
	while oReader.Peek() != -1
		nNumber++
		? "   " + nNumber + ": " + oReader.ReadLine()
	end
	oReader.Dispose()
	oRest = new StringReader("12 apples")
	? "   ReadToEnd gives the whole text: " + oRest.ReadToEnd()

	# 3. A function that writes its report to ANY writer. The same function is used for a string and for a file.
	? nl + "3. the same report function with two kinds of writer:"
	oToString = new StringWriter
	writeReport(oToString,"Ann",31)
	? "   to a string: " + substr(substr(oToString.ToString(),char(13),""),nl," | ")
	cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet_tutorial104.txt"])
	oFileWriter = new StreamWriter(cFile)
	writeReport(oFileWriter,"Bob",28)
	oFileWriter.Dispose()
	? "   to a file:   " + substr(substr(new File().ReadAllText(cFile),char(13),""),nl," | ")
	new File().Delete(cFile)

	# 4. Console.SetOut sends what a program writes with Console.WriteLine into a writer instead of the screen: that is how a test can
	#    check the output of code that prints. (Ring's own ? statement writes through the C library, not through Console.)
	oCapture = new StringWriter
	oConsole = new Console()
	oOld = oConsole.Out                    # the real console writer: it must be put back
	oConsole.SetOut(oCapture)
	oConsole.WriteLine("hidden message 1")
	oConsole.WriteLine("hidden message 2")
	oConsole.SetOut(oOld)
	? nl + "4. captured, not shown on the screen: " + substr(substr(oCapture.ToString(),char(13),""),nl," | ")

	# 5. Composite formatting: String.Format puts values into {0}, {1} places, with formats after a colon
	oString = new String()
	? nl + "5. " + oString.Format([ :format = "{0} bought {1} items for {2:0.00}", :args = ["Ann",3,12.5] ])
	? "   alignment: [" + oString.Format([ :format = "{0,-8}|{1,8}", :args = ["left","right"] ]) + "]"
	? "   padded numbers: " + oString.Format([ :format = "{0:00000} {1:0.0} {2:0.##}", :args = [42,255,0.25] ])

func writeReport oWriter,cName,nAge
	oWriter.WriteLine("name: " + cName)
	oWriter.WriteLine("age: " + nAge)
