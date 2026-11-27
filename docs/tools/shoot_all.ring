# Captures a screenshot of every GUI sample and application: docs/img/shots/<kind>-<name>.png (Windows; uses ring-cffi, see shootlib.ring)
#
#     cd docs/tools
#     ring shoot_all.ring [forms] [wpf] [apps]        (no names: all three)

load "shootlib.ring"

func main

	cHere = programFolder()
	cDocs = parentFolder(cHere)
	cRoot = parentFolder(cDocs)
	cSamples = cRoot + "/samples/UsingDotNet"
	cOut = cDocs + "/img/shots"
	aKinds = []
	nArgs = len(sysargv)
	for nArg = 3 to nArgs
		aKinds + sysargv[nArg]
	next
	if len(aKinds) = 0
		aKinds = ["forms","wpf","apps"]
	ok
	if find(aKinds,"forms") > 0
		aFiles = listNames(cSamples + "/Forms")
		for cFile in aFiles
			if not hasSuffix(cFile,".ring")
				loop
			ok
			cName = left(cFile,len(cFile) - 5)
			if cName = "33_color_wheel" or cName = "34_mandelbrot"
				? shootWindow(cSamples + "/Forms",cFile,cOut + "/forms-" + cName + ".png",3500,"--draw")
			else
				? shootWindow(cSamples + "/Forms",cFile,cOut + "/forms-" + cName + ".png",2500,"")
			ok
		next
	ok
	if find(aKinds,"wpf") > 0
		aFiles = listNames(cSamples + "/Wpf")
		for cFile in aFiles
			if not hasSuffix(cFile,".ring")
				loop
			ok
			cName = left(cFile,len(cFile) - 5)
			? shootWindow(cSamples + "/Wpf",cFile,cOut + "/wpf-" + cName + ".png",3500,"")
		next
	ok
	if find(aKinds,"apps") > 0
		aDirs = listNames(cSamples + "/applications")
		for cDir in aDirs
			if cDir = "WebApi" or cDir = "Contacts"
				loop
			ok
			cMain = cSamples + "/applications/" + cDir + "/" + cDir + ".ring"
			if fexists(cMain) and substr(read(cMain),"dnUseDesktop") > 0
				? shootWindow(cSamples + "/applications/" + cDir,cDir + ".ring",cOut + "/app-" + cDir + ".png",3500,"")
			ok
		next
	ok
