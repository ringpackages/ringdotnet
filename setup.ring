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
	ok
	chdir(cDir)
