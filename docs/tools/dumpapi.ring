# Makes docs/tools/api-data/api.jsonl: the API (from .NET reflection) of every wrapped class. Run it before build.ring when the classes change.
#
#     cd docs/tools
#     ring dumpapi.ring
#
# The types file (api-data/types.txt) has one line for each wrapped class: <namespace> TAB <Ring class> TAB <.NET type name>, made from the generated
# library. The output has one line for each class: <namespace> TAB <Ring class> TAB <JSON from the bridge>   (or an ERROR line).
# This is the only documentation tool that needs RingDotNet: the bridge gives the API of the .NET types.

load "../../libraries/dotnetlib/dotnetlib.ring"
load "doclib.ring"

dnUseAll()
dnUseData()

func main

	cHere = programFolder()
	cGen = parentFolder(parentFolder(cHere)) + "/libraries/dotnetlib/generated"
	cOutFolder = cHere + "/api-data"
	if not direxists(cOutFolder)
		makeFolder(cOutFolder)
	ok
	aLines = typeLines(cGen)
	write(cOutFolder + "/types.txt",joinList(aLines,nl) + nl)
	cOut = cOutFolder + "/api.jsonl"
	fp = fopen(cOut,"w")
	nDone = 0
	nFailed = 0
	for cLine in aLines
		aParts = str2list(substr(cLine,char(9),nl))
		cJson = ""
		cLastError = ""
		aLoop19 = typeCandidates(aParts[3])
		for cType in aLoop19
			try
				cJson = dnRequest("apidoc",[cType])
				exit
			catch
				cLastError = cCatchError
			done
		next
		if cJson != ""
			fputs(fp,aParts[1] + char(9) + aParts[2] + char(9) + cJson + nl)
			nDone++
		else
			fputs(fp,aParts[1] + char(9) + aParts[2] + char(9) + "ERROR " + substr(cLastError,nl," ") + nl)
			nFailed++
		ok
	next
	fclose(fp)
	? "" + nDone + " types written, " + nFailed + " failed"

# the lines of the types file: <namespace> TAB <Ring class> TAB <the .NET type, with its assembly when the generated class has it>
func typeLines cGen

	aLines = []
	aLoop20 = listNames(cGen)
	for cLoader in aLoop20
		if not hasSuffix(cLoader,".ring") or hasSuffix(cLoader,".classes.ring") or cLoader = "classindex.ring"
			loop
		ok
		cNs = left(cLoader,len(cLoader) - 5)
		aRegistered = registeredClasses(readText(cGen + "/" + cLoader))
		aNames = qualifiedNames(cGen,cNs,aRegistered)
		for aItem in aRegistered
			cName = aItem[2]
			nAt = find(aNames,cName,1)
			if nAt > 0
				aLines + (cNs + char(9) + cName + char(9) + aNames[nAt][2])
			else
				aLines + (cNs + char(9) + cName + char(9) + aItem[1])
			ok
		next
	next
	return aLines

# dnRegisterClass("<.NET type>","<Ring class>",<number>) : a list of [.NET type, Ring class]
func registeredClasses cText

	aFound = []
	aPieces = splitOn(cText,'dnRegisterClass("')
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cPiece = aPieces[nPiece]
		nQuote = substr(cPiece,'"')
		if nQuote <= 1 or part(cPiece,nQuote,nQuote + 2) != '","'
			loop
		ok
		cNet = left(cPiece,nQuote - 1)
		nStart = nQuote + 3
		nEnd = findFrom(cPiece,'"',nStart)
		if nEnd <= nStart
			loop
		ok
		cClass = part(cPiece,nStart,nEnd - 1)
		cRest = tail(cPiece,nEnd + 1)
		nDigits = 0
		nRest = len(cRest)
		if left(cRest,1) != ","
			loop
		ok
		nAt = 2
		while nAt <= nRest and isDigitCh(cRest[nAt])
			nAt++
			nDigits++
		end
		if nDigits > 0 and nAt <= nRest and cRest[nAt] = ")"
			aFound + [cNet,cClass]
		ok
	next
	return aFound

# The type of each class as the generated class has it ('Namespace.Type, Assembly'): a list of [Ring class, qualified name] for the classes that have it
func qualifiedNames cGen,cNs,aRegistered

	aResult = []
	cPath = cGen + "/" + cNs + ".classes.ring"
	if not fexists(cPath)
		return aResult
	ok
	aPieces = splitOn(substr(readText(cPath),nl + "Class ",char(3)),char(3))
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cBlock = aPieces[nPiece]
		nAt = 1
		nSize = len(cBlock)
		while nAt <= nSize and isWordCh(cBlock[nAt])
			nAt++
		end
		if nAt = 1
			loop
		ok
		cName = left(cBlock,nAt - 1)
		cNet = ""
		for aItem in aRegistered
			if aItem[2] = cName
				cNet = aItem[1]
			ok
		next
		if cNet = ""
			loop
		ok
		cStart = "'" + cNet + ", "
		nPos = 1
		while true
			nFound = findFrom(cBlock,cStart,nPos)
			if nFound = 0
				exit
			ok
			nBegin = nFound + len(cStart)
			nClose = findFrom(cBlock,"'",nBegin)
			if nClose > nBegin
				aResult + [cName,part(cBlock,nFound + 1,nClose - 1)]
				exit
			ok
			nPos = nFound + 1
		end
	next
	return aResult

# the name as given, then with assemblies that hold types the manifest finds by namespace
func typeCandidates cType

	aList = [cType]
	if substr(cType,",") = 0
		for cAsm in ["Microsoft.EntityFrameworkCore.Relational","Microsoft.AspNetCore.Mvc.Core","Microsoft.AspNetCore.Components.Endpoints","Microsoft.AspNetCore.Mvc.RazorPages","Microsoft.AspNetCore.Http.Results","Microsoft.AspNetCore.Http.Abstractions","Microsoft.AspNetCore.Routing","Microsoft.AspNetCore.Components","Microsoft.AspNetCore.Mvc.ViewFeatures","Microsoft.AspNetCore.Mvc.Razor"]
			aList + (cType + ", " + cAsm)
		next
	ok
	return aList
