# The class reference: one page per wrapped namespace (docs/api/<namespace>.html) and the index page (docs/api.html).
#
# Data: docs/tools/api-data/api.jsonl (made by dumpapi.ring: the .NET API of every class) and the generated Ring classes (libraries/dotnetlib/generated),
# which say how each member is called from Ring. Used by build.ring.

load "jsonlib.ring"

aApiKeywords = str2list(substr("next step call put get set load from to on off exit loop end return done try catch ok class func new import package private see give bye again break continue and or not if but else elseif for in while switch other"," ",nl))

# the lines of api.jsonl: the namespace, the Ring class and the JSON text (empty for a class that has no data)
aApiNs = []
aApiCls = []
aApiJson = []
aApiFull = []              # the "full" name of each class, as written in the JSON (not decoded)
aApiNsNames = []           # the namespaces
aApiNsClasses = []         # the numbers of the classes of each namespace
aApiNameCache = []         # [number of the class, its name, the base type written in the JSON]
aApiClassTexts = []        # [namespace, [[lower case class name, text]]]
aApiInfoKeys = []          # namespace + class of the classes in the cache of parseClassFile
aApiInfoValues = []         # the numbers in aInfos
aInfos = []                # the information of the generated classes: [base, attributes, functions, lower case names, .NET names, function numbers by .NET name, number of the base]
aApiClassNs = []           # [lower case class name] and the namespace that defines the class (a base class may be in another namespace)
aApiClassNsNames = []
aApiClassNsLoaded = []

func loadApi cFile

	aLines = str2list(read(cFile))
	nMax = len(aLines)
	for nLine = 1 to nMax
		cLine = aLines[nLine]
		if cLine = ""
			loop
		ok
		nTab1 = substr(cLine,char(9))
		cRest = substr(cLine,nTab1 + 1)
		nTab2 = substr(cRest,char(9))
		cNs = left(cLine,nTab1 - 1)
		cCls = left(cRest,nTab2 - 1)
		cJson = substr(cRest,nTab2 + 1)
		aApiNs + cNs
		aApiCls + cCls
		cFull = ""
		if left(cJson,5) = "ERROR"
			cJson = ""
		else
			nEnd = substr(cJson,'","name":"')
			cFull = part(cJson,10,nEnd - 1)
		ok
		aApiJson + cJson
		aApiFull + cFull
		nNs = find(aApiNsNames,cNs)
		if nNs = 0
			aApiNsNames + cNs
			aApiNsClasses + []
			nNs = len(aApiNsNames)
		ok
		aApiNsClasses[nNs] + (len(aApiNs))
	next
	aApiNameCache = list(len(aApiNs))
	for nItem = 1 to len(aApiNs)
		aApiNameCache[nItem] = []
	next

# ---------------------------------------------------------------- the data of the JSON (a list of [key, value] for an object)
func jIndex aObject,cKey

	nMax = len(aObject)
	for nItem = 1 to nMax
		if aObject[nItem][1] = cKey
			return nItem
		ok
	next
	return 0

func jText aObject,cKey

	nItem = jIndex(aObject,cKey)
	if nItem = 0
		return ""
	ok
	cValue = aObject[nItem][2]
	if isString(cValue)
		return cValue
	ok
	return "" + cValue

# the value as a truth value (a missing key is false)
func jFlag aObject,cKey

	nItem = jIndex(aObject,cKey)
	if nItem = 0
		return false
	ok
	cValue = aObject[nItem][2]
	if isNumber(cValue)
		return cValue != 0
	ok
	if isString(cValue)
		return cValue != "" and cValue != "false" and cValue != "null"
	ok
	return len(cValue) > 0

func jList aObject,cKey

	nItem = jIndex(aObject,cKey)
	if nItem = 0
		return []
	ok
	cValue = aObject[nItem][2]
	if isList(cValue)
		return cValue
	ok
	return []

# The constructors of a class: a list of the parameters of each constructor, a parameter is an object (a list of [key, value]).
# JSON2List loses the objects of an array in an array, so each constructor is read from its own text.
func ctorsOf cJson

	cStart = '"ctors":['
	nAt = substr(cJson,cStart)
	if nAt = 0
		return []
	ok
	aCtors = []
	nSize = len(cJson)
	i = nAt + len(cStart) - 1
	nDepth = 0
	nElement = 0
	lString = false
	while i <= nSize
		c = cJson[i]
		if lString
			if c = "\"
				i++
			but c = '"'
				lString = false
			ok
		but c = '"'
			lString = true
		but c = "["
			nDepth++
			if nDepth = 2
				nElement = i
			ok
		but c = "]"
			if nDepth = 2
				cElement = part(cJson,nElement,i)
				if cElement = "[]"
					aCtors + []
				else
					aWrapped = JSON2List('{"p":' + cElement + "}")
					aCtors + aWrapped[1][2]
				ok
			ok
			nDepth--
			if nDepth = 0
				exit
			ok
		ok
		i++
	end
	return aCtors

# the text of a field of the JSON text of a class, as written in the JSON ("" when the field is not there)
func rawField cJson,cKey

	cStart = '"' + cKey + '":"'
	nAt = substr(cJson,cStart)
	if nAt = 0
		return ""
	ok
	nBegin = nAt + len(cStart)
	nClose = findFrom(cJson,'"',nBegin)
	return part(cJson,nBegin,nClose - 1)

# [the name of the type, the base type as written in the JSON] of a class, from its JSON text (kept)
func ancestorInfo nClass

	if len(aApiNameCache[nClass]) = 0
		cJson = aApiJson[nClass]
		aApiNameCache[nClass] = [jsonUnescape(rawField(cJson,"name")),rawField(cJson,"basefull")]
	ok
	return aApiNameCache[nClass]

# ---------------------------------------------------------------- the generated classes
# the text of one class: the generated file of a namespace (<namespace>.classes.ring) has all its classes
func classText cNs,cClass

	nNs = 0
	nMax = len(aApiClassTexts)
	for nItem = 1 to nMax
		if aApiClassTexts[nItem][1] = cNs
			nNs = nItem
			exit
		ok
	next
	if nNs = 0
		aParts = []
		cPath = apiGenFolder() + "/" + cNs + ".classes.ring"
		if fexists(cPath)
			cText = readText(cPath)
			cText = substr(cText,nl + "Class ",char(3) + "Class ")
			aPieces = splitOn(cText,char(3))
			nPieces = len(aPieces)
			nFirst = 2
			if hasPrefix(cText,"Class ")
				nFirst = 1
			ok
			for nPiece = nFirst to nPieces
				cPiece = aPieces[nPiece]
				aHeader = classHeader(cPiece)
				if len(aHeader) > 0
					aParts + [lower(aHeader[1]),cPiece]
				ok
			next
		ok
		aApiClassTexts + [cNs,aParts]
		nNs = len(aApiClassTexts)
	ok
	cLow = lower(cClass)
	aParts = aApiClassTexts[nNs][2]
	nParts = len(aParts)
	cFound = ""
	for nPart = 1 to nParts
		if aParts[nPart][1] = cLow
			cFound = aParts[nPart][2]
		ok
	next
	return cFound

# Class\s+(\w+)\s+from\s+(\w+) at the start of a text: [name, base] or []
func classHeader cText

	if left(cText,5) != "Class"
		return []
	ok
	nSize = len(cText)
	nAt = 6
	if nAt > nSize or not isSpaceCh(cText[nAt])
		return []
	ok
	while nAt <= nSize and isSpaceCh(cText[nAt])
		nAt++
	end
	nStart = nAt
	while nAt <= nSize and isWordCh(cText[nAt])
		nAt++
	end
	if nAt = nStart
		return []
	ok
	cName = part(cText,nStart,nAt - 1)
	if nAt > nSize or not isSpaceCh(cText[nAt])
		return []
	ok
	while nAt <= nSize and isSpaceCh(cText[nAt])
		nAt++
	end
	if lower(part(cText,nAt,nAt + 3)) != "from"
		return []
	ok
	nAt += 4
	if nAt > nSize or not isSpaceCh(cText[nAt])
		return []
	ok
	while nAt <= nSize and isSpaceCh(cText[nAt])
		nAt++
	end
	nStart = nAt
	while nAt <= nSize and isWordCh(cText[nAt])
		nAt++
	end
	cBase = ""
	if nAt > nStart
		cBase = part(cText,nStart,nAt - 1)
	ok
	return [cName,cBase]

func apiGenFolder

	return rootFolder() + "/libraries/dotnetlib/generated"

# What the generated Ring class offers: [base class, the attributes (lower case), the functions, the names of the functions]
# a function: [ring name, number of parameters, .NET name, kind, takes NULL]
func parseClassFile cNs,cClass

	cKey = cNs + char(1) + lower(cClass)
	nCached = find(aApiInfoKeys,cKey)
	if nCached > 0
		return aApiInfoValues[nCached]
	ok
	nInfo = parseClassText(cNs,cClass)
	aApiInfoKeys + cKey
	aApiInfoValues + nInfo
	return nInfo

# the same without the cache (for the class that is being written: its own information is used once)
func parseClassText cNs,cClass

	aInfos + ["",[],[],[],[],[],-1]
	nInfo = len(aInfos)
	cText = classText(cNs,cClass)
	if cText != ""
		aHeader = classHeader(cText)
		if len(aHeader) > 0
			aInfos[nInfo][1] = aHeader[2]
		ok
		cText = substr(cText,nl + char(9) + "Func ",char(3))
		aBlocks = splitOn(cText,char(3))
		aAttrs = []
		aLoop10 = splitLines(aBlocks[1])
		for cLine in aLoop10
			if left(cLine,1) = char(9)
				cWord = pyRStrip(tail(cLine,2))
				if cWord != "" and allWord(cWord)
					aAttrs + lower(cWord)
				ok
			ok
		next
		aInfos[nInfo][2] = aAttrs
		nBlocks = len(aBlocks)
		for nBlock = 2 to nBlocks
			cBlock = aBlocks[nBlock]
			nNl = substr(cBlock,nl)
			cFirst = cBlock
			cBody = ""
			if nNl > 0
				cFirst = left(cBlock,nNl - 1)
				cBody = tail(cBlock,nNl + 1)
			ok
			aHeaderFunc = funcHeader(pyLStrip(cFirst))
			if len(aHeaderFunc) = 0
				loop
			ok
			cRing = aHeaderFunc[1]
			cParams = aHeaderFunc[2]
			nParams = 0
			if cParams != ""
				nParams = len(splitOn(cParams,","))
			ok
			cNet = ""
			cKind = "method"
			aCall = requestCall(cBody)
			if len(aCall) > 0
				cNet = aCall[2]
				if aCall[1] = "get" or aCall[1] = "set"
					cKind = aCall[1]
				ok
			but substr(cBody,'"setevent"') > 0 or substr(cBody,'"clearevent"') > 0
				cKind = "event"
			ok
			if substr(cBody,"dotnet_isnamed(P1)") > 0
				cKind = "dispatch"
			ok
			lNull = substr(cBody,'isstring(P1) and P1 = ""') > 0
			aInfos[nInfo][3] + [cRing,nParams,cNet,cKind,lNull]
			aInfos[nInfo][4] + lower(lstripChar(cRing,"@"))
			nGroup = find(aInfos[nInfo][5],cNet)
			if nGroup = 0
				aInfos[nInfo][5] + cNet
				aInfos[nInfo][6] + []
				nGroup = len(aInfos[nInfo][5])
			ok
			aInfos[nInfo][6][nGroup] + len(aInfos[nInfo][3])
		next
	ok
	return nInfo

# the number (in aInfos) of the Ring base class of a class, or 0
func baseOf nInfo

	if aInfos[nInfo][7] != -1
		return aInfos[nInfo][7]
	ok
	cBase = aInfos[nInfo][1]
	nBase = 0
	if cBase != ""
		cNs = findClassNs(cBase)
		if cNs != ""
			nBase = parseClassFile(cNs,cBase)
		ok
	ok
	aInfos[nInfo][7] = nBase
	return nBase

func allWord cText

	nMax = len(cText)
	for nChar = 1 to nMax
		if not isWordCh(cText[nChar])
			return false
		ok
	next
	return true

# (@?\w+)(?:\s+([\w,]+))?\s*$ : [name, parameters] or []
func funcHeader cFirst

	nSize = len(cFirst)
	nAt = 1
	if nAt <= nSize and cFirst[nAt] = "@"
		nAt++
	ok
	nStart = nAt
	while nAt <= nSize and isWordCh(cFirst[nAt])
		nAt++
	end
	if nAt = nStart
		return []
	ok
	cName = part(cFirst,1,nAt - 1)
	cRest = tail(cFirst,nAt)
	if pyStrip(cRest) = ""
		return [cName,""]
	ok
	if not isSpaceCh(left(cRest,1))
		return []
	ok
	cRest = pyStrip(cRest)
	nMax = len(cRest)
	for nChar = 1 to nMax
		c = cRest[nChar]
		if not (isWordCh(c) or c = ",")
			return []
		ok
	next
	return [cName,cRest]

# "s4:call",<handle or type>,"s6:Append": [the operation, the .NET name] of the first request in a text, or []
func requestCall cBody

	nPos = 1
	while true
		nAt = findFrom(cBody,'"s',nPos)
		if nAt = 0
			return []
		ok
		nPos = nAt + 1
		nSize = len(cBody)
		k = nAt + 2
		nDigits = k
		while k <= nSize and isDigitCh(cBody[k])
			k++
		end
		if k = nDigits or k > nSize or cBody[k] != ":"
			loop
		ok
		k++
		cOp = ""
		for cTry in ["callnamed","call","get","set"]
			if part(cBody,k,k + len(cTry) - 1) = cTry and part(cBody,k + len(cTry),k + len(cTry) + 1) = '",'
				cOp = cTry
				exit
			ok
		next
		if cOp = ""
			loop
		ok
		nSeg = k + len(cOp) + 2
		nQuote = findFrom(cBody,'"',nSeg)
		if nQuote = 0 or nQuote - 1 < nSeg or cBody[nQuote - 1] != ","
			loop
		ok
		# "s<digits>:<word>" after the comma
		j = nQuote + 1
		if j > nSize or cBody[j] != "s"
			loop
		ok
		j++
		nDig = j
		while j <= nSize and isDigitCh(cBody[j])
			j++
		end
		if j = nDig or j > nSize or cBody[j] != ":"
			loop
		ok
		j++
		nWord = j
		while j <= nSize and isWordCh(cBody[j])
			j++
		end
		if j = nWord or j > nSize or cBody[j] != '"'
			loop
		ok
		return [cOp,part(cBody,nWord,j - 1)]
	end

# the namespace whose generated file defines the Ring class (a base class may be in another namespace)
func findClassNs cClass

	if len(aApiClassNsLoaded) = 0
		aApiClassNsLoaded + 1
		cGen = apiGenFolder()
		aLoop11 = listNames(cGen)
		for cFile in aLoop11
			if hasSuffix(cFile,".classes.ring")
				cNs = left(cFile,len(cFile) - 13)
				cText = readText(cGen + "/" + cFile)
				cText = substr(cText,nl + "Class ",char(3) + "Class ")
				aPieces = splitOn(cText,char(3))
				nPieces = len(aPieces)
				nFirst = 2
				if hasPrefix(cText,"Class ")
					nFirst = 1
				ok
				for nPiece = nFirst to nPieces
					aHeader = classHeader(aPieces[nPiece])
					if len(aHeader) > 0
						cLow = lower(aHeader[1])
						if find(aApiClassNsNames,cLow) = 0
							aApiClassNsNames + cLow
							aApiClassNs + cNs
						ok
					ok
				next
			ok
		next
	ok
	nAt = find(aApiClassNsNames,lower(cClass))
	if nAt = 0
		return ""
	ok
	return aApiClassNs[nAt]

# True when the class, or one of its Ring base classes, has a method with this name
func hasFunc nInfo,cRingName

	cLow = lower(cRingName)
	nNow = nInfo
	nGuard = 0
	while nNow > 0 and nGuard < 30
		if find(aInfos[nNow][4],cLow) > 0
			return true
		ok
		nNow = baseOf(nNow)
		nGuard++
	end
	return false

# the Ring calls of a method: the class's own, or else the ones it inherits from the Ring base classes
func formsWithBases cName,nInfo,aOverloads

	aForms = ringForms(cName,nInfo,aOverloads)
	nGuard = 0
	nCurrent = baseOf(nInfo)
	while len(aForms) = 0 and nCurrent > 0 and nGuard < 30
		aForms = ringForms(cName,nCurrent,aOverloads)
		nCurrent = baseOf(nCurrent)
		nGuard++
	end
	if len(aForms) = 0 and len(aOverloads) > 0
		# a name that DotNetObject already has (Release, IsNull, New, ToList...) has no method of its own: callMethod calls the .NET one
		aCounts = []
		for aOverload in aOverloads
			nCount = len(jList(aOverload,"p"))
			if find(aCounts,nCount) = 0
				aCounts + nCount
			ok
		next
		aCounts = sort(aCounts)
		for nCount in aCounts
			aArgs = []
			for nArg = 1 to nCount
				aArgs + ("p" + nArg)
			next
			aForms + ('callMethod("' + cName + '",[' + joinList(aArgs,",") + "])")
		next
	ok
	return aForms

func sigParams aParams

	aOut = []
	for aParam in aParams
		cMod = ""
		if jText(aParam,"m") != ""
			cMod = jText(aParam,"m") + " "
		ok
		cOpt = ""
		if jFlag(aParam,"o")
			cOpt = " = " + C_UNICODE_ELLIPSIS
		ok
		aOut + (cMod + jText(aParam,"t") + " " + jText(aParam,"n") + cOpt)
	next
	return joinList(aOut,", ")

# The ways to call a .NET method from Ring. A method with overloads of several arities is one Ring method that takes one parameter:
# Name(NULL) for the parameterless overload, Name(value) for one parameter, Name([ :param = value ]) by the parameter names.
func ringForms cName,nInfo,aOverloads

	aForms = []
	nOverloads = len(aOverloads)
	nGroup = find(aInfos[nInfo][5],cName)
	nWanted = 0
	if nGroup > 0
		nWanted = len(aInfos[nInfo][6][nGroup])
	ok
	for nIndex = 1 to nWanted
		aFunc = aInfos[nInfo][3][aInfos[nInfo][6][nGroup][nIndex]]
		if not (aFunc[4] = "method" or aFunc[4] = "dispatch")
			loop
		ok
		cRing = aFunc[1]
		if aFunc[4] = "dispatch"
			aArities = []
			for aOverload in aOverloads
				nCount = len(jList(aOverload,"p"))
				if find(aArities,nCount) = 0
					aArities + nCount
				ok
			next
			if aFunc[5] and (find(aArities,0) > 0 or nOverloads = 0)
				aForms + (cRing + "(NULL)")
			ok
			if find(aArities,1) > 0 or nOverloads = 0
				aForms + (cRing + "(value)")
			ok
			aShown = []
			aOrder = sortByParamCount(aOverloads)
			for nOrder in aOrder
				aNames = []
				aLoop12 = jList(aOverloads[nOrder],"p")
				for aParam in aLoop12
					aNames + jText(aParam,"n")
				next
				cNames = joinList(aNames,char(1))
				if len(aNames) > 0 and find(aShown,cNames) = 0 and len(aShown) < 4
					aShown + cNames
					aPairs = []
					for cParamName in aNames
						aPairs + (":" + cParamName + " = " + C_UNICODE_ELLIPSIS)
					next
					aForms + (cRing + "([ " + joinList(aPairs,", ") + " ])")
				ok
			next
			if nOverloads = 0
				aForms + (cRing + "([ :name = value ])")
			ok
		else
			aArgs = []
			for nArg = 1 to aFunc[2]
				aArgs + ("p" + nArg)
			next
			aForms + (cRing + "(" + joinList(aArgs,",") + ")")
		ok
	next
	aOut = []
	for cForm in aForms
		if find(aOut,cForm) = 0
			aOut + cForm
		ok
	next
	return aOut

# the numbers of the overloads, ordered by the number of their parameters (the order of the list for the same number)
func sortByParamCount aOverloads

	aKeys = []
	nMax = len(aOverloads)
	for nItem = 1 to nMax
		aKeys + [len(jList(aOverloads[nItem],"p")) * 1000000 + nItem,nItem]
	next
	aKeys = sort(aKeys,1)
	aOrder = []
	for aKey in aKeys
		aOrder + aKey[2]
	next
	return aOrder

func apiAnchor cClass

	return "c-" + cClass

# ---------------------------------------------------------------- a class
# aData is the JSON of the class as a list; aWrapped are the names of its documented ancestors
func renderClass cNs,cClass,aData,nInfo,aWrapped,nClass

	aOut = []
	if len(aData) = 0
		return '<details class="cls" id="' + apiAnchor(cClass) + '"><summary><b>' + esc(cClass) + '</b> <span class="pill">no reflection data</span></summary></details>'
	ok
	cKind = jText(aData,"kind")
	aTags = [cKind]
	for cTag in ["static","abstract","sealed"]
		if jFlag(aData,cTag)
			aTags + cTag
		ok
	next
	cBase = ""
	cBaseName = jText(aData,"base")
	if cBaseName != ""
		nBase = byFull(rawField(aApiJson[nClass],"basefull"))
		if nBase > 0
			cBaseNs = aApiNs[nBase]
			cBaseCls = aApiCls[nBase]
			if cBaseNs != cNs
				cBase = ' · extends <a href="' + cBaseNs + ".html#" + apiAnchor(cBaseCls) + '">' + esc(cBaseCls) + "</a>"
			else
				cBase = ' · extends <a href="#' + apiAnchor(cBaseCls) + '">' + esc(cBaseCls) + "</a>"
			ok
		else
			cBase = " · extends " + esc(cBaseName)
		ok
	ok
	cSummary = "<b>" + esc(cClass) + '</b> <span class="muted">' + joinList(aTags," ") + cBase + "</span>"
	aOut + ('<details class="cls" id="' + apiAnchor(cClass) + '"><summary>' + cSummary + "</summary>")
	aOut + '<div class="clsbody">'
	aOut + ('<p class="net"><code>' + esc(jText(aData,"full")) + "</code> · assembly <code>" + esc(jText(aData,"asm")) + "</code></p>")
	aInterfaces = jList(aData,"interfaces")
	if len(aInterfaces) > 0
		aOut + ('<p class="muted">Implements: ' + esc(joinList(aInterfaces,", ")) + "</p>")
	ok

	# enums
	aValues = jList(aData,"values")
	if len(aValues) > 0
		aShown = []
		nShown = len(aValues)
		if nShown > 60
			nShown = 60
		ok
		for nValue = 1 to nShown
			aShown + ('"' + aValues[nValue] + '"')
		next
		cValues = joinList(aShown,", ")
		if len(aValues) > 60
			cValues += " " + C_UNICODE_ELLIPSIS
		ok
		aOut + ("<h4>Values</h4><p>Enum values are strings in Ring: <code>" + esc(cValues) + "</code></p>")
	ok

	# constructors
	aCtors = ctorsOf(aApiJson[nClass])
	if len(aCtors) > 0 and cKind != "enum"
		cRows = ""
		for aCtor in aCtors
			cRows += "<tr><td><code>new " + esc(cClass) + "(" + esc(sigParams(aCtor)) + ")</code></td></tr>"
		next
		aOut + ('<h4>Constructors</h4><div class="tablewrap"><table class="api"><tbody>' + cRows + "</tbody></table></div>")
		aOut + ('<p class="muted">Ring: <code>new ' + esc(cClass) + "(args)</code> uses one constructor; the others are chosen by the parameter names: <code>new " + esc(cClass) + '().@New([ :param = value ])</code> or <code>dnNew("' + esc(cClass) + '",[ :param = value ])</code>.</p>')
	ok

	# properties and fields
	aMembers = []
	aLoop13 = jList(aData,"props")
	for aProp in aLoop13
		if ownMember(aProp,aWrapped)
			aMembers + aProp
		ok
	next
	aLoop14 = jList(aData,"fields")
	for aProp in aLoop14
		if ownMember(aProp,aWrapped)
			aMembers + aProp
		ok
	next
	if len(aMembers) > 0
		cRows = ""
		for aProp in aMembers
			aAccess = []
			if jIndex(aProp,"r") = 0 or jFlag(aProp,"r")
				aAccess + "read"
			ok
			if jFlag(aProp,"w")
				aAccess + "write"
			ok
			if jFlag(aProp,"c")
				aAccess = ["constant"]
			ok
			cName = jText(aProp,"n")
			cLow = lower(cName)
			cWrite = ""
			if find(aInfos[nInfo][2],cLow) > 0
				if jFlag(aProp,"w")
					cWrite = " <code>o." + esc(cName) + " = v</code>"
				ok
				cUse = "<code>o." + esc(cName) + "</code>" + cWrite
			but not hasFunc(nInfo,"get" + cName)
				cUse = '<span class="muted">—</span>'
			else
				if jFlag(aProp,"w")
					cWrite = " <code>o.set" + esc(cName) + "(v)</code>"
				ok
				cUse = "<code>o.get" + esc(cName) + "()</code>" + cWrite
			ok
			cStatic = ""
			if jFlag(aProp,"s")
				cStatic = " · static"
			ok
			cRows += "<tr><td><code>" + esc(cName) + "</code></td><td><code>" + esc(jText(aProp,"t")) + "</code></td><td>" + esc(joinList(aAccess,", ")) + cStatic + "</td><td>" + cUse + "</td></tr>"
		next
		aOut + ('<h4>Properties and fields</h4><div class="tablewrap"><table class="api"><thead><tr><th>Name</th><th>Type</th><th>Access</th><th>In Ring</th></tr></thead><tbody>' + cRows + "</tbody></table></div>")
	ok

	# indexers
	aLoop15 = jList(aData,"indexers")
	for aIndexer in aLoop15
		cSet = ""
		if jFlag(aIndexer,"w")
			cSet = " · <code>o.SetItem(" + esc(jText(aIndexer,"n")) + ",value)</code>"
		ok
		aOut + ("<h4>Indexer</h4><p><code>o.Item(" + esc(jText(aIndexer,"i")) + " " + esc(jText(aIndexer,"n")) + ")</code> → <code>" + esc(jText(aIndexer,"t")) + "</code>" + cSet + "</p>")
	next

	# methods
	aGroupNames = []
	aGroups = []
	aLoop16 = jList(aData,"methods")
	for aMethod in aLoop16
		if ownMember(aMethod,aWrapped)
			cName = jText(aMethod,"n")
			nGroup = find(aGroupNames,cName)
			if nGroup = 0
				aGroupNames + cName
				aGroups + []
				nGroup = len(aGroupNames)
			ok
			aGroups[nGroup] + aMethod
		ok
	next
	if len(aGroupNames) > 0
		cRows = ""
		aOrder = sortedByLower(aGroupNames)
		for nGroup in aOrder
			cName = aGroupNames[nGroup]
			aMs = aGroups[nGroup]
			aForms = formsWithBases(cName,nInfo,aMs)
			aSigs = []
			for aMethod in aMs
				cGeneric = ""
				if jText(aMethod,"g") != ""
					cGeneric = "<" + jText(aMethod,"g") + ">"
				ok
				cStatic = ""
				if jFlag(aMethod,"s")
					cStatic = "static "
				ok
				aSigs + (cStatic + jText(aMethod,"r") + " " + cName + cGeneric + "(" + sigParams(jList(aMethod,"p")) + ")")
			next
			cFormsHtml = '<span class="muted">—</span>'
			if len(aForms) > 0
				aCodes = []
				for cForm in aForms
					aCodes + ("<code>" + esc(cForm) + "</code>")
				next
				cFormsHtml = joinList(aCodes,"<br>")
			ok
			aSigCodes = []
			for cSig in aSigs
				aSigCodes + ("<code>" + esc(cSig) + "</code>")
			next
			cRows += "<tr><td><code>" + esc(cName) + "</code></td><td>" + cFormsHtml + "</td><td>" + joinList(aSigCodes,"<br>") + "</td></tr>"
		next
		aOut + ('<h4>Methods</h4><div class="tablewrap"><table class="api"><thead><tr><th>Method</th><th>Ring call</th><th>.NET overloads</th></tr></thead><tbody>' + cRows + "</tbody></table></div>")
	ok

	# events
	cRows = ""
	nEvents = 0
	aLoop17 = jList(aData,"events")
	for aEvent in aLoop17
		if ownMember(aEvent,aWrapped)
			cEvent = esc(jText(aEvent,"n"))
			cRows += "<tr><td><code>" + cEvent + "</code></td><td><code>" + esc(jText(aEvent,"t")) + "</code></td><td><code>o.set" + cEvent + "Event(code)</code> · <code>o.clear" + cEvent + "Event()</code></td></tr>"
			nEvents++
		ok
	next
	if nEvents > 0
		aOut + ('<h4>Events</h4><div class="tablewrap"><table class="api"><thead><tr><th>Event</th><th>Handler type</th><th>In Ring</th></tr></thead><tbody>' + cRows + "</tbody></table></div>")
	ok
	if jText(aData,"base") != "" and cBase != ""
		aOut + '<p class="muted">Members of the base class are inherited.</p>'
	ok
	aOut + "</div></details>"
	return joinList(aOut,nl)

# a member of the class itself: it does not come from a documented ancestor
func ownMember aItem,aWrapped

	cFrom = jText(aItem,"from")
	return cFrom = "" or find(aWrapped,cFrom) = 0

# the numbers of the texts, ordered by their lower case text (the order of the list for the same text)
func sortedByLower aTexts

	aKeys = []
	nMax = len(aTexts)
	for nItem = 1 to nMax
		aKeys + [lower(aTexts[nItem]) + char(1) + padNumber(nItem),nItem]
	next
	aKeys = sort(aKeys,1)
	aOrder = []
	for aKey in aKeys
		aOrder + aKey[2]
	next
	return aOrder

func padNumber n

	cNum = "" + n
	return copy("0",8 - len(cNum)) + cNum

# the number of the class whose "full" name is cFull (as written in the JSON), or 0
func byFull cFull

	if cFull = ""
		return 0
	ok
	return find(aApiFull,cFull)

# ---------------------------------------------------------------- the pages
# [the number of classes, the number of namespaces]
func buildApiPages cDocs

	loadApi(hereFolder() + "/api-data/api.jsonl")
	if not direxists(cDocs + "/api")
		system("mkdir " + substr(cDocs + "/api","/",iff(isWindows(),"\","/")))
	ok
	aIndexItems = []
	aNsRows = []
	nTotal = 0
	aNsOrder = sort(aApiNsNames)
	nNsCount = len(aNsOrder)
	for nNsOrder = 1 to nNsCount
		cNs = aNsOrder[nNsOrder]
		nNs = find(aApiNsNames,cNs)
		aNumbers = aApiNsClasses[nNs]
		aNames = []
		for nNumber in aNumbers
			aNames + aApiCls[nNumber]
		next
		aOrder = sortedByLower(aNames)
		aSortedNumbers = []
		for nOrder in aOrder
			aSortedNumbers + aNumbers[nOrder]
		next
		aParts = []
		aChips = []
		cAsm = ""
		for nClass in aSortedNumbers
			cClass = aApiCls[nClass]
			aData = []
			if aApiJson[nClass] != ""
				aData = JSON2List(aApiJson[nClass])
			ok
			nInfo = parseClassText(cNs,cClass)
			# the documented ancestors: their members are inherited, not repeated
			aWrapped = []
			if len(aData) > 0
				cBaseFull = rawField(aApiJson[nClass],"basefull")
				nGuard = 0
				while cBaseFull != "" and nGuard < 30
					nBase = byFull(cBaseFull)
					if nBase = 0
						exit
					ok
					aAnc = ancestorInfo(nBase)
					aWrapped + aAnc[1]
					cBaseFull = aAnc[2]
					nGuard++
				end
			ok
			aParts + renderClass(cNs,cClass,aData,nInfo,aWrapped,nClass)
			aInfos[nInfo] = []
			cKind = "class"
			if len(aData) > 0
				cKind = jText(aData,"kind")
				if cAsm = ""
					cAsm = jText(aData,"asm")
				ok
			ok
			aChips + ('<a href="#' + apiAnchor(cClass) + '">' + esc(cClass) + "</a>")
			aIndexItems + ("[" + jsonString(cClass) + "," + jsonString(cNs) + "," + jsonString(cKind) + "]")
			nTotal++
		next
		aNsRows + [cNs,len(aSortedNumbers),cAsm]
		cBody = '<p class="lead">' + len(aSortedNumbers) + ' wrapped types. Load them with <code>using { "' + esc(cNs) + '" }</code>. Click a class to open it.</p>' + '<div class="chips">' + joinList(aChips," ") + "</div>" + joinList(aParts,nl)
		writeText(cDocs + "/api/" + cNs + ".html",pageHtml("api/" + cNs,cNs,"",cBody,"api","../",false,cNs))
		aParts = []
	next
	# the index page
	cRows = ""
	for aRow in aNsRows
		cRows += '<tr><td><a href="api/' + aRow[1] + '.html">' + esc(aRow[1]) + "</a></td><td>" + aRow[2] + "</td><td><code>" + esc(aRow[3]) + "</code></td></tr>"
	next
	cBody = '<p class="lead">Every .NET class that RingDotNet wraps: ' + nTotal + " classes, structs, interfaces and enums in " + len(aNsRows) + " namespaces. "
	cBody += 'Each entry shows the .NET type, constructors, properties (as Ring attributes), methods (with the way to call them from Ring), and events.</p>'
	cBody += '<div class="callout tip"><span class="t">Tip</span><p>Use the search box (<kbd>/</kbd>) to find a class by name. '
	cBody += 'Load a namespace with <code>using { "System.Text" }</code>. How members are named in Ring: <a href="concepts.html">Core concepts</a>.</p></div>'
	cBody += "<h2>Reading the Ring call column</h2><ul>"
	cBody += "<li><code>Name(p1,p2)</code>: a method that has one form takes its parameters in order.</li>"
	cBody += "<li><code>Name(NULL)</code>, <code>Name(value)</code>, <code>Name([ :param = " + C_UNICODE_ELLIPSIS + " ])</code>: a method with several overloads is one Ring method that takes one argument: <code>NULL</code> for no parameters, a value for one, or a list of named parameters.</li>"
	cBody += '<li><code>callMethod("Name",[p1,p2])</code>: the .NET name is one that every object already has in Ring (<code>Release</code>, <code>IsNull</code>, <code>New</code>, <code>ToList</code>...), so the method is called with <code>callMethod</code>.</li>'
	cBody += "<li>A name with <code>@</code> (<code>@Next</code>) is a .NET name that is a Ring keyword.</li></ul>"
	cBody += '<div class="tablewrap"><table><thead><tr><th>Namespace</th><th>Types</th><th>Assembly</th></tr></thead><tbody>' + cRows + "</tbody></table></div>"
	writeText(cDocs + "/api.html",pageHtml("api","Class reference","",cBody,"api","",true,"Class reference"))
	writeText(cDocs + "/assets/api-index.js","window.API_INDEX = [" + joinList(aIndexItems,",") + "];")
	return [nTotal,len(aNsRows)]
