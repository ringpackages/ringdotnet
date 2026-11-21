# Watching a folder - FileSystemWatcher: waiting for files to be created, changed, renamed and deleted
#   ring ch05_watch_folder.ring            the parent: it watches a folder and starts a second copy of this program (the child) that changes it
#   ring ch05_watch_folder.ring --child    the child (the parent starts it, you do not)
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Diagnostics"
	"System.Threading.Tasks"
}

func main
	if find(sysargv,"--child") > 0
		child(sysargv[len(sysargv)])
		return
	ok

	# A FileSystemWatcher tells a program that something happened in a folder: a file was created, changed, renamed or deleted. A program
	# that shows the files of a folder, a build tool that starts when a source file is saved, or a program that waits for files to arrive
	# in a folder uses it, instead of looking at the folder again and again.

	# 1. A folder to watch. The name comes from the system (it is different each time), so the program prints only what is the same each time.
	oPath = new Path()
	cFolder = oPath.Combine([ oPath.GetTempPath(), "ringdotnet-watch-" + oPath.GetRandomFileName() ])
	oDirectory = new Directory()
	oDirectory.CreateDirectory(cFolder)
	? "1. a folder to watch was created"

	# 2. The watcher: the folder, and the file names that interest us ("*.txt"). IncludeSubdirectories = True would watch the folders below too.
	oWatcher = new FileSystemWatcher().@New([ :path = cFolder, :filter = "*.txt" ])
	oWatcher.IncludeSubdirectories = False
	? "2. watching: " + oWatcher.Filter + ", subfolders: no"

	# 3. Start the child. It waits a moment, and then it creates a file, writes into it, renames it and deletes it, with a pause
	#    between the steps.
	oInfo = new ProcessStartInfo().@New([ :fileName = exefilename(), :arguments = '"' + filename() + '" --child "' + cFolder + '"' ])
	oInfo.UseShellExecute = False
	oInfo.CreateNoWindow = True
	oChild = new Process().Start(oInfo)
	? "3. the child was started"

	# 4. Wait for the changes. WaitForChanged waits for the next change (or for the time limit, here 4 seconds) and returns what happened.
	#    A change that happens while the program is NOT waiting is not reported: this is why the child makes a pause between the steps.
	? nl + "4. what happened:"
	aSeen = []
	while True
		oResult = oWatcher.WaitForChanged([ :changeType = "All", :timeout = 4000 ])
		if oResult.TimedOut
			exit
		ok
		cLine = describe(oResult)
		# one write can raise a few "Changed" events: the same line is printed once
		if len(aSeen) = 0 or aSeen[len(aSeen)] != cLine
			? "   " + cLine
			aSeen + cLine
		ok
		if oResult.ChangeType = "Deleted"
			exit
		ok
	end
	oChild.WaitForExit(5000)

	# 5. Clean up
	oWatcher.Dispose()
	oDirectory.Delete([ :path = cFolder, :recursive = True ])
	? nl + "5. the folder was deleted; the child's exit code: " + oChild.ExitCode

# what a change tells: the kind of change and the name (a rename also has the old name)
func describe oResult
	cKind = "" + oResult.ChangeType
	if cKind = "Renamed"
		return "Renamed   " + oResult.OldName + " -> " + oResult.Name
	ok
	return padRight(cKind,10) + oResult.Name

func padRight cText,nWidth
	return cText + copy(" ",nWidth - len(cText))

# ---------------------------------------------------------------- the child
func child cFolder
	oFile = new File()
	pause(1000)
	oFile.WriteAllText([ :path = cFolder + "/note.txt", :contents = "first" ])
	pause(600)
	oFile.AppendAllText([ :path = cFolder + "/note.txt", :contents = " and more" ])
	pause(600)
	oFile.Move([ :sourceFileName = cFolder + "/note.txt", :destFileName = cFolder + "/done.txt" ])
	pause(600)
	oFile.WriteAllText([ :path = cFolder + "/ignored.log", :contents = "not a .txt file" ])    # the filter *.txt does not match: no event
	pause(600)
	oFile.Delete(cFolder + "/done.txt")

func pause nMilliseconds
	new Task().Delay(nMilliseconds).Wait(NULL)
