# Builds the RingDotNet documentation: docs/src/*.md --> docs/*.html (plus the gallery pages made from the samples, the class reference and the search index).
#
#     cd docs/tools
#     ring build.ring [--refresh] [--no-api]
#
# --no-api leaves out the class reference (a quick build while you write the pages). --refresh runs the example programs again (their output is cached in docs/tools/output-cache). Plain Ring: this tool does not use RingDotNet.

load "doclib.ring"
load "docpages.ring"
load "mdlib.ring"
load "apipages.ring"

C_RING_COMMENT_DEFAULT = "Use .NET classes and methods from Ring programs"
aInternalFunctions = ["dnPackItem","dnPack","dnUnpack","dnJoin","dnDispatchCallback","dnIsIdentifier","dnFolderOf","dnShow","dnTypeCached","dnCreate","dnWrapObject","dnLinq","dnCode","dnQuerySource","dnSelected","webWrapper","webPlain","wpfSelfTest","uiSelfTest"]

# The settings of the run: here, docs, root, src, refresh, page template
aSettings = []

func main

	cHere = programFolder()
	cDocs = parentFolder(cHere)
	cRoot = parentFolder(cDocs)
	cSrc = cDocs + "/src"
	lRefresh = false
	lApi = true
	for nArg = 3 to len(sysargv)
		if sysargv[nArg] = "--refresh"
			lRefresh = true
		but sysargv[nArg] = "--no-api"
			lApi = false
		ok
	next
	aSettings = [cHere,cDocs,cRoot,cSrc,lRefresh,readText(cHere + "/page.template")]
	aIndex = []
	nCount = 0
	nPages = len(aDocPages)
	for nPage = 1 to nPages
		cName = aDocPages[nPage][1]
		cTitle = aDocPages[nPage][2]
		if cName = "api"
			loop
		ok
		cPath = cSrc + "/" + cName + ".md"
		if not fexists(cPath)
			? "missing " + cPath
			loop
		ok
		aFront = parseFront(readText(cPath))
		aMeta = aFront[1]
		cBody = markdown(aFront[2])
		if substr(cBody,"@APPS@") > 0
			cBody = substr(cBody,"@APPS@","" + appsCount())
		ok
		if substr(cBody,"@CLASSES@") > 0
			aStats = statsValues()
			cBody = substr(cBody,"@CLASSES@",aStats[:classes])
		ok
		cTitle = metaGet(aMeta,"title",cTitle)
		cLead = metaGet(aMeta,"lead","")
		writeText(cDocs + "/" + cName + ".html",pageHtml(cName,cTitle,cLead,cBody,cName,"",true,""))
		# search entries: one per section
		aSections = splitOn(cBody,"<h2 id=")
		nSections = len(aSections)
		for nSection = 1 to nSections
			cSection = aSections[nSection]
			if nSection > 1
				cSection = "<h2 id=" + cSection
			ok
			cId = ""
			cHeading = ""
			if left(cSection,8) = '<h2 id="'
				nQuote = findFrom(cSection,'"',9)
				if nQuote > 9 and part(cSection,nQuote,nQuote + 1) = '">'
					nEndAnchor = findFrom(cSection,'<a class="anchor"',nQuote + 2)
					if nEndAnchor > 0
						cInner = part(cSection,nQuote + 2,nEndAnchor - 1)
						if substr(cInner,nl) = 0
							cId = part(cSection,9,nQuote - 1)
							cHeading = plainText(cInner)
						ok
					ok
				ok
			ok
			cUrl = cName + ".html"
			if cId != ""
				cUrl += "#" + cId
			ok
			aIndex + ('{"u": ' + jsonString(cUrl) + ', "t": ' + jsonString(cTitle) + ', "h": ' + jsonString(cHeading) + ', "x": ' + jsonString(utf8Left(plainText(cSection),600)) + "}")
		next
		nCount++
	next
	if lApi and fexists(cHere + "/api-data/api.jsonl")
		aApi = buildApiPages(cDocs)
		? "class reference: " + aApi[1] + " classes in " + aApi[2] + " namespaces"
	ok
	writeText(cDocs + "/assets/search-index.js","window.SEARCH_INDEX = [" + joinList(aIndex,", ") + "];")
	? "built " + nCount + " pages, " + len(aIndex) + " search entries"

func hereFolder

	return aSettings[1]

func docsFolder

	return aSettings[2]

func rootFolder

	return aSettings[3]

func metaGet aMeta,cKey,cDefault

	for aItem in aMeta
		if aItem[1] = cKey
			return aItem[2]
		ok
	next
	return cDefault

# [the front matter as a list of [key, value], the text after it]
func parseFront cText

	aMeta = []
	if left(cText,3) = "---"
		nPos = findFrom(cText,nl + "---",4)
		cBlock = part(cText,4,nPos - 1)
		aLoop1 = splitLines(pyStrip(cBlock))
		for cLine in aLoop1
			nColon = substr(cLine,":")
			if nColon > 0
				cKey = pyStrip(left(cLine,nColon - 1))
				cValue = pyStrip(tail(cLine,nColon + 1))
			else
				cKey = pyStrip(cLine)
				cValue = ""
			ok
			if len(cValue) > 1 and left(cValue,1) = right(cValue,1) and (left(cValue,1) = '"' or left(cValue,1) = "'")
				cValue = part(cValue,2,len(cValue) - 1)
			ok
			aMeta + [cKey,cValue]
		next
		cText = tail(cText,nPos + 4)
	ok
	return [aMeta,cText]

# the text of a part of a page without the markup (for the search)
func plainText cText

	nBar = 1
	while true
		nBar = substr(cText,'<div class="bar">')
		if nBar = 0
			exit
		ok
		nClose = findFrom(cText,"</div>",nBar)
		if nClose = 0
			exit
		ok
		cText = left(cText,nBar - 1) + tail(cText,nClose + 6)
	end
	cText = removeSpanTags(cText)
	cText = removeTags(cText," ")
	cText = htmlUnescape(cText)
	return collapseSpace(cText)

# </?span[^>]*>  removed (the [^>]* goes over any < until the first >)
func removeSpanTags cText

	aPieces = splitOn(cText,"<")
	aOut = [aPieces[1]]
	nMax = len(aPieces)
	nPiece = 2
	while nPiece <= nMax
		cPiece = aPieces[nPiece]
		cRest = cPiece
		if left(cRest,1) = "/"
			cRest = tail(cRest,2)
		ok
		nClose = 0
		nLast = nPiece
		if left(cRest,4) = "span"
			# the pieces up to the one that has the >
			nCheck = nPiece
			while nCheck <= nMax
				nClose = substr(aPieces[nCheck],">")
				if nClose > 0
					nLast = nCheck
					exit
				ok
				nCheck++
			end
		ok
		if nClose > 0
			aOut + tail(aPieces[nLast],nClose + 1)
			nPiece = nLast + 1
		else
			aOut + ("<" + cPiece)
			nPiece++
		ok
	end
	return joinList(aOut,"")

# \s+ turned into one space, and the text stripped
func collapseSpace cText

	aOut = []
	nSize = len(cText)
	lSpace = false
	nStart = 1
	i = 1
	cOut = ""
	while i <= nSize
		c = cText[i]
		nSkip = 0
		if isSpaceCh(c)
			nSkip = 1
		but ascii(c) = 194 and i < nSize and (ascii(cText[i + 1]) = 160 or ascii(cText[i + 1]) = 133)
			nSkip = 2
		ok
		if nSkip > 0
			if i > nStart
				aOut + part(cText,nStart,i - 1)
			ok
			aOut + " "
			i += nSkip
			while i <= nSize
				c = cText[i]
				if isSpaceCh(c)
					i++
				but ascii(c) = 194 and i < nSize and (ascii(cText[i + 1]) = 160 or ascii(cText[i + 1]) = 133)
					i += 2
				else
					exit
				ok
			end
			nStart = i
		else
			i++
		ok
	end
	if nStart <= nSize
		aOut + part(cText,nStart,nSize)
	ok
	return pyStrip(joinList(aOut,""))

# ---------------------------------------------------------------- galleries
func firstComment cSrc

	aLines = []
	aLoop2 = splitLines(cSrc)
	for cLine in aLoop2
		if left(cLine,1) = "#"
			aLines + pyStrip(lstripChar(cLine,"#"))
		but pyStrip(cLine) = "" and len(aLines) = 0
			loop
		else
			exit
		ok
	next
	aKept = []
	for cLine in aLines
		if cLine != ""
			aKept + cLine
		ok
	next
	return joinList(aKept," ")

func prettyName cName

	# ^\d+_ removed
	nDigits = 0
	nSize = len(cName)
	while nDigits < nSize and isDigitCh(cName[nDigits + 1])
		nDigits++
	end
	if nDigits > 0 and nDigits < nSize and cName[nDigits + 1] = "_"
		cName = tail(cName,nDigits + 2)
	ok
	cName = substr(cName,"_"," ")
	cSpaced = ""
	nSize = len(cName)
	for nChar = 1 to nSize
		c = cName[nChar]
		if nChar > 1 and isUpperCh(c) and isLowerCh(cName[nChar - 1])
			cSpaced += " "
		ok
		cSpaced += c
	next
	if cSpaced = ""
		return ""
	ok
	return upper(left(cSpaced,1)) + tail(cSpaced,2)

func isLowerCh c

	n = ascii(c)
	return n >= 97 and n <= 122

func shotTag cName,cAlt

	if fexists(docsFolder() + "/img/shots/" + cName)
		return '<img src="img/shots/' + cName + '" alt="' + esc(cAlt) + '" loading="lazy">'
	ok
	return '<div class="pill">no screenshot</div>'

# the applications that have a window: [name, program file]
func windowApplications

	aApps = []
	cFolder = rootFolder() + "/samples/UsingDotNet/applications"
	aLoop3 = listNames(cFolder)
	for cDir in aLoop3
		cMain = cFolder + "/" + cDir + "/" + cDir + ".ring"
		if not fexists(cMain) or cDir = "WebApi"
			loop
		ok
		cSrc = readText(cMain)
		if substr(cSrc,'"System.Windows') = 0 and substr(cSrc,"dnUseDesktop") = 0
			loop
		ok
		aApps + [cDir,cSrc]
	next
	return aApps

func appsCount

	return len(windowApplications())

# [the HTML of the gallery, the number of items]
func galleryHtml cKind

	aItems = []
	if cKind = "forms" or cKind = "wpf"
		cSub = "Forms"
		if cKind = "wpf"
			cSub = "Wpf"
		ok
		cFolder = rootFolder() + "/samples/UsingDotNet/" + cSub
		aLoop4 = listNames(cFolder)
		for cFile in aLoop4
			if not hasSuffix(cFile,".ring")
				loop
			ok
			cBase = left(cFile,len(cFile) - 5)
			cSrc = readText(cFolder + "/" + cFile)
			aItems + [prettyName(cBase),firstComment(cSrc),cKind + "-" + cBase + ".png",cSrc,"ring samples/UsingDotNet/" + cSub + "/" + cFile]
		next
	else
		aApps = windowApplications()
		for aApp in aApps
			cMain = aApp[1] + ".ring"
			aItems + [prettyName(aApp[1]),firstComment(aApp[2]),"app-" + aApp[1] + ".png",aApp[2],"cd samples/UsingDotNet/applications/" + aApp[1] + "  then  ring " + cMain]
		next
	ok
	aCards = []
	for aItem in aItems
		cDesc = "&nbsp;"
		if aItem[2] != ""
			cDesc = esc(aItem[2])
		ok
		aCards + ('<div class="item" id="' + slug(aItem[1]) + '"><div class="pic">' + shotTag(aItem[3],aItem[1]) + '</div><div class="info"><h3>' + esc(aItem[1]) + "</h3><p>" + cDesc + '</p><div class="run"><code>' + esc(aItem[5]) + "</code></div>" + "<details><summary>Source code</summary>" + codeBlock(aItem[4],"ring","Ring") + "</details></div></div>")
	next
	return ['<div class="gallery">' + joinList(aCards,"") + "</div>",len(aItems)]

func sourceLanguage cRel

	if hasSuffix(cRel,".ring")
		return "ring"
	ok
	if hasSuffix(cRel,".cs")
		return "csharp"
	ok
	return "text"

# the HTML of a {{directive}} line
func directiveHtml cCmd

	if hasPrefix(cCmd,"gallery:")
		return galleryHtml(tail(cCmd,substr(cCmd,":") + 1))[1]
	ok
	if hasPrefix(cCmd,"file:")
		cRel = pyStrip(tail(cCmd,substr(cCmd,":") + 1))
		return codeBlock(readText(rootFolder() + "/" + cRel),sourceLanguage(cRel),cRel)
	ok
	if hasPrefix(cCmd,"source:")
		cRel = pyStrip(tail(cCmd,substr(cCmd,":") + 1))
		return '<details class="src"><summary>' + esc(cRel) + "</summary>" + codeBlock(readText(rootFolder() + "/" + cRel),sourceLanguage(cRel),cRel) + "</details>"
	ok
	if hasPrefix(cCmd,"output:")
		cRel = pyStrip(tail(cCmd,substr(cCmd,":") + 1))
		aParts = words(cRel)
		aArgs = []
		nParts = len(aParts)
		for nPart = 2 to nParts
			aArgs + aParts[nPart]
		next
		cText = runRing(aParts[1],aArgs)
		if isSelfTestOutput(pyStrip(cText))
			return ""
		ok
		return codeBlock(cText,"output","Output")
	ok
	if hasPrefix(cCmd,"functions:")
		return functionsTable(pyStrip(tail(cCmd,substr(cCmd,":") + 1)))
	ok
	if hasPrefix(cCmd,"stats")
		aStats = statsValues()
		aCells = [["Namespaces",aStats[:namespaces]],["Wrapped classes",aStats[:classes]],["Forms samples",aStats[:forms]],["WPF samples",aStats[:wpf]],["Applications",aStats[:apps]],["Test files",aStats[:tests]]]
		cCells = ""
		for aCell in aCells
			cCells += '<div class="stat"><b>' + aCell[2] + "</b><span>" + aCell[1] + "</span></div>"
		next
		return '<div class="stats">' + cCells + "</div>"
	ok
	return "<!-- unknown directive " + esc(cCmd) + " -->"

# the words of a text (split() of Python: white space separates)
func words cText

	aWords = []
	cWord = ""
	nSize = len(cText)
	for nChar = 1 to nSize
		if isSpaceCh(cText[nChar])
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

# SELFTEST OK (n checks)
func isSelfTestOutput cText

	if left(cText,13) != "SELFTEST OK (" or not hasSuffix(cText," checks)")
		return false
	ok
	cDigits = part(cText,14,len(cText) - 8)
	return len(cDigits) > 0 and digitsValue(cDigits) >= 0

# The output of a program of the package; the output is kept in docs/tools/output-cache (--refresh runs the program again)
func runRing cRel,aArgs

	cPath = rootFolder() + "/" + cRel
	cCache = hereFolder() + "/output-cache"
	cKeyText = cRel + " " + joinList(aArgs," ")
	cKey = ""
	lWord = true
	nSize = len(cKeyText)
	for nChar = 1 to nSize
		c = cKeyText[nChar]
		if isWordCh(c)
			cKey += c
			lWord = true
		elseif lWord
			cKey += "_"
			lWord = false
		ok
	next
	cFile = cCache + "/" + cKey + ".txt"
	if not aSettings[5] and fexists(cFile)
		return readText(cFile)
	ok
	cArgs = ""
	for cArg in aArgs
		cArgs += " " + cArg
	next
	cFolder = parentFolder(cPath)
	cName = tail(cPath,len(cFolder) + 2)
	cText = runCommand(cFolder,'"' + exefilename() + '" ' + cName + cArgs,rootFolder() + "/bin")
	cText = pyStrip(substr(cText,char(13),""))
	cText = substr(cText,rootFolder(),"<package>")
	cText = substr(cText,substr(rootFolder(),"/","\"),"<package>")
	if not direxists(cCache)
		system("mkdir " + substr(cCache,"/",iff(isWindows(),"\","/")))
	ok
	writeText(cFile,cText)
	return cText

# A table of the functions and class methods of a Ring file with the comment above each one
func functionsTable cRel

	aRows = []
	aComment = []
	cClass = ""
	aLoop5 = splitLines(readText(rootFolder() + "/" + cRel))
	for cLine in aLoop5
		cS = pyStrip(cLine)
		cName = wordAfterKeyword(cLine,"class",0)
		if cName != ""
			cClass = cName
			aComment = []
			loop
		ok
		if left(cS,1) = "#" and left(cS,6) != "# ----"
			aComment + pyStrip(lstripChar(cS,"#"))
			loop
		ok
		aFunc = funcLine(cLine)
		if len(aFunc) > 0
			cName = aFunc[1]
			cArgs = aFunc[2]
			lTop = aFunc[3]
			if lTop
				cClass = ""
			ok
			if lTop and find(aInternalFunctions,cName) > 0
				aComment = []
				loop
			ok
			if not lTop and cClass = ""
				aComment = []
				loop
			ok
			cLabel = ""
			if not lTop and cClass != ""
				cLabel = cClass + "."
			ok
			cLabel += cName + "(" + dropPrefixes(substr(cArgs,"  "," ")) + ")"
			aRows + [cLabel,joinList(aComment," ")]
			aComment = []
			loop
		ok
		if cS != ""
			aComment = []
		ok
	next
	cBody = ""
	for aRow in aRows
		cBody += "<tr><td><code>" + esc(aRow[1]) + "</code></td><td>" + inlineMd(aRow[2]) + "</td></tr>"
	next
	return '<div class="tablewrap"><table><thead><tr><th>Function</th><th>Description</th></tr></thead><tbody>' + cBody + "</tbody></table></div>"

# ^keyword\s+(\w+) with the keyword in any case (the line starts with it): the word, or ""
func wordAfterKeyword cLine,cKeyword,nTabs

	nKeyword = len(cKeyword)
	nAt = 1 + nTabs
	if lower(part(cLine,nAt,nAt + nKeyword - 1)) != cKeyword
		return ""
	ok
	nAt += nKeyword
	nSize = len(cLine)
	if nAt > nSize or not isSpaceCh(cLine[nAt])
		return ""
	ok
	while nAt <= nSize and isSpaceCh(cLine[nAt])
		nAt++
	end
	nStart = nAt
	while nAt <= nSize and isWordCh(cLine[nAt])
		nAt++
	end
	if nAt = nStart
		return ""
	ok
	return part(cLine,nStart,nAt - 1)

# ^(\t?)func\s+(\w+)\s*(.*)$ : [name, the rest, true for a function at the left margin] or []
func funcLine cLine

	lTop = left(cLine,1) != char(9)
	nTabs = 0
	if not lTop
		nTabs = 1
	ok
	cName = wordAfterKeyword(cLine,"func",nTabs)
	if cName = ""
		return []
	ok
	nStart = nTabs + 5
	nSize = len(cLine)
	while nStart <= nSize and isSpaceCh(cLine[nStart])
		nStart++
	end
	nAfter = nStart + len(cName)
	while nAfter <= nSize and isSpaceCh(cLine[nAfter])
		nAfter++
	end
	return [cName,tail(cLine,nAfter),lTop]

# (dn|db|wb|ui|wpf)_ removed: the prefix of the names of the parameters and variables that the library keeps to itself (dn_cResponse is shown as cResponse)
func dropPrefixes cText

	aOut = []
	nSize = len(cText)
	nPos = 1
	i = 1
	while i <= nSize
		nSkip = 0
		if i = 1 or not isWordCh(cText[i - 1])
			aPrefixes = ["dn_","db_","wb_","ui_","wpf_"]
			for cPrefix in aPrefixes
				if part(cText,i,i + len(cPrefix) - 1) = cPrefix
					nSkip = len(cPrefix)
					exit
				ok
			next
		ok
		if nSkip > 0
			if i > nPos
				aOut + part(cText,nPos,i - 1)
			ok
			i += nSkip
			nPos = i
		else
			i++
		ok
	end
	if nPos <= nSize
		aOut + part(cText,nPos,nSize)
	ok
	return joinList(aOut,"")

# the numbers of the home page: [:namespaces, :classes, :forms, :wpf, :apps, :tests]
func statsValues

	cGen = rootFolder() + "/libraries/dotnetlib/generated"
	nClasses = 0
	nWith = 0
	aLoop6 = listNames(cGen)
	for cFile in aLoop6
		if hasSuffix(cFile,".classes.ring")
			cText = readText(cGen + "/" + cFile)
			nHere = (len(cText) - len(substr(cText,nl + "Class ",""))) / 7
			if hasPrefix(cText,"Class ")
				nHere++
			ok
			nClasses += nHere
			if nHere > 0
				nWith++
			ok
		ok
	next
	nApps = 0
	cApps = rootFolder() + "/samples/UsingDotNet/applications"
	aLoop7 = listNames(cApps)
	for cDir in aLoop7
		if fexists(cApps + "/" + cDir + "/" + cDir + ".ring")
			nApps++
		ok
	next
	nTests = 0
	aLoop8 = listNames(rootFolder() + "/samples/UsingDotNet/tests")
	for cFile in aLoop8
		if hasPrefix(cFile,"test_")
			nTests++
		ok
	next
	return [:namespaces = "" + nWith,:classes = thousands(nClasses),:forms = "" + countFiles("samples/UsingDotNet/Forms"),:wpf = "" + countFiles("samples/UsingDotNet/Wpf"),:apps = "" + nApps,:tests = "" + nTests]

func countFiles cRel

	cFolder = rootFolder() + "/" + cRel
	if not direxists(cFolder)
		return 0
	ok
	nCount = 0
	aLoop9 = listNames(cFolder)
	for cFile in aLoop9
		if hasSuffix(cFile,".ring")
			nCount++
		ok
	next
	return nCount

# ---------------------------------------------------------------- templates
func sidebarHtml cCurrent,cRoot

	aOut = []
	cSection = ""
	nPages = len(aDocPages)
	for nPage = 1 to nPages
		aPage = aDocPages[nPage]
		if aPage[3] != cSection
			aOut + ("<h4>" + aPage[3] + "</h4>")
			cSection = aPage[3]
		ok
		cClass = ""
		if aPage[1] = cCurrent
			cClass = ' class="cur"'
		ok
		aOut + ('<a href="' + cRoot + aPage[1] + ".html" + '"' + cClass + ">" + aPage[2] + "</a>")
	next
	return joinList(aOut,nl)

func pageHtml cName,cTitle,cLead,cBody,cCurrent,cRoot,lToc,cHeading

	nPages = len(aDocPages)
	n = 0
	for nPage = 1 to nPages
		if aDocPages[nPage][1] = cName
			n = nPage
			exit
		ok
	next
	cPrev = "<span></span>"
	cNext = "<span></span>"
	if n > 1
		cPrev = '<a href="' + aDocPages[n - 1][1] + '.html"><small>Previous</small>' + aDocPages[n - 1][2] + "</a>"
	ok
	if n >= 1 and n < nPages
		cNext = '<a class="next" href="' + aDocPages[n + 1][1] + '.html"><small>Next</small>' + aDocPages[n + 1][2] + "</a>"
	ok
	cHead = ""
	if cName != "index"
		cShown = cHeading
		if cShown = ""
			cShown = cTitle
		ok
		cLeadHtml = ""
		if cLead != ""
			cLeadHtml = '<p class="lead">' + inlineMd(cLead) + "</p>"
		ok
		cHead = "<h1>" + esc(cShown) + "</h1>" + cLeadHtml
	ok
	if n = 0 or cName = "api"
		cPrev = ""
		cNext = ""
	ok
	cMeta = cLead
	if cMeta = ""
		cMeta = C_RING_COMMENT_DEFAULT
	ok
	cMeta = substr(substr(cMeta,"`",""),"*","")
	cToc = ""
	if lToc
		cToc = '<aside class="toc" id="toc"></aside>'
	ok
	return fillTemplate(aSettings[6],[["title",esc(cTitle)],["lead",esc(cMeta)],["sidebar",sidebarHtml(cCurrent,cRoot)],["head",cHead],["root",cRoot],["tocaside",cToc],["body",cBody],["prev",cPrev],["next",cNext]])
