# Checks a change of the generator, the bridge or the manifest before it is committed.
#
#     ring tools/dotnettools/checkgenerator.ring                  regenerate the library, then run every check
#     ring tools/dotnettools/checkgenerator.ring --no-generate    the checks only (the library is as it is)
#     ring tools/dotnettools/checkgenerator.ring --allow-large    a big change of the generated files is expected (a new rule of the generator)
#     ring tools/dotnettools/checkgenerator.ring --all-packages   also the package tests (all of them: about ten minutes)
#     ring tools/dotnettools/checkgenerator.ring --no-docs        leave out the check of the documentation (it takes about 30 seconds)
#     ring tools/dotnettools/checkgenerator.ring --update-baseline   write the number of types without a class as the new baseline
#     --max-files N and --max-lines N change the limits of the size of the change (15 files, 600 lines)
#
# The checks, in order:
#   1. gendotnet.ring makes the whole library (without errors).
#   2. The size of the change of the generated files (files and lines against the last commit, and the kinds of line that changed: read them, a rule that
#      copies methods into derived classes shows here as thousands of added lines).
#   3. importall.ring imports every namespace of the manifest: every generated file loads.
#   4. The tests that use the generated classes most (the classes of the library, extension methods, generic types, keywords, your own assembly).
#   5. A few package tests whose classes are made again by the generator now (fluent calls in callbacks, generic pipelines, properties named like Ring
#      words, generic extension methods). The cache of a package is made again when the generator, the bridge or the library changed.
#   6. The number of public types that have no class (auditcoverage.ring) against tools/dotnettools/coverage-baseline.txt: it must not grow.
#   7. The documentation is made again (docs/tools/dumpapi.ring and build.ring) and the generated files that differ from the last commit are counted:
#      a change of the classes changes the class reference, and those files belong to the same commit.
# The exit code is not set by Ring: the last line says how many checks failed.
#
# This is plain Ring: the tool that checks the package does not use the package (a bridge that does not work must not stop the check). The programs that
# need the bridge (the generator, the tests) are started as programs of their own with the same ring that runs this one.

C_GENERATED = "libraries/dotnetlib/generated"
aLibraryTests = ["test_foundation.ring","test_collections.ring","test_extension_methods.ring","test_classindex.ring","test_more_classes.ring","test_web_runtime.ring","test_odbc_sqlitepcl.ring","test_userassembly.ring"]
aPackageTests = ["pkgtest_questpdf.ring","pkgtest_mlnet_chess.ring","pkgtest_esprima.ring","pkgtest_fluentvalidation.ring"]

cRoot = ""
cRing = ""
nChecks = 0
aFailed = []

func main

	cRing = exefilename()
	lGenerate = true
	lLarge = false
	lAllPackages = false
	lUpdate = false
	lDocs = true
	nMaxFiles = 15
	nMaxLines = 600
	nArgs = len(sysargv)
	for nArg = 3 to nArgs
		switch sysargv[nArg]
		on "--no-generate"
			lGenerate = false
		on "--allow-large"
			lLarge = true
		on "--all-packages"
			lAllPackages = true
		on "--update-baseline"
			lUpdate = true
		on "--no-docs"
			lDocs = false
		on "--max-files"
			nMaxFiles = number(sysargv[nArg + 1])
		on "--max-lines"
			nMaxLines = number(sysargv[nArg + 1])
		off
	next
	if lLarge
		nMaxFiles = 1000000
		nMaxLines = 1000000000
	ok
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
	cRoot = substr(currentdir(),"\","/")
	nStart = clock()
	if lGenerate
		if not checkGenerate()
			? "the library could not be made: the other checks are skipped"
			return
		ok
	ok
	checkSize(nMaxFiles,nMaxLines)
	checkImport()
	for cTest in aLibraryTests
		checkTest(cRoot + "/samples/UsingDotNet/tests",cTest)
	next
	for cTest in aPackageTests
		checkTest(cRoot + "/samples/UsingDotNet/tests/packages",cTest)
	next
	if lAllPackages
		checkAllPackages()
	ok
	checkCoverage(lUpdate)
	if lDocs
		checkDocs()
	ok
	? nl + nChecks + " checks, " + len(aFailed) + " failed (" + floor((clock() - nStart) / clockspersecond()) + " seconds)"
	for cName in aFailed
		? "  FAILED: " + cName
	next

# ---------------------------------------------------------------- the checks

func checkGenerate

	aRun = runIn(cRoot + "/tools/dotnettools",'"' + cRing + '" gendotnet.ring')
	lFailed = hasError(aRun[1])
	cDetail = "" + floor(aRun[2]) + " seconds"
	if lFailed
		cDetail = firstLine(aRun[1])
	ok
	report("generate the library",not lFailed,cDetail)
	return not lFailed

func checkSize nMaxFiles, nMaxLines

	aNumstat = lines(gitOutput("diff --numstat -- " + C_GENERATED))
	nFiles = 0
	nAdded = 0
	nRemoved = 0
	for cLine in aNumstat
		aParts = str2list(substr(cLine,char(9),nl))
		if len(aParts) >= 3
			nFiles++
			nAdded += number(aParts[1])
			nRemoved += number(aParts[2])
		ok
	next
	aStatus = lines(gitOutput("status --short -- " + C_GENERATED))
	for cLine in aStatus
		if left(cLine,2) = "??"
			nFiles++
		ok
	next
	lOk = (nFiles <= nMaxFiles) and (nAdded + nRemoved <= nMaxLines)
	report("the change of the generated files",lOk,"" + nFiles + " files changed or new, " + nAdded + " lines added, " + nRemoved + " removed (limits: " + nMaxFiles + " files, " + nMaxLines + " lines; --allow-large for a new rule)")
	if nFiles > 0
		printKinds(gitOutput("diff -U0 -- " + C_GENERATED))
	ok
	return lOk

# The kinds of line that changed: the lines with the names between quotes and after Func or Class replaced, counted, the most common ones first
func printKinds cDiff

	aKinds = []
	aCounts = []
	for cLine in lines(cDiff)
		if len(cLine) > 0 and (cLine[1] = "+" or cLine[1] = "-") and left(cLine,3) != "+++" and left(cLine,3) != "---"
			cKey = cLine[1] + kindOf(trim(substr(right(cLine,len(cLine) - 1),char(9)," ")))
			nPlace = find(aKinds,cKey)
			if nPlace = 0
				aKinds + cKey
				aCounts + 1
			else
				aCounts[nPlace] += 1
			ok
		ok
	next
	? "      the kinds of line that changed (count, line):"
	nShown = 0
	while nShown < 8 and len(aKinds) > 0
		nBest = 1
		nKinds = len(aKinds)
		for nPlace = 2 to nKinds
			if aCounts[nPlace] > aCounts[nBest]
				nBest = nPlace
			ok
		next
		? "        " + padLeft(aCounts[nBest],6) + "  " + left(aKinds[nBest],110)
		del(aKinds,nBest)
		del(aCounts,nBest)
		nShown++
	end

func kindOf cText

	# the first word of a Func or Class line stays, its name is X; what is between quotes is X
	if left(cText,5) = "Func " or left(cText,6) = "Class "
		nSpace = substr(cText," ")
		cRest = right(cText,len(cText) - nSpace)
		nNext = substr(cRest," ")
		if nNext > 0
			return left(cText,nSpace) + "X" + right(cRest,len(cRest) - nNext + 1)
		ok
		return left(cText,nSpace) + "X"
	ok
	cOut = ""
	lInside = false
	nLength = len(cText)
	for nChar = 1 to nLength
		if cText[nChar] = '"'
			if lInside
				lInside = false
			else
				lInside = true
				cOut += '"X"'
			ok
		but not lInside
			cOut += cText[nChar]
		ok
	next
	return cOut

func checkImport

	aRun = runIn(cRoot + "/tools/dotnettools",'"' + cRing + '" importall.ring')
	nPlace = substr(aRun[1],"IMPORTED ")
	lOk = false
	cDetail = firstLine(aRun[1])
	if nPlace > 0
		cLine = trim(firstLine(right(aRun[1],len(aRun[1]) - nPlace + 1)))
		cDetail = cLine
		lOk = substr(cLine," 0 failed") > 0
		if not lOk
			cDetail += "  " + failedLines(aRun[1])
		ok
	ok
	report("every namespace of the manifest imports",lOk,cDetail)
	return lOk

func checkTest cDirectory, cName

	if cName = "test_userassembly.ring"
		removeFolder(cRoot + "/samples/UsingDotNet/tests/UserLib/generated")          # made again by the generator of now
	ok
	aRun = runIn(cDirectory,'"' + cRing + '" ' + cName)
	nPlace = substr(aRun[1],"TESTS: ")
	lOk = false
	cDetail = ""
	if nPlace > 0
		cLine = trim(firstLine(right(aRun[1],len(aRun[1]) - nPlace + 1)))
		lOk = substr(cLine," 0 failed") > 0
		cDetail = cLine + ", " + floor(aRun[2]) + " seconds"
	but substr(aRun[1],"SKIPPED") > 0
		lOk = true
		cDetail = "SKIPPED"
	else
		cDetail = left(firstLine(aRun[1]),200)
		if cDetail = ""
			cDetail = "no summary"
		ok
	ok
	report(cName,lOk,cDetail)
	return lOk

func checkAllPackages

	aRun = runIn(cRoot,"sh samples/UsingDotNet/tests/run.sh " + cRing + " --packages-only")
	cSummary = ""
	for cLine in lines(aRun[1])
		if substr(cLine," failed (") > 0
			cSummary = cLine
		ok
	next
	report("all the package tests",substr(cSummary,"0 failed (") > 0,cSummary)

func checkCoverage lUpdate

	aRun = runIn(cRoot + "/tools/dotnettools",'"' + cRing + '" auditcoverage.ring')
	nPlace = substr(aRun[1],"without a Ring class that is not excluded on purpose: ")
	if nPlace = 0
		report("types without a class",false,"the audit gave no total")
		return false
	ok
	cRest = right(aRun[1],len(aRun[1]) - nPlace - len("without a Ring class that is not excluded on purpose: ") + 1)
	cDigits = ""
	for nChar = 1 to len(cRest)
		if isdigit(cRest[nChar])
			cDigits += cRest[nChar]
		else
			exit
		ok
	next
	nCount = number(cDigits)
	cBaseline = cRoot + "/tools/dotnettools/coverage-baseline.txt"
	nBaseline = -1
	if fexists(cBaseline)
		cText = trim(read(cBaseline))
		if cText != ""
			nBaseline = number(cText)
		ok
	ok
	if lUpdate or nBaseline < 0
		write(cBaseline,"" + nCount + nl)
		report("types without a class",true,"" + nCount + " (the baseline was written)")
		return true
	ok
	lOk = (nCount <= nBaseline)
	cDetail = "" + nCount + " now, " + nBaseline + " in the baseline"
	if not lOk
		cDetail += ": types lost their class"
	ok
	report("types without a class",lOk,cDetail)
	return lOk

# The documentation: the API data (the bridge asks .NET for the API of every wrapped class), the pages and the class reference. The check passes when both
# programs run; it says how many generated files of the documentation differ from the last commit.
func checkDocs

	cDocsTools = cRoot + "/docs/tools"
	aRun = runIn(cDocsTools,'"' + cRing + '" dumpapi.ring')
	nPlace = substr(aRun[1],"types written")
	if nPlace = 0
		report("the documentation: the API data",false,firstLine(aRun[1]))
		return false
	ok
	report("the documentation: the API data",true,lastText(aRun[1]))
	aRun = runIn(cDocsTools,'"' + cRing + '" build.ring')
	if substr(aRun[1],"built ") = 0 or hasError(aRun[1])
		report("the documentation: the pages",false,firstLine(aRun[1]))
		return false
	ok
	cStatus = gitOutput("status --short -- docs/api docs/api.html docs/assets docs/reference.html")
	nChanged = len(lines(cStatus))
	cNote = "the pages and the class reference are made again in " + floor(aRun[2]) + " seconds"
	if nChanged > 0
		cNote += "; " + nChanged + " generated files of the documentation differ from the last commit: commit them with the change"
	else
		cNote += "; the generated documentation is the same as in the last commit"
	ok
	report("the documentation: the pages",true,cNote)
	return true

# the last line of a text that has text
func lastText cText

	aLines = lines(cText)
	nMax = len(aLines)
	for nLine = nMax to 1 step -1
		if trim(aLines[nLine]) != ""
			return trim(aLines[nLine])
		ok
	next
	return ""

# ---------------------------------------------------------------- helpers

func report cName, lOk, cDetail

	nChecks++
	if not lOk
		aFailed + cName
	ok
	cMark = "PASS "
	if not lOk
		cMark = "FAIL "
	ok
	cLine = cMark + " " + cName
	if cDetail != ""
		cLine += "  -  " + cDetail
	ok
	? cLine

# Run a command in a folder, the way a developer's shell would: RING_HOME is not set, and the bin folder of the package is on the PATH. The output (also the errors)
# is read from a file. The answer is [the output, the seconds].
func runIn cDirectory, cCommand

	cOutput = tempFolder() + "/ringdotnet_check_output.txt"
	cBin = cRoot + "/bin"
	if iswindows()
		cLine = 'cd /d "' + substr(cDirectory,"/","\") + '" && set RING_HOME=&& set "PATH=' + substr(cBin,"/","\") + ';%PATH%" && ' + cCommand + ' > "' + substr(cOutput,"/","\") + '" 2>&1'
		cLine = '"' + cLine + '"'
	else
		cLine = 'cd "' + cDirectory + '" && env -u RING_HOME PATH="' + cBin + ':$PATH" ' + cCommand + ' > "' + cOutput + '" 2>&1'
	ok
	nStart = clock()
	system(cLine)
	nSeconds = (clock() - nStart) / clockspersecond()
	cText = ""
	if fexists(cOutput)
		cText = read(cOutput)
		remove(cOutput)
	ok
	return [cText,nSeconds]

# The output of a git command in the root of the repository
func gitOutput cArguments

	cOutput = tempFolder() + "/ringdotnet_check_git.txt"
	system("git -c core.quotepath=off " + cArguments + ' > "' + cOutput + '"')
	cText = ""
	if fexists(cOutput)
		cText = read(cOutput)
		remove(cOutput)
	ok
	return cText

func lines cText

	return str2list(substr(substr(cText,char(13),""),nl,nl))

func firstLine cText

	aLines = lines(trim(cText))
	if len(aLines) > 0
		return aLines[1]
	ok
	return ""

func failedLines cText

	cJoined = ""
	for cLine in lines(cText)
		if substr(cLine,"FAILED") > 0
			if cJoined != ""
				cJoined += " | "
			ok
			cJoined += trim(cLine)
		ok
	next
	return left(cJoined,300)

# An error of Ring or of the bridge in the output of a program
func hasError cText

	return substr(cText,"Error (R") > 0 or substr(cText,"DotNet Error") > 0 or (substr(cText,"Line ") > 0 and substr(cText," Error ") > 0)

func removeFolder cFolder

	if direxists(cFolder)
		if iswindows()
			system('rmdir /s /q "' + substr(cFolder,"/","\") + '"')
		else
			system('rm -rf "' + cFolder + '"')
		ok
	ok

func padLeft xValue, nWidth

	cText = "" + xValue
	if len(cText) >= nWidth
		return cText
	ok
	return copy(" ",nWidth - len(cText)) + cText

func tempFolder

	cFolder = sysget("TEMP")
	if cFolder = ""
		cFolder = sysget("TMPDIR")
	ok
	if cFolder = ""
		cFolder = "/tmp"
	ok
	return substr(cFolder,"\","/")
