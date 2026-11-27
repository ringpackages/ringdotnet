# Audit of the public API of NuGet packages: what can Ring use, and what gets in the way?
#
#     ring auditpackages.ring                    the packages of packages.txt, restored into a work folder, then one total table
#     ring auditpackages.ring Serilog Dapper     only these packages
#     ring auditpackages.ring --each             one table for each package (instead of the total)
#     ring auditpackages.ring --reuse            the folders of the earlier run, no restore
#
# Each package is restored with `dotnet publish` (like the tutorials do), so its DLL and the DLLs it needs are copied into one folder. The DLLs that an empty project
# does not have are audited with auditassembly.ring (a program of the bridge: it is what is measured). A package that cannot be restored is listed and left out.
#
# This is plain Ring: the program that runs the audits does not use the package (a bridge that does not work must not stop it from saying so).

C_PROJECT = '<Project Sdk="Microsoft.NET.Sdk">' + nl
C_PROJECT += '  <PropertyGroup><TargetFramework>net9.0</TargetFramework><AssemblyName>Probe</AssemblyName><DebugType>none</DebugType>' + nl
C_PROJECT += '    <SatelliteResourceLanguages>en</SatelliteResourceLanguages></PropertyGroup>' + nl
C_PROJECT += '  <ItemGroup>%s</ItemGroup>' + nl
C_PROJECT += '</Project>' + nl

cHere = ""
cRoot = ""
cWork = ""
cRing = ""

func main

	cRing = exefilename()
	cProgram = substr(sysargv[2],"\","/")
	nSlash = 0
	for nChar = 1 to len(cProgram)
		if cProgram[nChar] = "/"
			nSlash = nChar
		ok
	next
	if nSlash > 0
		chdir(left(cProgram,nSlash - 1))
	ok
	cHere = substr(currentdir(),"\","/")
	cRoot = cHere + "/../.."
	cWork = tempFolder() + "/ringdotnet-package-audit"
	aNames = []
	lEach = false
	lReuse = false
	for nArg = 3 to len(sysargv)
		if sysargv[nArg] = "--each"
			lEach = true
		but sysargv[nArg] = "--reuse"
			lReuse = true
		but left(sysargv[nArg],2) != "--"
			aNames + sysargv[nArg]
		ok
	next
	if len(aNames) = 0
		for cLine in lines(read(cHere + "/packages.txt"))
			nHash = substr(cLine,"#")
			if nHash > 0
				cLine = left(cLine,nHash - 1)
			ok
			cLine = trim(cLine)
			if cLine != ""
				aNames + cLine
			ok
		next
	ok
	if not lReuse
		publish([],cWork + "/baseline")
	ok
	aBaseline = dllNames(cWork + "/baseline")
	aAudited = []
	aFailed = []
	aPerPackage = []          # [package, [dll paths]]: each package is audited in a process of its own, so that two versions of a dependency do not meet
	for cName in aNames
		cFolder = cWork + "/" + firstWord(cName)
		lGood = false
		cReason = "restore failed"
		if lReuse and direxists(cFolder + "/out")
			lGood = true
		else
			aResult = publish([cName],cFolder)
			lGood = aResult[1]
			cReason = aResult[2]
		ok
		if not lGood
			aFailed + (cName + ": " + cReason)
		else
			aMine = []
			aDlls = dllNames(cFolder)
			for cDll in aDlls
				if find(aBaseline,cDll) = 0 and cDll != "Probe.dll" and find(aAudited,cDll) = 0
					aAudited + cDll
					aMine + (cFolder + "/out/" + cDll)
				ok
			next
			aPerPackage + [cName,aMine]
			? "restored " + cName
		ok
	next
	cFailedText = "none"
	if len(aFailed) > 0
		cFailedText = ""
		for cFail in aFailed
			cFailedText += cFail + "; "
		next
	ok
	? nl + "not restored: " + cFailedText
	? "assemblies to audit: " + len(aAudited)
	if lEach
		for aItem in aPerPackage
			if len(aItem[2]) > 0
				? nl + "##### " + aItem[1]
				? runAudit(aItem[2],false)
			ok
		next
		return
	ok
	aTags = []
	aTotals = []
	aExamples = []
	for aItem in aPerPackage
		if len(aItem[2]) > 0
			aParsed = parseTotal(runAudit(aItem[2],true))
			for aRow in aParsed
				nPlace = find(aTags,aRow[2])
				if nPlace = 0
					aTags + aRow[2]
					aTotals + 0
					aExamples + ""
					nPlace = len(aTags)
				ok
				aTotals[nPlace] += aRow[1]
				if aExamples[nPlace] = ""
					aExamples[nPlace] = aRow[3]
				ok
			next
		ok
	next
	? nl + "== total of " + len(aAudited) + " assemblies"
	for cKind in ["OK","INFO","GAP"]
		aRows = []
		nTags = len(aTags)
		for nPlace = 1 to nTags
			if left(trim(aTags[nPlace]),len(cKind)) = cKind
				aRows + [aTotals[nPlace],nPlace]
			ok
		next
		aRows = sortByCount(aRows)
		for aRow in aRows
			cLine = padLeft(aRow[1],7) + "  " + aTags[aRow[2]]
			if aExamples[aRow[2]] != ""
				cLine += "   e.g. " + aExamples[aRow[2]]
			ok
			? cLine
		next
	next
	nTypes = getTotal(aTags,aTotals,"INFO type: public types")
	nUsable = getTotal(aTags,aTotals,"OK   type: wrapped (class, struct, interface)") + getTotal(aTags,aTotals,"OK   type: enum (a text in Ring)") + getTotal(aTags,aTotals,"OK   type: delegate (a callback in Ring)")
	nMethods = getTotal(aTags,aTotals,"INFO method: public methods")
	nCallable = 0
	nTags = len(aTags)
	for nPlace = 1 to nTags
		if left(aTags[nPlace],len("OK   method: callable")) = "OK   method: callable"
			nCallable += aTotals[nPlace]
		ok
	next
	? nl + "summary"
	if nTypes > 0
		? "  types that Ring can use (wrapped, enums, delegates): " + floor(nUsable * 100 / nTypes) + " % (" + nUsable + " of " + nTypes + ")   (generic definitions " + getTotal(aTags,aTotals,"INFO type: generic type definition (wrapped, made with :typeArguments)") + ", nested " + getTotal(aTags,aTotals,"INFO type: nested type (wrapped, named after the types around it)") + ")"
	ok
	if nMethods > 0
		? "  methods that can be called, in the types that are wrapped: " + floor(nCallable * 100 / nMethods) + " % (" + nCallable + " of " + nMethods + ")"
	ok
	? "  members (methods, constructors, properties) in types that are not wrapped: " + getTotal(aTags,aTotals,"GAP  members of types that are not wrapped")

# ---------------------------------------------------------------- the work

# Restore the packages of a list (one project, no packages for the baseline) into a folder with dotnet publish. The answer is [it worked, the end of the messages].
func publish aPackages, cFolder

	makeFolder(cFolder)
	cRefs = ""
	for cPackage in aPackages
		aWords = words(cPackage)
		cVersion = "*"
		if len(aWords) > 1
			cVersion = aWords[2]
		ok
		cRefs += '<PackageReference Include="' + aWords[1] + '" Version="' + cVersion + '" />'
	next
	write(cFolder + "/Probe.csproj",substr(C_PROJECT,"%s",cRefs))
	write(cFolder + "/Empty.cs","class Empty { }" + nl)
	cOutput = tempFolder() + "/ringdotnet_audit_publish.txt"
	nCode = system('dotnet publish "' + nativePath(cFolder) + '" -c Release -o "' + nativePath(cFolder + "/out") + '" -nologo -v q > "' + nativePath(cOutput) + '" 2>&1')
	cText = ""
	if fexists(cOutput)
		cText = read(cOutput)
		remove(cOutput)
	ok
	cReason = "restore failed"
	for cLine in lines(cText)
		if substr(cLine,"error") > 0
			cReason = right(trim(cLine),160)
		ok
	next
	return [nCode = 0,cReason]

# The names of the DLLs that a restore copied into the folder out
func dllNames cFolder

	aNames = []
	cOut = cFolder + "/out"
	if direxists(cOut)
		for aFile in dir(cOut)
			if not aFile[2] and lower(right(aFile[1],4)) = ".dll"
				aNames + aFile[1]
			ok
		next
	ok
	return aNames

# The audit of some DLLs with auditassembly.ring: its output
func runAudit aFiles, lQuiet

	cCommand = '"' + cRing + '" auditassembly.ring'
	if lQuiet
		cCommand += " --quiet"
	ok
	for cFile in aFiles
		cCommand += ' "' + nativePath(cFile) + '"'
	next
	cOutput = tempFolder() + "/ringdotnet_audit_output.txt"
	cBin = nativePath(cRoot + "/extensions/ringdotnet/bin") + pathSeparator() + nativePath(cRoot + "/bin")
	if iswindows()
		cLine = 'cd /d "' + nativePath(cHere) + '" && set RING_HOME=&& set "PATH=' + cBin + ';%PATH%" && ' + cCommand + ' > "' + nativePath(cOutput) + '" 2>&1'
		cLine = '"' + cLine + '"'
	else
		cLine = 'cd "' + cHere + '" && env -u RING_HOME PATH="' + cBin + ':$PATH" ' + cCommand + ' > "' + cOutput + '" 2>&1'
	ok
	system(cLine)
	cText = ""
	if fexists(cOutput)
		cText = read(cOutput)
		remove(cOutput)
	ok
	return cText

# The lines of the total of one run: [[count, tag, example]]
func parseTotal cText

	aRows = []
	lInside = false
	for cLine in lines(cText)
		if left(cLine,8) = "== total"
			lInside = true
		but left(cLine,7) = "summary"
			exit
		but lInside
			cRest = cLine
			nSpaces = 0
			while nSpaces < len(cRest) and cRest[nSpaces + 1] = " "
				nSpaces++
			end
			cRest = right(cRest,len(cRest) - nSpaces)
			cDigits = ""
			for nChar = 1 to len(cRest)
				if isdigit(cRest[nChar])
					cDigits += cRest[nChar]
				else
					exit
				ok
			next
			if cDigits != "" and substr(cRest,cDigits + "  ") = 1
				cTag = right(cRest,len(cRest) - len(cDigits) - 2)
				cExample = ""
				nExample = substr(cTag,"   e.g. ")
				if nExample > 0
					cExample = right(cTag,len(cTag) - nExample - len("   e.g. ") + 1)
					cTag = left(cTag,nExample - 1)
				ok
				aRows + [number(cDigits),cTag,cExample]
			ok
		ok
	next
	return aRows

func getTotal aTags, aTotals, cTag

	nPlace = find(aTags,cTag)
	if nPlace = 0
		return 0
	ok
	return aTotals[nPlace]

# [[count, place]] with the highest count first
func sortByCount aRows

	aSorted = []
	nRows = len(aRows)
	for nTurn = 1 to nRows
		nBest = 1
		nItems = len(aRows)
		for nItem = 2 to nItems
			if aRows[nItem][1] > aRows[nBest][1]
				nBest = nItem
			ok
		next
		aSorted + aRows[nBest]
		del(aRows,nBest)
	next
	return aSorted

# ---------------------------------------------------------------- small helpers

func lines cText

	return str2list(substr(substr(cText,char(13),""),nl,nl))

func words cText

	aWords = []
	cWord = ""
	nLength = len(cText)
	for nChar = 1 to nLength
		if cText[nChar] = " " or cText[nChar] = char(9)
			if cWord != ""
				aWords + cWord
				cWord = ""
			ok
		else
			cWord += cText[nChar]
		ok
	next
	if cWord != ""
		aWords + cWord
	ok
	return aWords

func firstWord cText

	aWords = words(cText)
	if len(aWords) > 0
		return aWords[1]
	ok
	return cText

func padLeft xValue, nWidth

	cText = "" + xValue
	if len(cText) >= nWidth
		return cText
	ok
	return copy(" ",nWidth - len(cText)) + cText

func nativePath cPath

	if iswindows()
		return substr(cPath,"/","\")
	ok
	return cPath

func pathSeparator

	if iswindows()
		return ";"
	ok
	return ":"

func makeFolder cFolder

	if not direxists(cFolder)
		if iswindows()
			system('mkdir "' + nativePath(cFolder) + '" 2>nul')
		else
			system('mkdir -p "' + cFolder + '"')
		ok
	ok

func tempFolder

	cFolder = sysget("TEMP")
	if cFolder = ""
		cFolder = sysget("TMPDIR")
	ok
	if cFolder = ""
		cFolder = "/tmp"
	ok
	return substr(cFolder,"\","/")
