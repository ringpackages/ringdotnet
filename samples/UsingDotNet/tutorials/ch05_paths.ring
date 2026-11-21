# paths and the environment - building paths safely, splitting them, special folders and environment variables
load "dotnet.ring"
using {
	"System"
	"System.IO"
}

func main
	oPath = new Path()

	# 1. Build a path with Combine, never with + "\": Combine uses the right separator for the system and never doubles it
	cFile = oPath.Combine(["reports","2024","january.txt"])
	? "1. Combine: " + cFile
	? "   Combine with a rooted second part restarts the path: " + oPath.Combine(["reports","/etc/hosts"])

	# 2. Take a path apart
	cFull = "C:\data\reports\2024\summary.final.txt"
	? nl + "2. file name      : " + oPath.GetFileName(cFull)
	? "   without suffix : " + oPath.GetFileNameWithoutExtension(cFull)
	? "   extension      : " + oPath.GetExtension(cFull)
	? "   folder         : " + oPath.GetDirectoryName(cFull)
	? "   change the extension: " + oPath.ChangeExtension(cFull,".csv")

	# 3. A path can be relative (to the current folder) or absolute (complete): GetFullPath makes it absolute
	cAbsolute = oPath.GetFullPath("data.txt")
	? nl + "3. is 'data.txt' rooted? " + yesNo(oPath.IsPathRooted("data.txt")) + "; its full path is rooted? " + yesNo(oPath.IsPathRooted(cAbsolute))
	? "   it ends with the same name: " + yesNo(oPath.GetFileName(cAbsolute) = "data.txt")

	# 4. Characters a file name may not contain
	cBad = "report: 1/2?.txt"
	cGood = cBad
	for cChar in ["\","/",":","*","?",'"',"<",">","|"]       # the characters Windows does not allow in a name
		cGood = substr(cGood,cChar,"_")
	next
	? nl + "4. '" + cBad + "' becomes '" + cGood + "'"

	# 5. Special folders: do not write the user's name into your code, ask the system
	oEnvironment = new Environment()
	cDocuments = oEnvironment.GetFolderPath("MyDocuments")
	? nl + "5. the documents folder exists? " + yesNo(new Directory().Exists(cDocuments))
	? "   the temporary folder exists? " + yesNo(new Directory().Exists(oPath.GetTempPath()))

	# 6. Environment variables: settings from outside (a password, a folder, a mode). Always provide a default.
	oEnvironment.SetEnvironmentVariable([ :variable = "RINGDOTNET_MODE", :value = "fast" ])
	? nl + "6. RINGDOTNET_MODE = " + oEnvironment.GetEnvironmentVariable("RINGDOTNET_MODE")
	cMissing = oEnvironment.GetEnvironmentVariable("RINGDOTNET_NOT_SET")
	if isobject(cMissing)                                 # .NET null comes to Ring as an object that IsNull()
		cMissing = "(default)"
	ok
	? "   a variable that is not set: " + cMissing
	oEnvironment.SetEnvironmentVariable([ :variable = "RINGDOTNET_MODE", :value = NULL ])

	# 7. The system: which one runs the program
	? nl + "7. 64-bit process? " + yesNo(oEnvironment.Is64BitProcess) + ", the new line is " + len(oEnvironment.NewLine) + " character(s) long"

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
