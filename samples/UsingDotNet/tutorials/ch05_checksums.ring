# a project: check that files did not change - a checksum list in the format of sha256sum, and a verify that finds changed, missing and new files
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Security.Cryptography"
}

func main

	oFile = new File()
	oPath = new Path()
	oDirectory = new Directory()

	# A work folder with a few files, some of them in a subfolder (it is removed at the end)
	cFolder = oPath.Combine([ oPath.GetTempPath(), "ringdotnet-sums-" + oPath.GetRandomFileName() ])
	oDirectory.CreateDirectory(cFolder + "/docs")
	oFile.WriteAllText([ :path = cFolder + "/readme.txt", :contents = "Read me" ])
	oFile.WriteAllText([ :path = cFolder + "/data.csv", :contents = "a,b" + nl + "1,2" + nl ])
	oFile.WriteAllText([ :path = cFolder + "/docs/guide.txt", :contents = "The guide" ])

	# A CHECKSUM is the hash of the bytes of a file (SHA-256 here): 64 hexadecimal characters that change when ONE bit of the file changes.
	# A list of the checksums of all the files of a folder lets anybody check, later, that nothing was changed, damaged or lost: after a
	# download, after a copy to another disk, after a year in an archive.
	? "1. the checksum of one file, readme.txt: " + checksumOf(cFolder + "/readme.txt")

	# 2. The list: one line for each file, "checksum, two spaces, the path with / and relative to the folder". This is the format of the
	#    programs sha256sum and shasum, so the list can be checked by them too. The paths are sorted.
	aList = makeList(cFolder)
	cListFile = cFolder + "/checksums.txt"
	oFile.WriteAllText([ :path = cListFile, :contents = listText(aList) ])
	? nl + "2. the list (the checksums are cut to 12 characters here):"
	for aItem in aList
		? "   " + left(aItem[1],12) + "...  " + aItem[2]
	next

	# 3. Verify, nothing changed. Each line of the list is checked: the file must exist and have the same checksum.
	? nl + "3. verify:"
	showResult(verify(cFolder,readList(cListFile)))

	# 4. Changes: a file is changed (one character), a file is deleted, and a new file appears
	oFile.WriteAllText([ :path = cFolder + "/readme.txt", :contents = "Read me!" ])
	oFile.Delete(cFolder + "/data.csv")
	oFile.WriteAllText([ :path = cFolder + "/docs/new.txt", :contents = "Something new" ])
	? nl + "4. after a change, a delete and a new file:"
	showResult(verify(cFolder,readList(cListFile)))

	# 5. The list must be protected too: somebody who changes a file can change its line in the list. The checksum of the LIST is kept
	#    somewhere else (written down, sent by another way). A list that was changed has another checksum.
	cListSum = checksumOf(cListFile)
	? nl + "5. the checksum of the list: " + left(cListSum,12) + "..."
	oFile.AppendAllText([ :path = cListFile, :contents = "# edited" + nl ])
	? "   after somebody edited the list the checksum is the same: " + yesNo(checksumOf(cListFile) = cListSum)

	oDirectory.Delete([ :path = cFolder, :recursive = True ])

# the SHA-256 checksum of a file as lower case hexadecimal text
func checksumOf cFile

	return lower(new Convert().ToHexString(new SHA256().HashData(new File().ReadAllBytes(cFile))))

# the paths (relative, with /) of all the files of a folder and its subfolders, sorted, without the list file itself
func relativeFiles cFolder

	aPaths = []
	nCut = len(cFolder) + 2
	aFiles = new Directory().GetFiles([ :path = cFolder, :searchPattern = "*", :searchOption = "AllDirectories" ]).toList()
	for cFile in aFiles
		cRelative = substr(substr(cFile,"\","/"),nCut)
		if cRelative != "checksums.txt"
			aPaths + cRelative
		ok
	next
	return sort(aPaths)

func makeList cFolder

	aList = []
	aRelatives = relativeFiles(cFolder)
	for cRelative in aRelatives
		aList + [ checksumOf(cFolder + "/" + cRelative), cRelative ]
	next
	return aList

func listText aList

	cText = ""
	for aItem in aList
		cText += aItem[1] + "  " + aItem[2] + nl
	next
	return cText

# the list from its file: each line is the checksum (64 characters), two spaces and the path
func readList cListFile

	aList = []
	aLines = new File().ReadAllLines(cListFile).toList()
	for cLine in aLines
		if len(cLine) > 66 and left(cLine,1) != "#"
			aList + [ left(cLine,64), substr(cLine,67) ]
		ok
	next
	return aList

# the problems: changed files, missing files and new files (the files that the list does not know)
func verify cFolder,aList

	aProblems = []
	aKnown = []
	for aItem in aList
		aKnown + aItem[2]
		cFile = cFolder + "/" + aItem[2]
		if not new File().Exists(cFile)
			aProblems + [ "MISSING",aItem[2] ]
		but checksumOf(cFile) != aItem[1]
			aProblems + [ "CHANGED",aItem[2] ]
		ok
	next
	aRelatives = relativeFiles(cFolder)
	for cRelative in aRelatives
		if find(aKnown,cRelative) = 0
			aProblems + [ "NEW",cRelative ]
		ok
	next
	return [ len(aList),aProblems ]

func showResult aResult

	nChecked = aResult[1]
	aProblems = aResult[2]
	if len(aProblems) = 0
		? "   all " + nChecked + " files are as they were"
	else
		for aItem in aProblems
			? "   " + padRight(aItem[1],8) + aItem[2]
		next
		? "   " + len(aProblems) + " problems in " + nChecked + " files of the list"
	ok

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"

func padRight cText,nWidth

	return cText + copy(" ",nWidth - len(cText))
