# Writes True / False instead of 1 / 0 where the value is logical:
# properties known to be boolean (oForm.MaximizeBox = 0, oBox.Checked = 1 ...) and the expected value of a dnAssert that checks a condition.
#
#     ring booleans.ring [--dry] file ...
#
# Plain Ring (the old Python tool, with its regular expressions written as scans of the line).

load "doclib.ring"

aBoolProps = str2list(substr("MaximizeBox MinimizeBox ControlBox ShowInTaskbar TopMost Topmost KeyPreview Checked ReadOnly Enabled Visible Handled SuppressKeyPress GridLines FullRowSelect UseShellExecute RedirectStandardOutput RedirectStandardError RedirectStandardInput CreateNoWindow Multiline WordWrap AcceptsReturn AcceptsTab UseSystemPasswordChar CheckOnClick AllowUserToAddRows AllowUserToDeleteRows Selected Cancel AutoSize TabStop AllowDrop MultiSelect ShowCheckBoxes HideSelection DoubleBuffered Focusable IsEnabled IsChecked IsReadOnly AcceptsReturn UseVisualStyleBackColor ShowUpDown CheckBoxes LabelEdit Sorted AutoGenerateColumns RowHeadersVisible ColumnHeadersVisible ShowToolTips ShowFocusCues Capture"," ",nl))

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
	nChanged = 0
	nLinesChanged = 0
	for cFile in aFiles
		cText = read(cFile)
		cEol = nl
		if substr(cText,char(13) + nl) > 0
			cEol = char(13) + nl
		ok
		aLines = splitByEol(cText,cEol)
		aOut = []
		nHere = 0
		nLines = len(aLines)
		for nLine = 1 to nLines
			cLine = aLines[nLine]
			cNew = fixLine(cLine)
			if cNew != cLine
				nHere++
			ok
			aOut + cNew
		next
		if nHere > 0
			nChanged++
			nLinesChanged += nHere
			if not lDry
				write(cFile,joinList(aOut,cEol))
			ok
		ok
	next
	cNote = ""
	if lDry
		cNote = " (dry run)"
	ok
	? "" + nLinesChanged + " lines in " + nChanged + " files" + cNote

func fixLine cLine

	cNew = fixProperties(cLine)
	aAssert = matchAssert(cNew)
	if len(aAssert) > 0
		cActual = pyStrip(aAssert[3])
		if isLogical(cActual)
			cValue = "False"
			if aAssert[4] = "1"
				cValue = "True"
			ok
			cNew = aAssert[1] + "dnAssert(" + aAssert[2] + "," + aAssert[3] + "," + cValue + ")" + aAssert[5]
		ok
	ok
	return cNew

# (\.(?:props)\s*(?:\+=|-=|=)\s*)([01])(?![\w.])  ->  the 1 or 0 written as True or False
func fixProperties cLine

	if substr(cLine,".") = 0
		return cLine
	ok
	aOut = []
	nSize = len(cLine)
	nPos = 1
	i = 1
	while i <= nSize
		if cLine[i] != "."
			i++
			loop
		ok
		j = i + 1
		while j <= nSize and isWordCh(cLine[j])
			j++
		end
		cName = part(cLine,i + 1,j - 1)
		if cName = "" or find(aBoolProps,cName) = 0
			i++
			loop
		ok
		k = j
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
			i++
			loop
		ok
		k += nOperator
		while k <= nSize and isSpaceCh(cLine[k])
			k++
		end
		if k > nSize or (cLine[k] != "0" and cLine[k] != "1")
			i++
			loop
		ok
		if k < nSize and (isWordCh(cLine[k + 1]) or cLine[k + 1] = ".")
			i++
			loop
		ok
		aOut + part(cLine,nPos,k - 1)
		if cLine[k] = "1"
			aOut + "True"
		else
			aOut + "False"
		ok
		nPos = k + 1
		i = k + 1
	end
	if nPos = 1
		return cLine
	ok
	if nPos <= nSize
		aOut + part(cLine,nPos,nSize)
	ok
	return joinList(aOut,"")

# ^(\s*)dnAssert\((".*?"),(.*),([01])\)(\s*(?:#.*)?)$  ->  [indent, "name", expression, 0 or 1, the end of the line] or []
func matchAssert cLine

	nSize = len(cLine)
	i = 1
	while i <= nSize and isSpaceCh(cLine[i])
		i++
	end
	cIndent = part(cLine,1,i - 1)
	if part(cLine,i,i + 8) != "dnAssert("
		return []
	ok
	nQuote = i + 9
	if nQuote > nSize or cLine[nQuote] != '"'
		return []
	ok
	# the last ,0) or ,1) whose end of the line is white space or a comment
	nLast = 0
	for p = nSize - 2 to nQuote + 2 step -1
		if cLine[p] = "," and (cLine[p + 1] = "0" or cLine[p + 1] = "1") and cLine[p + 2] = ")"
			if validEnd(cLine,p + 3)
				nLast = p
				exit
			ok
		ok
	next
	if nLast = 0
		return []
	ok
	# the first closing quote (after the opening one) that has a comma after it and room for the expression
	nClose = 0
	for q = nQuote + 1 to nLast - 2
		if cLine[q] = '"' and cLine[q + 1] = ","
			nClose = q
			exit
		ok
	next
	if nClose = 0
		return []
	ok
	return [cIndent,part(cLine,nQuote,nClose),part(cLine,nClose + 2,nLast - 1),cLine[nLast + 1],tail(cLine,nLast + 3)]

# (\s*(?:#.*)?)$ from the position: white space, or white space and a comment
func validEnd cLine,nFrom

	nSize = len(cLine)
	k = nFrom
	while k <= nSize and isSpaceCh(cLine[k])
		k++
	end
	return k > nSize or cLine[k] = "#"

# the expression of a dnAssert that is a condition (a comparison, a property that is boolean, a function that answers a boolean)
func isLogical cText

	nSize = len(cText)
	# \.(?:props)$
	for cProp in aBoolProps
		if hasSuffix(cText,"." + cProp)
			return true
		ok
	next
	for i = 1 to nSize
		c = cText[i]
		if c = "<" or c = ">"
			return true
		ok
		if isSpaceCh(c) and i + 2 <= nSize and cText[i + 1] = "=" and isSpaceCh(cText[i + 2])
			return true
		ok
	next
	for aWord in [["Exists(",true,false],["IsCompleted",true,true],["Contains(",true,false],["StartsWith(",true,false],["EndsWith(",true,false],["IsMatch(",true,false],["TryParse",true,false]]
		nAt = 1
		while true
			nFound = findFrom(cText,aWord[1],nAt)
			if nFound = 0
				exit
			ok
			lBefore = nFound = 1 or not isWordCh(cText[nFound - 1])
			nEnd = nFound + len(aWord[1])
			lAfter = nEnd > nSize or not isWordCh(cText[nEnd])
			if lBefore and (lAfter or not aWord[3])
				return true
			ok
			nAt = nFound + 1
		end
	next
	# ^\(?is[a-z]+\(
	i = 1
	if left(cText,1) = "("
		i = 2
	ok
	if part(cText,i,i + 1) = "is"
		j = i + 2
		while j <= nSize and ascii(cText[j]) >= 97 and ascii(cText[j]) <= 122
			j++
		end
		if j > i + 2 and j <= nSize and cText[j] = "("
			return true
		ok
	ok
	return false
