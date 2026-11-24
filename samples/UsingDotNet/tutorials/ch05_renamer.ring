# a project: rename many files - rules (replace, regular expression, case, numbering), a preview, conflict checks and undo
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Text.RegularExpressions"
}

func main

	oFile = new File()
	oPath = new Path()
	oDirectory = new Directory()

	# A work folder with some files with untidy names (it is removed at the end)
	cFolder = oPath.Combine([ oPath.GetTempPath(), "ringdotnet-rename-" + oPath.GetRandomFileName() ])
	oDirectory.CreateDirectory(cFolder)
	for cName in [ "IMG 0042 holiday.JPG", "IMG 0043 holiday.JPG", "IMG 0050 Beach Trip.jpg", "report final (copy).TXT", "report final.txt", "notes.md" ]
		oFile.WriteAllText([ :path = cFolder + "/" + cName, :contents = "x" ])
	next

	# A tool that renames many files must be CAREFUL: a wrong rule can damage hundreds of names. So it works in four steps:
	#   1. list the names,  2. make the new names with a RULE and show them (a PREVIEW, nothing is renamed yet),
	#   3. refuse when two files would get the same name,  4. rename, and keep a LOG so that everything can be undone.
	aNames = fileNames(cFolder)
	? "1. the files:"
	for cName in aNames
		? "   " + cName
	next

	# 2. A rule is a function from a name to a new name. Four kinds of rules are made by small functions that return a rule (a text of
	#    the kind and its values), and one function applies it.
	? nl + "2. rule: replace the spaces with underscores, and write the name in lower case"
	aRule = [ [ "replace"," ","_" ], [ "lower" ] ]
	showPreview(aNames,aRule)

	? nl + "3. rule: remove the word final (a regular expression: spaces and the word) and write lower case"
	aRule = [ [ "regex","\s*final","" ], [ "lower" ] ]
	showPreview(aNames,aRule)

	? nl + "4. rule: numbering, 'holiday-01.jpg' for the files that have the word holiday"
	aHoliday = []
	for cName in aNames
		if substr(lower(cName),"holiday") > 0
			aHoliday + cName
		ok
	next
	aRule = [ [ "number","holiday-","jpg",2 ] ]
	showPreview(aHoliday,aRule)

	# 5. Conflicts. Removing "(copy)" from "report final (copy).TXT" and making lower case gives the name of another file:
	#    two files with one name cannot exist, so the tool refuses before it renames anything.
	? nl + "5. a rule that makes two files have the same name (copy removed, lower case):"
	aRule = [ [ "regex","\s*\(copy\)","" ], [ "lower" ] ]
	aPlan = makePlan(aNames,aRule)
	aProblems = findConflicts(aPlan,aNames)
	for cProblem in aProblems
		? "   problem: " + cProblem
	next
	? "   the tool renames nothing when there is a problem: " + yesNo(len(aProblems) > 0)

	# 6. A good rule: spaces to underscores and lower case. No conflicts, so rename. The log keeps [old, new] for each file.
	aRule = [ [ "replace"," ","_" ], [ "lower" ] ]
	aPlan = makePlan(aNames,aRule)
	aProblems = findConflicts(aPlan,aNames)
	? nl + "6. the rule of step 2: " + len(aProblems) + " problems"
	aLog = applyPlan(cFolder,aPlan)
	? "   renamed " + len(aLog) + " files; now the folder has:"
	aFileNames = fileNames(cFolder)
	for cName in aFileNames
		? "   " + cName
	next

	# 7. Undo: the log in reverse order puts every name back
	undoLog(cFolder,aLog)
	? nl + "7. after undo the folder has the first names again: " + yesNo(sameList(fileNames(cFolder),aNames))

	oDirectory.Delete([ :path = cFolder, :recursive = True ])

# the names of the files of a folder, sorted (the folder order is not defined)
func fileNames cFolder

	aList = []
	aItems = new DirectoryInfo(cFolder).GetFiles(NULL).toList()
	for oItem in aItems
		aList + oItem.Name
	next
	return sort(aList)

# split "name.ext" into the name and the extension (the extension starts at the last dot)
func splitName cName

	nDot = 0
	for i = len(cName) to 1 step -1
		if substr(cName,i,1) = "."
			nDot = i
			exit
		ok
	next
	if nDot = 0
		return [ cName, "" ]
	ok
	return [ left(cName,nDot - 1), substr(cName,nDot + 1) ]

# one rule applied to the name part (the extension is kept, except by "extension")
func applyRule aItem,cBase,cExtension

	cKind = aItem[1]
	if cKind = "replace"
		cBase = substr(cBase,aItem[2],aItem[3])
	but cKind = "regex"
		cBase = dnStatic("System.Text.RegularExpressions.Regex","Replace",[ cBase, aItem[2], aItem[3] ])
	but cKind = "lower"
		cBase = lower(cBase)
		cExtension = lower(cExtension)
	but cKind = "upper"
		cBase = upper(cBase)
	ok
	return [ cBase, cExtension ]

# the new names of a list of names: a list of [old, new]
func makePlan aNames,aRule

	aPlan = []
	nNumber = 0
	for cName in aNames
		aParts = splitName(cName)
		cBase = aParts[1]
		cExtension = aParts[2]
		for aItem in aRule
			if aItem[1] = "number"
				nNumber++
				cBase = aItem[2] + right("000" + nNumber,aItem[4])
				cExtension = aItem[3]
			else
				aResult = applyRule(aItem,cBase,cExtension)
				cBase = aResult[1]
				cExtension = aResult[2]
			ok
		next
		cNew = cBase
		if cExtension != ""
			cNew += "." + cExtension
		ok
		aPlan + [ cName, cNew ]
	next
	return aPlan

func showPreview aNames,aRule

	aItems = makePlan(aNames,aRule)
	for aItem in aItems
		? "   " + padRight(aItem[1],26) + "-> " + aItem[2]
	next

# problems that stop the renaming: two files with one new name, a new name that is the name of a file that stays, or an empty name
func findConflicts aPlan,aAllNames

	aProblems = []
	aTaken = []
	for aItem in aPlan
		cNew = aItem[2]
		if cNew = ""
			aProblems + (aItem[1] + " would get an empty name")
		ok
		if find(aTaken,lower(cNew)) > 0
			aProblems + ("two files would be named " + cNew)
		ok
		aTaken + lower(cNew)
	next
	return aProblems

# rename (a file whose name does not change is skipped) and return the log of what was done
func applyPlan cFolder,aPlan

	aLog = []
	for aItem in aPlan
		if aItem[1] != aItem[2]
			new File().Move([ :sourceFileName = cFolder + "/" + aItem[1], :destFileName = cFolder + "/" + aItem[2] ])
			aLog + [ aItem[1], aItem[2] ]
		ok
	next
	return aLog

# undo: the same moves, the other way and the last one first
func undoLog cFolder,aLog

	for i = len(aLog) to 1 step -1
		new File().Move([ :sourceFileName = cFolder + "/" + aLog[i][2], :destFileName = cFolder + "/" + aLog[i][1] ])
	next

func sameList aFirst,aSecond

	if len(aFirst) != len(aSecond)
		return False
	ok
	for i = 1 to len(aFirst)
		if aFirst[i] != aSecond[i]
			return False
		ok
	next
	return True

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"

func padRight cText,nWidth

	return cText + copy(" ",nWidth - len(cText))
