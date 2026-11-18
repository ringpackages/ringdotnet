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
	OSDeleteFolder("libraries/dotnetlib")
	OSDeleteFolder("samples/UsingDotNet")
	OSDeleteFolder("extensions/ringdotnet")
	chdir(cDir)

func startsWith cText, cStart
	return left(cText,len(cStart)) = cStart

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
