# Tutorial 31: a project - find duplicate files (folders, hashes, dictionaries)
load "dotnetlib.ring"
using {
	"System"
	"System.IO"
	"System.Security.Cryptography"
	"System.Collections.Generic"
}

func main
	# STEP 1. A folder with some files: three of them have the same content, two others as well
	cFolder = new Path().Combine(new Path().GetTempPath(),"tutorial31")
	if new Directory().Exists(cFolder)
		new Directory().Delete([ :path = cFolder, :recursive = True ])
	ok
	new Directory().CreateDirectory(cFolder)
	new Directory().CreateDirectory(new Path().Combine(cFolder,"old"))
	makeFile(cFolder,"report.txt","Quarterly report: all good.")
	makeFile(cFolder,"report copy.txt","Quarterly report: all good.")
	makeFile(cFolder,"old/report 2023.txt","Quarterly report: all good.")
	makeFile(cFolder,"notes.txt","Remember to buy milk.")
	makeFile(cFolder,"todo.txt","Remember to buy milk, and eggs.")
	makeFile(cFolder,"old/notes backup.txt","Remember to buy milk.")
	? "STEP 1: made six files in a folder and its subfolder"

	# STEP 2. Find every file, also in the subfolders
	aFiles = new Directory().GetFiles_3(cFolder,"*.txt","AllDirectories").toList()
	? "STEP 2: " + len(aFiles) + " files found"

	# STEP 3. The fingerprint of a file is the hash of its content. Same content = same hash.
	#   A dictionary maps each hash to the files that have it (their paths, joined with | ).
	oGroups = new StringDictionary()
	for cFile in aFiles
		cHash = hashOf(cFile)
		aFound = oGroups.TryGetValue(cHash)
		if aFound[1]
			oGroups.SetItem(cHash,aFound[2] + "|" + cFile)
		else
			oGroups.SetItem(cHash,cFile)
		ok
	next
	? "STEP 3: " + oGroups.Count + " different contents"

	# STEP 4. Report the contents that exist more than once
	? nl + "STEP 4: duplicates"
	nWasted = 0
	for cHash in oGroups.Keys.toList()
		aPaths = str2list(substr(oGroups.Item(cHash),"|",nl))
		if len(aPaths) > 1
			nSize = new FileInfo(aPaths[1]).Length
			nWasted += nSize * (len(aPaths) - 1)
			? "   " + len(aPaths) + " copies of the same " + nSize + " bytes:"
			for cPath in sort(aPaths)
				? "      " + substr(cPath,cFolder + "\","")
			next
		ok
	next
	? "   Space wasted by the extra copies: " + nWasted + " bytes"

	# STEP 5. Clean up the demo folder
	new Directory().Delete([ :path = cFolder, :recursive = True ])

func makeFile cFolder, cName, cText
	cPath = new Path().Combine(cFolder,cName)
	new File().WriteAllText(cPath,cText)

# the SHA-256 hash of the content of a file, as text
func hashOf cFile
	return lower(new Convert().ToHexString(new SHA256().HashData(new File().ReadAllBytes(cFile))))
