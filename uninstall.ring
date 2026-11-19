# Removes the files that setup.ring extracted: the big folders at once, the other files from the list

func main
	? "Removing the RingDotNet package"
	cDir = CurrentDir()
	cRing = exefolder() + "../"
	chdir(cRing)
	cList = "extensions/ringdotnet/package-files.txt"
	if fexists(cList)
		aFiles = str2list(read(cList))
		for cFile in aFiles
			if cFile != "" and not startsWith(cFile,"libraries/dotnetlib/") and not startsWith(cFile,"samples/UsingDotNet/") and not startsWith(cFile,"extensions/ringdotnet/")
				remove(cFile)
			ok
		next
	ok
	if not isWindows() and fexists(cList)
		# the managed files that setup.ring copied to ring/lib
		for cFile in aFiles
			if isManagedFile(cFile)
				remove("lib/" + substr(cFile,"bin/",""))
			ok
		next
		OSDeleteFolder("lib/runtimes")
	ok
	OSDeleteFolder("libraries/dotnetlib")
	OSDeleteFolder("samples/UsingDotNet")
	OSDeleteFolder("extensions/ringdotnet")
	# the folders that the package made and that are empty now (bin/runtimes/win-x64/native ...); a folder that still has files stays
	for cFolder in emptyFolders(aFiles)
		OSDeleteEmptyFolder(cFolder)
	next
	chdir(cDir)

# a managed file of the package: a .dll or .json file in the bin folder itself (not in a sub folder), without the Windows libraries
func isManagedFile cFile
	if left(cFile,4) != "bin/" or substr(right(cFile,len(cFile) - 4),"/") > 0
		return false
	ok
	if cFile = "bin/ring_dotnet.dll" or cFile = "bin/e_sqlite3.dll"
		return false
	ok
	return right(cFile,4) = ".dll" or right(cFile,5) = ".json"

func startsWith cText, cStart
	return left(cText,len(cStart)) = cStart

# the folders of the listed files, the deepest first (the top folders bin, libraries, samples, tools and extensions are the Ring folders)
func emptyFolders aFiles
	aFolders = []
	for cFile in aFiles
		cFolder = cFile
		while substr(cFolder,"/") > 0
			cFolder = left(cFolder,len(cFolder) - len(lastPart(cFolder)) - 1)
			if substr(cFolder,"/") > 0 and find(aFolders,cFolder) = 0
				aFolders + cFolder
			ok
		end
	next
	aSorted = []
	for cFolder in aFolders
		aSorted + [len(cFolder),cFolder]
	next
	aSorted = sort(aSorted,1)
	aResult = []
	for nPos = len(aSorted) to 1 step -1
		aResult + aSorted[nPos][2]
	next
	return aResult

func lastPart cPath
	nPos = len(cPath)
	while nPos > 0 and cPath[nPos] != "/"
		nPos--
	end
	return right(cPath,len(cPath) - nPos)

# removes the folder only when it is empty (rd and rmdir without the option for contents)
func OSDeleteEmptyFolder cFolder
	if isWindows()
		systemSilent("rd " + substr(cFolder,"/","\") + " 2>nul")
	else
		systemSilent("rmdir " + cFolder + " 2>/dev/null")
	ok

func OSDeleteFolder cFolder
	if isWindows()
		systemSilent("rd /s /q " + substr(cFolder,"/","\"))
	else
		systemSilent("rm -r " + cFolder)
	ok

func SystemSilent cCmd
	if isWindows()
		system(cCmd + " >nul 2>nul")
	else
		system(cCmd + " > /dev/null")
	ok
