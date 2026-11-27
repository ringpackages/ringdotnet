# Turns runs of  oVar.Member = value / oVar.Method(...)  lines into Ring brace blocks:
#
#     oInfo = new ProcessStartInfo()            oInfo = new ProcessStartInfo() {
#     oInfo.FileName = "cmd"            --->        FileName = "cmd"
#     oInfo.Arguments = "/c ver"                    Arguments = "/c ver"
#                                               }
#
# A run (2 or more consecutive lines on the same variable) is skipped when a name used on the right side could be taken for a member of the
# object inside the braces (any name of the generated classes), so the meaning never changes. Prints what it skipped.
#
#     cd docs/tools
#     ring bracify.ring [--dry] file ...
#
# Plain Ring (the old Python tool, with its regular expressions written as scans of the line).

load "doclib.ring"

aNames = []                # the names of the generated classes (sorted, lower case)
aKeep = ["true","false","null","nl","tab","string","number","list","self","this"]
aCallNames = ["Controls.Add","Items.Add","Nodes.Add","Children.Add","Columns.Add","Rows.Add","Add","Append"]

func main

	lDry = false
	aFiles = []
	nArgs = len(sysargv)
	for nArg = 3 to nArgs
		if sysargv[nArg] = "--dry"
			lDry = true
		but left(sysargv[nArg],2) != "--"
			aFiles + sysargv[nArg]
		ok
	next
	cHere = programFolder()
	cRoot = parentFolder(parentFolder(cHere))
	loadNames(cRoot + "/libraries/dotnetlib/generated")
	aReport = []
	nBlocks = 0
	nChanged = 0
	for cFile in aFiles
		cText = read(cFile)
		cShown = relativeName(cFile,cRoot)
		aResult = transform(cText,cShown,aReport)
		if aResult[2] > 0
			nBlocks += aResult[2]
			nChanged++
			if not lDry
				write(cFile,aResult[1])
			ok
		ok
	next
	cNote = ""
	if lDry
		cNote = " (dry run)"
	ok
	? "" + nBlocks + " blocks in " + nChanged + " files" + cNote
	for cLine in aReport
		? cLine
	next

# the path relative to the root of the package, with slashes (os.path.relpath)
func relativeName cFile,cRoot

	cPath = substr(cFile,"\","/")
	if not (left(cPath,1) = "/" or substr(cPath,":") > 0)
		cPath = substr(currentdir(),"\","/") + "/" + cPath
	ok
	aPath = str2list(substr(cPath,"/",nl))
	aRoot = str2list(substr(cRoot,"/",nl))
	nCommon = 0
	nMax = min([len(aPath),len(aRoot)])
	for nPart = 1 to nMax
		if lower(aPath[nPart]) = lower(aRoot[nPart])
			nCommon = nPart
		else
			exit
		ok
	next
	aOut = []
	for nPart = nCommon + 1 to len(aRoot)
		aOut + ".."
	next
	for nPart = nCommon + 1 to len(aPath)
		aOut + aPath[nPart]
	next
	return joinList(aOut,"/")

# every attribute and method name of the generated classes (and of the helper classes): inside braces they win over variables
func loadNames cGen

	aAll = []
	readNames(cGen,aAll)
	for cExtra in ["add","close","show","text","name","count","item","clear","left","right","top","bottom","width","height","size","location","color","x","y","value","start","stop","enabled","visible","tag","font","image","id","length","type","init","show","hide","focus","update","refresh","run","line","pixel","brush","pen","fill","key"]
		aAll + cExtra
	next
	aAll = sort(aAll)
	aNames = []
	cLast = ""
	nMax = len(aAll)
	for nName = 1 to nMax
		if aAll[nName] != cLast
			aNames + aAll[nName]
			cLast = aAll[nName]
		ok
	next

func readNames cFolder,aAll

	aItems = dir(cFolder)
	nItems = len(aItems)
	for nItem = 1 to nItems
		cName = aItems[nItem][1]
		if aItems[nItem][2]
			readNames(cFolder + "/" + cName,aAll)
		but hasSuffix(cName,".ring")
			aLines = str2list(read(cFolder + "/" + cName))
			nLines = len(aLines)
			for nLine = 1 to nLines
				cLine = aLines[nLine]
				if left(cLine,1) = char(9)
					cWord = lineName(cLine)
					if cWord != ""
						aAll + lower(cWord)
					ok
				ok
			next
		ok
	next

# ^\t(?:Func\s+)?([A-Za-z_]\w*)\b : the name at the start of a line that begins with a tab, or ""
func lineName cLine

	nSize = len(cLine)
	nAt = 2
	if part(cLine,2,5) = "Func" and nSize >= 6 and isSpaceCh(cLine[6])
		k = 6
		while k <= nSize and isSpaceCh(cLine[k])
			k++
		end
		if k <= nSize and (isLetterCh(cLine[k]) or cLine[k] = "_")
			nAt = k
		ok
	ok
	if nAt > nSize or not (isLetterCh(cLine[nAt]) or cLine[nAt] = "_")
		return ""
	ok
	j = nAt
	while j < nSize and isWordCh(cLine[j + 1])
		j++
	end
	return part(cLine,nAt,j)

func isKnownName cLow

	return binarysearch(aNames,cLow) > 0

# ---------------------------------------------------------------- the lines
# is cTail (from nFrom) white space only, or white space and a comment? [ok, the comment text (with its white space) or ""]
func endOfStatement cLine,nFrom

	nSize = len(cLine)
	k = nFrom
	while k <= nSize and isSpaceCh(cLine[k])
		k++
	end
	if k > nSize
		return [true,""]
	ok
	if cLine[k] = "#" and k > nFrom
		return [true,tail(cLine,nFrom)]
	ok
	return [false,""]

# the line of a statement  oName.rest  [# comment]  : [indent, variable, rest, comment] or []
func matchStatement cLine

	nSize = len(cLine)
	i = 1
	while i <= nSize and (cLine[i] = " " or cLine[i] = char(9))
		i++
	end
	if i + 1 > nSize or cLine[i] != "o" or not isUpperCh(cLine[i + 1])
		return []
	ok
	j = i + 1
	while j <= nSize and isWordCh(cLine[j])
		j++
	end
	if j > nSize or cLine[j] != "."
		return []
	ok
	nRest = j + 1
	aMatch = matchCall(cLine,nRest)
	if len(aMatch) = 0
		aMatch = matchAssign(cLine,nRest)
	ok
	if len(aMatch) = 0
		return []
	ok
	return [part(cLine,1,i - 1),part(cLine,i,j - 1),aMatch[1],aMatch[2]]

# the calls: set...Event(...), clear...Event(...), Controls.Add(...), Items.Add(...) ..., Add(...), Append(...) : [rest, comment] or []
func matchCall cLine,nFrom

	nSize = len(cLine)
	nOpen = findFrom(cLine,"(",nFrom)
	if nOpen = 0
		return []
	ok
	cName = part(cLine,nFrom,nOpen - 1)
	lName = find(aCallNames,cName) > 0
	if not lName
		if left(cName,3) = "set" and right(cName,5) = "Event" and len(cName) >= 9 and allWordChars(cName)
			lName = true
		but left(cName,5) = "clear" and right(cName,5) = "Event" and len(cName) >= 11 and allWordChars(cName)
			lName = true
		ok
	ok
	if not lName
		return []
	ok
	# \(.*\) : the last ) with a valid end of the line after it
	for q = nSize to nOpen + 1 step -1
		if cLine[q] = ")"
			aEnd = endOfStatement(cLine,q + 1)
			if aEnd[1]
				return [part(cLine,nFrom,q),aEnd[2]]
			ok
		ok
	next
	return []

func allWordChars cText

	nMax = len(cText)
	for nChar = 1 to nMax
		if not isWordCh(cText[nChar])
			return false
		ok
	next
	return true

# [A-Za-z_][\w.]*\s*(?:\+=|-=|=)\s*.+?  (the value ends where the end of the line, white space or a comment, begins)
func matchAssign cLine,nFrom

	nSize = len(cLine)
	if nFrom > nSize or not (isLetterCh(cLine[nFrom]) or cLine[nFrom] = "_")
		return []
	ok
	k = nFrom
	while k <= nSize and (isWordCh(cLine[k]) or cLine[k] = ".")
		k++
	end
	while k <= nSize and isSpaceCh(cLine[k])
		k++
	end
	nOperator = 0
	if part(cLine,k,k + 1) = "+=" or part(cLine,k,k + 1) = "-="
		nOperator = 2
	but part(cLine,k,k) = "="
		nOperator = 1
	ok
	if nOperator = 0
		return []
	ok
	k += nOperator
	nValue = k
	while nValue <= nSize and isSpaceCh(cLine[nValue])
		nValue++
	end
	if nValue > nSize
		# nothing after the white space: the last white space is the value
		if nValue = k
			return []
		ok
		nValue = nSize
	ok
	for e = nValue + 1 to nSize + 1
		aEnd = endOfStatement(cLine,e)
		if aEnd[1]
			return [part(cLine,nFrom,e - 1),aEnd[2]]
		ok
	next
	return []

# ^[ \t]*(o[A-Z]\w*)\s*=\s*(new\s+[A-Za-z_]\w*\s*\((?:[^()]|\([^()]*\))*\))\s*$ : [indent, variable] or []
func matchNew cLine

	nSize = len(cLine)
	i = 1
	while i <= nSize and (cLine[i] = " " or cLine[i] = char(9))
		i++
	end
	if i + 1 > nSize or cLine[i] != "o" or not isUpperCh(cLine[i + 1])
		return []
	ok
	j = i + 1
	while j <= nSize and isWordCh(cLine[j])
		j++
	end
	cVar = part(cLine,i,j - 1)
	k = j
	while k <= nSize and isSpaceCh(cLine[k])
		k++
	end
	if k > nSize or cLine[k] != "="
		return []
	ok
	k++
	while k <= nSize and isSpaceCh(cLine[k])
		k++
	end
	if part(cLine,k,k + 2) != "new" or k + 3 > nSize or not isSpaceCh(cLine[k + 3])
		return []
	ok
	k += 3
	while k <= nSize and isSpaceCh(cLine[k])
		k++
	end
	if k > nSize or not (isLetterCh(cLine[k]) or cLine[k] = "_")
		return []
	ok
	while k <= nSize and isWordCh(cLine[k])
		k++
	end
	while k <= nSize and isSpaceCh(cLine[k])
		k++
	end
	if k > nSize or cLine[k] != "("
		return []
	ok
	k++
	# the arguments: no parentheses, or one level of them
	while k <= nSize
		c = cLine[k]
		if c = "("
			k++
			while k <= nSize and cLine[k] != "(" and cLine[k] != ")"
				k++
			end
			if k > nSize or cLine[k] = "("
				return []
			ok
			k++
		but c = ")"
			exit
		else
			k++
		ok
	end
	if k > nSize
		return []
	ok
	k++
	while k <= nSize and isSpaceCh(cLine[k])
		k++
	end
	if k <= nSize
		return []
	ok
	return [part(cLine,1,i - 1),cVar]

# the names of an expression (not the ones after a dot or after new), in lower case; the text of the strings does not count
func identifiers cExpr

	cText = withoutStrings(cExpr)
	aOut = []
	nSize = len(cText)
	i = 1
	while i <= nSize
		c = cText[i]
		if isLetterCh(c) or c = "_"
			j = i
			while j < nSize and isWordCh(cText[j + 1])
				j++
			end
			# what is before: the last character that is not white space
			k = i - 1
			while k >= 1 and isSpaceCh(cText[k])
				k--
			end
			lSkip = false
			if k >= 1 and cText[k] = "."
				lSkip = true
			ok
			if k >= 3 and part(cText,k - 2,k) = "new" and (k = 3 or not isWordCh(cText[k - 3]))
				lSkip = true
			ok
			if not lSkip
				aOut + lower(part(cText,i,j))
			ok
			i = j + 1
		else
			i++
		ok
	end
	return aOut

# "[^"]*" and '[^']*' replaced by ""
func withoutStrings cText

	aOut = []
	nSize = len(cText)
	nPos = 1
	i = 1
	while i <= nSize
		c = cText[i]
		if c = '"' or c = "'"
			nClose = findFrom(cText,c,i + 1)
			if nClose > 0
				if i > nPos
					aOut + part(cText,nPos,i - 1)
				ok
				aOut + '""'
				nPos = nClose + 1
				i = nPos
				loop
			ok
		ok
		i++
	end
	if nPos <= nSize
		aOut + part(cText,nPos,nSize)
	ok
	return joinList(aOut,"")

# the name of the first identifier on the right sides of a run that a member of the object could be taken for, or ""
func conflicts aRun

	for aStatement in aRun
		cRest = aStatement[3]
		nSize = len(cRest)
		nMember = 1
		while nMember <= nSize and (isWordCh(cRest[nMember]) or cRest[nMember] = ".")
			nMember++
		end
		aIdents = identifiers(tail(cRest,nMember))
		for cIdent in aIdents
			if find(aKeep,cIdent) > 0
				loop
			ok
			if isKnownName(cIdent)
				return cIdent
			ok
		next
	next
	return ""

# [the new text, the number of blocks]
func transform cText,cName,aReport

	cEol = nl
	if substr(cText,char(13) + nl) > 0
		cEol = char(13) + nl
	ok
	aLines = splitByEol(cText,cEol)
	aOut = []
	nLines = len(aLines)
	i = 1
	nChanged = 0
	while i <= nLines
		aMatch = matchStatement(aLines[i])
		if len(aMatch) = 0
			aOut + aLines[i]
			i++
			loop
		ok
		cIndent = aMatch[1]
		cVar = aMatch[2]
		j = i
		aRun = []
		aRunLines = []
		while j <= nLines
			aMatchJ = matchStatement(aLines[j])
			if len(aMatchJ) = 0 or aMatchJ[1] != cIndent or aMatchJ[2] != cVar
				exit
			ok
			aRun + aMatchJ
			aRunLines + aLines[j]
			j++
		end
		if len(aRun) < 2
			for cRunLine in aRunLines
				aOut + cRunLine
			next
			i = j
			loop
		ok
		cBad = conflicts(aRun)
		if cBad != ""
			aReport + (cName + ":" + i + " skipped (" + cVar + " uses '" + cBad + "')")
			for cRunLine in aRunLines
				aOut + cRunLine
			next
			i = j
			loop
		ok
		aBody = []
		for aStatement in aRun
			aBody + (cIndent + char(9) + pyStrip(aStatement[3]) + aStatement[4])
		next
		cPrev = ""
		nOut = len(aOut)
		if nOut > 0
			cPrev = aOut[nOut]
		ok
		aPrev = matchNew(cPrev)
		if len(aPrev) > 0 and aPrev[1] = cIndent and aPrev[2] = cVar
			aOut[nOut] = pyRStrip(cPrev) + " {"
		else
			aOut + (cIndent + cVar + " {")
		ok
		for cBodyLine in aBody
			aOut + cBodyLine
		next
		aOut + (cIndent + "}")
		nChanged++
		i = j
	end
	return [joinList(aOut,cEol),nChanged]

func isUpperCh c

	n = ascii(c)
	return n >= 65 and n <= 90
