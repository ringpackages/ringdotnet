# Tutorial 52: logging - levels, timestamps, a file, rotation, and what to write
load "dotnet.ring"
using {
	"System"
	"System.IO"
}

func main
	cFolder = new Path().Combine(new Path().GetTempPath(),"tutorial52")
	if new Directory().Exists(cFolder)
		new Directory().Delete([ :path = cFolder, :recursive = True ])
	ok
	new Directory().CreateDirectory(cFolder)
	cFile = new Path().Combine(cFolder,"app.log")

	# 1. A logger writes lines: time, level, message. The level says how important a line is.
	oLog = new Logger(cFile)
	oLog.setClock("2024-05-17 08:00:00")                    # a fixed time: the output of the tutorial is the same every run
	oLog.info("the program started")
	oLog.debug("a detail: this line is not written (the minimum level is INFO)")
	oLog.warn("the disk is 91% full")
	oLog.error("could not open the report")
	? "1. The file after four calls:"
	? "   " + substr(new File().ReadAllText(cFile),windowsnl(),nl + "   ")

	# 2. The minimum level: a program in development wants everything, a program in production only problems
	oLog.setLevel("DEBUG")
	oLog.debug("now debug lines are written too")
	oLog.setLevel("ERROR")
	oLog.info("this line is NOT written")
	oLog.error("this one is")
	? nl + "2. Lines in the file now: " + len(new File().ReadAllLines(cFile).toList())

	# 3. Errors are the reason for logs: write the error text of a failure, and keep going
	try
		new Int32().Parse("abc")
	catch
		oLog.error("a number could not be read: " + left(cCatchError,60))
	done
	? nl + "3. The last line: " + new File().ReadAllLines(cFile).toList()[len(new File().ReadAllLines(cFile).toList())]

	# 4. Rotation: a log must not grow forever. When the file is too big it is renamed and a new one starts.
	oSmall = new Logger(new Path().Combine(cFolder,"small.log"))
	oSmall.setClock("2024-05-17 09:00:00")
	oSmall.setMaxSize(300)                                  # bytes: tiny, to see the rotation
	for nLine = 1 to 12
		oSmall.info("message number " + nLine + " with some more text to fill the file")
	next
	? nl + "4. Files in the folder after 12 messages with a limit of 300 bytes:"
	for cName in sort(new Directory().GetFiles_2(cFolder,"small*").toList())
		? "   " + new Path().GetFileName(cName)
	next
	new Directory().Delete([ :path = cFolder, :recursive = True ])

# A logger as a Ring class: the settings are attributes, the behaviour is in the methods
class Logger

	cFile = ""
	cClock = ""            # when set, this text is the time of every line (for tests); empty: the real time
	nLevel = 2             # DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4
	nMaxSize = 0           # 0: no limit

	func init cPath
		cFile = cPath

	func setClock cText
		cClock = cText

	func setLevel cLevel
		nLevel = levelNumber(cLevel)

	func setMaxSize nBytes
		nMaxSize = nBytes

	func debug cMessage
		write("DEBUG",cMessage)

	func info cMessage
		write("INFO ",cMessage)

	func warn cMessage
		write("WARN ",cMessage)

	func error cMessage
		write("ERROR",cMessage)

	func levelNumber cLevel
		cLevel = upper(trim(cLevel))
		if cLevel = "DEBUG"
			return 1
		but cLevel = "INFO"
			return 2
		but cLevel = "WARN"
			return 3
		ok
		return 4

	# one line: "2024-05-17 08:00:00 INFO  the program started"
	func write cLevel, cMessage
		if levelNumber(cLevel) < nLevel
			return
		ok
		rotateIfNeeded()
		cTime = cClock
		if cTime = ""
			cTime = new DateTime(2000,1,1).Now.ToString_1("yyyy-MM-dd HH:mm:ss")
		ok
		new File().AppendAllText(cFile,cTime + " " + cLevel + " " + cMessage + windowsnl())

	# when the file is bigger than the limit: app.log becomes app.log.1 (an older .1 is replaced), and a new file starts
	func rotateIfNeeded
		if nMaxSize = 0 or not new File().Exists(cFile)
			return
		ok
		if new FileInfo(cFile).Length > nMaxSize
			cOld = cFile + ".1"
			if new File().Exists(cOld)
				new File().Delete(cOld)
			ok
			new File().Move(cFile,cOld)
		ok
