# Installing the package = extracting one zip file into the Ring folder (faster than copying thousands of files)
load "ziplib.ring"

func main
	? "Extracting File : ringdotnet.zip"
	cDir = CurrentDir()
	chdir(exefolder()+"../extensions")
	zip_extract_allfiles("ringdotnet.zip","..")
	remove("ringdotnet.zip")
	if not isWindows()
		? "RingDotNet: the extension (ring_dotnet) must be built for this system - see extensions/ringdotnet/README.md"
		# ring2exe (Linux and macOS) and the extension look for the managed files next to the library, in ring/lib: they are copied there too
		chdir(exefolder()+"../")
		systemSilent("mkdir -p lib")
		for cFile in str2list(read("extensions/ringdotnet/package-files.txt"))
			if isManagedFile(cFile)
				systemSilent("cp " + cFile + " lib/")
			ok
		next
		systemSilent("cp -r bin/runtimes lib/")
	ok
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
