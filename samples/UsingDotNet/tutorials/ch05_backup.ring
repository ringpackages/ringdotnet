# a project - a backup tool (zip a folder, name by date, keep the newest few, restore)
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.IO.Compression"
}

func main
	oPath = new Path()
	oDirectory = new Directory()
	oFile = new File()
	cWork = oPath.Combine([oPath.GetTempPath(),"ringdotnet_backup"])
	if oDirectory.Exists(cWork)
		oDirectory.Delete([ :path = cWork, :recursive = True ])
	ok
	cSource = oPath.Combine([cWork,"documents"])
	cBackups = oPath.Combine([cWork,"backups"])
	oDirectory.CreateDirectory(oPath.Combine([cSource,"notes"]))
	oDirectory.CreateDirectory(cBackups)
	oFile.WriteAllText([ :path = oPath.Combine([cSource,"report.txt"]), :contents = "Annual report" + nl + copies("lorem ipsum ",50) ])
	oFile.WriteAllText([ :path = oPath.Combine([cSource,"notes/todo.txt"]), :contents = "buy milk" ])
	? "The folder to protect has " + len(oDirectory.GetFiles([ :path = cSource, :searchPattern = "*", :searchOption = "AllDirectories" ]).toList()) + " files"

	# STEP 1. A backup is a zip file named with the date and time, so that the names sort in time order
	aStamps = ["2024-05-01_0900","2024-05-02_0900","2024-05-03_0900","2024-05-04_0900","2024-05-05_0900"]
	for cStamp in aStamps
		oFile.WriteAllText([ :path = oPath.Combine([cSource,"report.txt"]), :contents = "Annual report, version of " + cStamp + nl + copies("lorem ipsum ",50) ])
		makeBackup(cSource,cBackups,cStamp)
	next
	? nl + "STEP 1: five backups made:"
	showBackups(cBackups)

	# STEP 2. Keep only the newest 3: the names sort by time, so delete from the front of the sorted list
	nDeleted = keepNewest(cBackups,3)
	? nl + "STEP 2: removed " + nDeleted + " old backups, left:"
	showBackups(cBackups)

	# STEP 3. Restore the newest backup into a new folder and check that it has our latest report
	cRestore = oPath.Combine([cWork,"restored"])
	cLatest = restoreLatest(cBackups,cRestore)
	? nl + "STEP 3: restored " + oPath.GetFileName(cLatest)
	? "   the restored report says: " + left(oFile.ReadAllText(oPath.Combine([cRestore,"report.txt"])),38)
	? "   restored files: " + len(oDirectory.GetFiles([ :path = cRestore, :searchPattern = "*", :searchOption = "AllDirectories" ]).toList())

	oDirectory.Delete([ :path = cWork, :recursive = True ])

# STEP 1: zip the source folder to backups/backup-<stamp>.zip
func makeBackup cSource, cBackups, cStamp
	cZip = new Path().Combine([cBackups,"backup-" + cStamp + ".zip"])
	new ZipFile().CreateFromDirectory([ :sourceDirectoryName = cSource, :destinationArchiveFileName = cZip ])
	return cZip

# the backups, oldest first (the names sort the same way as the dates)
func listBackups cBackups
	return sort(new Directory().GetFiles([ :path = cBackups, :searchPattern = "backup-*.zip" ]).toList())

func showBackups cBackups
	for cFile in listBackups(cBackups)
		? "   " + new Path().GetFileName(cFile)
	next

# STEP 2: delete the oldest backups until only nKeep are left
func keepNewest cBackups, nKeep
	aList = listBackups(cBackups)
	nDeleted = 0
	for nIndex = 1 to len(aList) - nKeep
		new File().Delete(aList[nIndex])
		nDeleted++
	next
	return nDeleted

# STEP 3: unzip the newest backup into a folder
func restoreLatest cBackups, cFolder
	aList = listBackups(cBackups)
	cLatest = aList[len(aList)]
	new ZipFile().ExtractToDirectory([ :sourceArchiveFileName = cLatest, :destinationDirectoryName = cFolder ])
	return cLatest

func copies cText, nTimes
	cResult = ""
	for nIndex = 1 to nTimes
		cResult += cText
	next
	return cResult
