# Builds extensions/ringdotnet.zip: the package files, with the paths they have inside the Ring folder.
#
# RingPM copies this one zip into ring/extensions (one file instead of thousands) and setup.ring extracts it into the Ring folder. Run it again whenever the
# library, the samples, the DLLs or the tests change:
#     ring tools/dotnettools/makepackage.ring
#
# This is plain Ring: the tool that packs the package does not use the package (a bridge that does not work must not stop the packing). The zip is written with
# RingZip, the library that setup.ring extracts it with. The files are the ones that git tracks (git ls-files) under the folders of the package.
load "ziplib.ring"

C_PREFIXES = ["libraries/","extensions/ringdotnet/","samples/","tools/","bin/"]
C_MANIFEST = "extensions/ringdotnet/package-files.txt"          # the list of the files (used by uninstall.ring)

func main

	# the root of the repository: two folders above this program
	cProgram = substr(sysargv[2],"\","/")
	nSlash = 0
	for nChar = 1 to len(cProgram)
		if cProgram[nChar] = "/"
			nSlash = nChar
		ok
	next
	if nSlash > 0
		chdir(left(cProgram,nSlash - 1) + "/../..")
	else
		chdir("../..")
	ok
	aFiles = packageFiles()
	cList = ""
	for cFile in aFiles
		cList += cFile + nl
	next
	cList += C_MANIFEST + nl
	cTarget = "extensions/ringdotnet.zip"
	oZip = zip_openfile(cTarget,'w')
	# the folders first: the extractor of RingZip needs them
	aFolders = folderList(aFiles)
	for cFolder in aFolders
		zip_entry_open(oZip,cFolder)
		zip_entry_close(oZip)
	next
	for cFile in aFiles
		zip_addfile(oZip,cFile)
	next
	zip_entry_open(oZip,C_MANIFEST)
	zip_entry_write(oZip,cList,len(cList))
	zip_entry_close(oZip)
	zip_close(oZip)
	nBytes = len(read(cTarget))
	? "" + (len(aFiles) + 1) + " files, " + (floor(nBytes / 104857.6 + 0.5) / 10) + " MB -> " + currentdir() + "/" + cTarget

# The files of the package: what git tracks under the folders of C_PREFIXES, sorted, and still on the disk
func packageFiles

	cOutput = tempFolder() + "/ringdotnet_makepackage_files.txt"
	system("git -c core.quotepath=off ls-files > " + cOutput)
	aLines = str2list(read(cOutput))
	remove(cOutput)
	aFiles = []
	for cLine in aLines
		cLine = trim(cLine)
		if cLine != ""
			for cPrefix in C_PREFIXES
				if left(cLine,len(cPrefix)) = cPrefix
					if fexists(cLine)
						aFiles + cLine
					ok
					exit
				ok
			next
		ok
	next
	return sort(aFiles)

# Every folder that holds a file, with the folders above it: "a/b/c.txt" gives "a/" and "a/b/", sorted
func folderList aFiles

	aSeen = []
	aFolders = []
	for cFile in aFiles
		cFolder = ""
		nStart = 1
		nLength = len(cFile)
		for nChar = 1 to nLength
			if cFile[nChar] = "/"
				cFolder = left(cFile,nChar)
				if find(aSeen,cFolder) = 0
					aSeen + cFolder
					aFolders + cFolder
				ok
			ok
		next
	next
	return sort(aFolders)

func tempFolder

	cFolder = sysget("TEMP")
	if cFolder = ""
		cFolder = sysget("TMPDIR")
	ok
	if cFolder = ""
		cFolder = "/tmp"
	ok
	return substr(cFolder,"\","/")
