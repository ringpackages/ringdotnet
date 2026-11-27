# Screenshots of the tutorial programs: docs/img/shots/tut-<name>.png (Windows; uses ring-cffi, see shootlib.ring)
# Some shots need the program in a later state: the code of tutorialshots.ring runs just before the window is shown (in a temporary copy).
#
#     cd docs/tools
#     ring shoot_tutorials.ring [shot name ...]        (no names: every shot)

load "shootlib.ring"
load "tutorialshots.ring"

func main

	cHere = programFolder()
	cDocs = parentFolder(cHere)
	cTut = parentFolder(cDocs) + "/samples/UsingDotNet/tutorials"
	cOut = cDocs + "/img/shots"
	aOnly = []
	nArgs = len(sysargv)
	for nArg = 3 to nArgs
		aOnly + sysargv[nArg]
	next
	nShots = len(aTutorialShots)
	for nShot = 1 to nShots
		aShot = aTutorialShots[nShot]
		cProgram = aShot[1]
		cName = aShot[2]
		cMarker = substr(substr(aShot[3],"{tab}",char(9)),"{nl}",nl)
		cCode = substr(substr(aShot[4],"{tab}",char(9)),"{nl}",nl)
		if len(aOnly) > 0 and find(aOnly,cName) = 0
			loop
		ok
		cScript = cProgram
		if cMarker != ""
			cSource = readText(cTut + "/" + cProgram)
			nAt = substr(cSource,cMarker)
			if nAt = 0
				? "MARKER NOT FOUND " + cName + " in " + cProgram
				loop
			ok
			cSource = left(cSource,nAt - 1) + cCode + tail(cSource,nAt)
			cScript = "_shot_" + cProgram
			write(cTut + "/" + cScript,cSource)
		ok
		? shootWindow(cTut,cScript,cOut + "/tut-" + cName + ".png",aShot[5],"")
		if cMarker != ""
			remove(cTut + "/" + cScript)
		ok
	next
