# The Markdown of the manual and the highlighting of code blocks (used by build.ring). Plain Ring: every pattern is a scan of the text.

aRingKeywords = str2list(substr("func function class from if but else elseif ok for in to step next while end return new load try catch done switch on off other exit loop import package private see give put get call and or not true false null self this this bye again break continue"," ",nl))
aCsKeywords = str2list(substr("using namespace class public private protected internal static void return new if else for foreach while var string int long double bool object null true false override sealed abstract interface struct enum try catch finally throw await async get set in out ref params readonly"," ",nl))
aPlainLanguages = ["text","output","bash","sh","console","xml","json","html","xaml","ini","cmd",""]
aMarkupLanguages = ["json","xml","html","xaml"]

# ---------------------------------------------------------------- highlighting
func highlight cCode,cLang

	if find(aPlainLanguages,cLang) > 0
		if find(aMarkupLanguages,cLang) > 0
			return highlightMarkup(cCode)
		ok
		return esc(cCode)
	ok
	lCs = find(["csharp","cs","c#"],cLang) > 0
	aOut = []
	nPos = 1
	nSize = len(cCode)
	cPrev = ""
	i = 1
	while i <= nSize
		c = cCode[i]
		nEnd = 0
		cKind = ""
		if c = "#"
			nEnd = lineEnd(cCode,i,nSize)
			cKind = "c"
		but c = "/" and i < nSize and cCode[i + 1] = "/"
			nEnd = lineEnd(cCode,i,nSize)
			cKind = "c"
		but c = "/" and i < nSize and cCode[i + 1] = "*"
			nClose = findFrom(cCode,"*/",i + 2)
			if nClose > 0
				nEnd = nClose + 1
				cKind = "c"
			ok
		but c = '"' or c = "'"
			nEnd = stringEnd(cCode,i,c,nSize)
			cKind = "s"
		but c = "`"
			j = i + 1
			while j <= nSize and cCode[j] != "`" and cCode[j] != nl
				j++
			end
			if j <= nSize and cCode[j] = "`"
				nEnd = j
				cKind = "s"
			ok
		but isDigitCh(c)
			nEnd = numberEnd(cCode,i,nSize)
			cKind = "n"
		but isLetterCh(c) or c = "_"
			j = i
			while j < nSize and isWordCh(cCode[j + 1])
				j++
			end
			nEnd = j
			cKind = "w"
		ok
		if nEnd = 0
			i++
			loop
		ok
		if i > nPos
			aOut + esc(part(cCode,nPos,i - 1))
		ok
		cTxt = part(cCode,i,nEnd)
		nPos = nEnd + 1
		i = nEnd + 1
		switch cKind
		on "c"
			if lCs and left(cTxt,1) = "#"
				aOut + esc(cTxt)
			else
				aOut + ('<span class="c">' + esc(cTxt) + "</span>")
			ok
			cPrev = ""
		on "s"
			aOut + ('<span class="s">' + esc(cTxt) + "</span>")
			cPrev = ""
		on "n"
			aOut + ('<span class="n">' + esc(cTxt) + "</span>")
			cPrev = ""
		on "w"
			if lCs
				cLow = cTxt
			else
				cLow = lower(cTxt)
			ok
			nStart = nPos - len(cTxt)
			cBefore = ""
			k = nStart - 1
			while k >= 1 and (cCode[k] = " " or cCode[k] = char(9))
				k--
			end
			if k >= 1
				cBefore = cCode[k]
			ok
			cAfter = ""
			if nPos <= nSize
				cAfter = cCode[nPos]
			ok
			if lCs
				lKeyword = find(aCsKeywords,cLow) > 0
			else
				lKeyword = find(aRingKeywords,cLow) > 0
			ok
			if lKeyword
				aOut + ('<span class="k">' + cTxt + "</span>")
			but isUiName(cTxt) or (cBefore = "." and cAfter = "(") or cPrev = "func" or cPrev = "function"
				aOut + ('<span class="f">' + cTxt + "</span>")
			but cPrev = "new" or (isUpperCh(cTxt[1]) and len(cTxt) > 2 and (cAfter = "(" or cAfter = " ") and cBefore != "." and lCs)
				aOut + ('<span class="t">' + cTxt + "</span>")
			else
				aOut + cTxt
			ok
			cPrev = cLow
		off
	end
	if nPos <= nSize
		aOut + esc(part(cCode,nPos,nSize))
	ok
	return joinList(aOut,"")

# the last character of the line that starts before or at i (the line feed is not part of it)
func lineEnd cCode,i,nSize

	nLine = findFrom(cCode,nl,i)
	if nLine = 0
		return nSize
	ok
	return nLine - 1

# the end of a string literal that starts at i with the quote cQuote, or 0 (the string is not closed in its line)
func stringEnd cCode,i,cQuote,nSize

	j = i + 1
	while j <= nSize
		c = cCode[j]
		if c = cQuote
			return j
		but c = "\"
			if j + 1 > nSize
				return 0
			ok
			j += 2
		but c = nl
			return 0
		else
			j++
		ok
	end
	return 0

# the end of the number that starts at i (digits, and digits after a dot) when a word boundary is on both sides, or 0
func numberEnd cCode,i,nSize

	if i > 1 and isWordCh(cCode[i - 1])
		return 0
	ok
	j = i
	while j < nSize and isDigitCh(cCode[j + 1])
		j++
	end
	nInt = j
	if j + 2 <= nSize and cCode[j + 1] = "." and isDigitCh(cCode[j + 2])
		k = j + 2
		while k < nSize and isDigitCh(cCode[k + 1])
			k++
		end
		if k = nSize or not isWordCh(cCode[k + 1])
			return k
		ok
	ok
	if nInt = nSize or not isWordCh(cCode[nInt + 1])
		return nInt
	ok
	return 0

func isUpperCh c

	n = ascii(c)
	return n >= 65 and n <= 90

# dnXxx, uiXxx, wpfXxx, webXxx, dbXxx: the functions of the library
func isUiName cName

	for cPrefix in ["dn","ui","wpf","web","db"]
		nPrefix = len(cPrefix)
		if len(cName) > nPrefix and left(cName,nPrefix) = cPrefix and isUpperCh(cName[nPrefix + 1])
			return true
		ok
	next
	return false

# the markup languages: three substitutions, one after the other, on the escaped text
func highlightMarkup cCode

	cOut = esc(cCode)
	cOut = markupTags(cOut)
	cOut = markupAttributes(cOut)
	cOut = markupStrings(cOut)
	return cOut

# (&lt;/?)([A-Za-z_][\w:.\-]*)  ->  \1<span class="k">\2</span>
func markupTags cText

	aPieces = splitOn(cText,"&lt;")
	aOut = [aPieces[1]]
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cPiece = aPieces[nPiece]
		nAt = 1
		cSlash = ""
		if left(cPiece,1) = "/"
			cSlash = "/"
			nAt = 2
		ok
		nSize = len(cPiece)
		nEnd = nAt - 1
		if nAt <= nSize and (isLetterCh(cPiece[nAt]) or cPiece[nAt] = "_")
			nEnd = nAt
			while nEnd < nSize and (isWordCh(cPiece[nEnd + 1]) or cPiece[nEnd + 1] = ":" or cPiece[nEnd + 1] = "." or cPiece[nEnd + 1] = "-")
				nEnd++
			end
			aOut + ("&lt;" + cSlash + '<span class="k">' + part(cPiece,nAt,nEnd) + "</span>" + tail(cPiece,nEnd + 1))
		else
			aOut + ("&lt;" + cPiece)
		ok
	next
	return joinList(aOut,"")

# ([\w:\-]+)(=)(&quot;|")  ->  <span class="t">\1</span>\2\3
func markupAttributes cText

	aOut = []
	nSize = len(cText)
	nPos = 1
	i = 1
	while i <= nSize
		c = cText[i]
		if isWordCh(c) or c = ":" or c = "-"
			j = i
			while j < nSize and (isWordCh(cText[j + 1]) or cText[j + 1] = ":" or cText[j + 1] = "-")
				j++
			end
			if j < nSize and cText[j + 1] = "="
				cQuote = ""
				if part(cText,j + 2,j + 7) = "&quot;"
					cQuote = "&quot;"
				but j + 2 <= nSize and cText[j + 2] = '"'
					cQuote = '"'
				ok
				if cQuote != ""
					if i > nPos
						aOut + part(cText,nPos,i - 1)
					ok
					aOut + ('<span class="t">' + part(cText,i,j) + "</span>=" + cQuote)
					nPos = j + 2 + len(cQuote)
					i = nPos
					loop
				ok
			ok
			i = j + 1
		else
			i++
		ok
	end
	if nPos <= nSize
		aOut + part(cText,nPos,nSize)
	ok
	return joinList(aOut,"")

# (&quot;[^&\n]*&quot;|"[^"\n]*")  ->  <span class="s">\1</span>
func markupStrings cText

	aOut = []
	nSize = len(cText)
	nPos = 1
	i = 1
	while i <= nSize
		c = cText[i]
		nEnd = 0
		if c = "&" and part(cText,i,i + 5) = "&quot;"
			j = i + 6
			while j <= nSize and cText[j] != "&" and cText[j] != nl
				j++
			end
			if j <= nSize and part(cText,j,j + 5) = "&quot;"
				nEnd = j + 5
			ok
		but c = '"'
			j = i + 1
			while j <= nSize and cText[j] != '"' and cText[j] != nl
				j++
			end
			if j <= nSize and cText[j] = '"'
				nEnd = j
			ok
		ok
		if nEnd > 0
			if i > nPos
				aOut + part(cText,nPos,i - 1)
			ok
			aOut + ('<span class="s">' + part(cText,i,nEnd) + "</span>")
			nPos = nEnd + 1
			i = nPos
		else
			i++
		ok
	end
	if nPos <= nSize
		aOut + part(cText,nPos,nSize)
	ok
	return joinList(aOut,"")

func codeBlock cCode,cLang,cTitle

	cCode = rstripChar(cCode,nl)
	cLabel = cTitle
	if cLabel = ""
		cLabel = cLang
		switch cLang
		on "ring"
			cLabel = "Ring"
		on "output"
			cLabel = "Output"
		on "text"
			cLabel = ""
		on "bash"
			cLabel = "Shell"
		on "csharp"
			cLabel = "C#"
		on "xml"
			cLabel = "XML"
		on "xaml"
			cLabel = "XAML"
		on "json"
			cLabel = "JSON"
		on "html"
			cLabel = "HTML"
		off
	ok
	cClass = "code"
	if cLang = "output"
		cClass = "code out"
	ok
	return '<div class="' + cClass + '"><div class="bar"><span class="dots"><i></i><i></i><i></i></span><span>' + esc(cLabel) + '</span><button class="copy" type="button">Copy</button></div><pre><code>' + highlight(cCode,cLang) + "</code></pre></div>"

# ---------------------------------------------------------------- inline Markdown
func slug cText

	# the tags go
	cText = removeTags(cText,"")
	cOut = ""
	nSize = len(cText)
	for nChar = 1 to nSize
		c = cText[nChar]
		if isLetterCh(c) or isDigitCh(c) or c = " " or c = "-"
			cOut += c
		ok
	next
	cOut = lower(pyStrip(cOut))
	aOut = []
	lSpace = false
	nSize = len(cOut)
	cResult = ""
	for nChar = 1 to nSize
		c = cOut[nChar]
		if c = " "
			if not lSpace
				cResult += "-"
				lSpace = true
			ok
		else
			cResult += c
			lSpace = false
		ok
	next
	return cResult

# <[^>]+> replaced by cWith
func removeTags cText,cWith

	if substr(cText,"<") = 0
		return cText
	ok
	aOut = []
	nSize = len(cText)
	nPos = 1
	i = 1
	while i <= nSize
		if cText[i] = "<"
			j = i + 1
			while j <= nSize and cText[j] != ">"
				j++
			end
			if j <= nSize and j > i + 1
				if i > nPos
					aOut + part(cText,nPos,i - 1)
				ok
				aOut + cWith
				nPos = j + 1
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

func inlineMd cText

	aCodes = []
	cP = codeSpans(cText,aCodes)
	cP = esc(cP)
	if substr(cP,"**") > 0
		cP = strongSpans(cP)
	ok
	if substr(cP,"*") > 0
		cP = emSpans(cP)
	ok
	if substr(cP,"[") > 0
		cP = linkSpans(cP)
	ok
	if substr(cP,"&amp;nbsp;") > 0
		cP = substr(cP,"&amp;nbsp;","&nbsp;")
	ok
	if len(aCodes) = 0
		return cP
	ok
	aPieces = splitOn(cP,"@@CODE")
	aOut = [aPieces[1]]
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cPiece = aPieces[nPiece]
		nDigits = 0
		nSize = len(cPiece)
		while nDigits < nSize and isDigitCh(cPiece[nDigits + 1])
			nDigits++
		end
		if nDigits > 0 and part(cPiece,nDigits + 1,nDigits + 2) = "@@"
			aOut + aCodes[number(left(cPiece,nDigits)) + 1]
			aOut + tail(cPiece,nDigits + 3)
		else
			aOut + ("@@CODE" + cPiece)
		ok
	next
	return joinList(aOut,"")

# `code`: the code spans are put aside (the places @@CODEn@@)
func codeSpans cText,aCodes

	if substr(cText,"`") = 0
		return cText
	ok
	aOut = []
	nPos = 1
	while true
		nOpen = findFrom(cText,"`",nPos)
		if nOpen = 0
			exit
		ok
		nClose = findFrom(cText,"`",nOpen + 1)
		if nClose = 0
			exit
		ok
		if nClose = nOpen + 1
			aOut + part(cText,nPos,nOpen)
			nPos = nOpen + 1
			loop
		ok
		aOut + part(cText,nPos,nOpen - 1)
		aCodes + ("<code>" + esc(part(cText,nOpen + 1,nClose - 1)) + "</code>")
		aOut + ("@@CODE" + (len(aCodes) - 1) + "@@")
		nPos = nClose + 1
	end
	if nPos <= len(cText)
		aOut + substr(cText,nPos)
	ok
	return joinList(aOut,"")

# \*\*([^*]+)\*\*
func strongSpans cText

	aOut = []
	nSize = len(cText)
	nPos = 1
	i = 1
	while i + 4 <= nSize
		if cText[i] = "*" and cText[i + 1] = "*"
			j = i + 2
			while j <= nSize and cText[j] != "*"
				j++
			end
			if j > i + 2 and j + 1 <= nSize and cText[j + 1] = "*"
				if i > nPos
					aOut + part(cText,nPos,i - 1)
				ok
				aOut + ("<strong>" + part(cText,i + 2,j - 1) + "</strong>")
				nPos = j + 2
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

# (?<![\w*])\*([^*\n]+)\*(?![\w*])
func emSpans cText

	aOut = []
	nSize = len(cText)
	nPos = 1
	i = 1
	while i <= nSize
		if cText[i] = "*" and (i = 1 or not (isWordCh(cText[i - 1]) or cText[i - 1] = "*"))
			j = i + 1
			while j <= nSize and cText[j] != "*" and cText[j] != nl
				j++
			end
			if j > i + 1 and j <= nSize and cText[j] = "*" and (j = nSize or not (isWordCh(cText[j + 1]) or cText[j + 1] = "*"))
				if i > nPos
					aOut + part(cText,nPos,i - 1)
				ok
				aOut + ("<em>" + part(cText,i + 1,j - 1) + "</em>")
				nPos = j + 1
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

# \[([^\]]+)\]\(([^)\s]+)\)  ->  <a href="url">text</a>  (a link to a .md page is a link to the .html page)
func linkSpans cText

	aOut = []
	nSize = len(cText)
	nPos = 1
	i = 1
	while i <= nSize
		if cText[i] = "["
			j = i + 1
			while j <= nSize and cText[j] != "]"
				j++
			end
			if j > i + 1 and j + 1 <= nSize and cText[j + 1] = "("
				k = j + 2
				while k <= nSize and cText[k] != ")" and not isSpaceCh(cText[k])
					k++
				end
				if k > j + 2 and k <= nSize and cText[k] = ")"
					if i > nPos
						aOut + part(cText,nPos,i - 1)
					ok
					aOut + ('<a href="' + pageUrl(part(cText,j + 2,k - 1)) + '">' + part(cText,i + 1,j - 1) + "</a>")
					nPos = k + 1
					i = nPos
					loop
				ok
			ok
		ok
		i++
	end
	if nPos <= nSize
		aOut + part(cText,nPos,nSize)
	ok
	return joinList(aOut,"")

# .md at the end of an address, or before a #, becomes .html
func pageUrl cUrl

	if substr(cUrl,".md") = 0
		return cUrl
	ok
	aOut = []
	nSize = len(cUrl)
	nPos = 1
	while true
		nAt = findFrom(cUrl,".md",nPos)
		if nAt = 0
			exit
		ok
		nAfter = nAt + 3
		if nAfter > nSize or cUrl[nAfter] = "#"
			aOut + part(cUrl,nPos,nAt - 1)
			aOut + ".html"
		else
			aOut + part(cUrl,nPos,nAt + 2)
		ok
		nPos = nAfter
	end
	if nPos <= nSize
		aOut + substr(cUrl,nPos)
	ok
	return joinList(aOut,"")

# ---------------------------------------------------------------- blocks
func tableMd aLines

	aRows = []
	for cLine in aLines
		aRows + tableCells(stripChar(pyStrip(cLine),"|"))
	next
	cHead = ""
	for cCell in aRows[1]
		cHead += "<th>" + inlineMd(cCell) + "</th>"
	next
	cBody = ""
	nMax = len(aRows)
	for nRow = 3 to nMax
		cBody += "<tr>"
		for cCell in aRows[nRow]
			cBody += "<td>" + inlineMd(substr(cCell,"\|","|")) + "</td>"
		next
		cBody += "</tr>"
	next
	return '<div class="tablewrap"><table><thead><tr>' + cHead + "</tr></thead><tbody>" + cBody + "</tbody></table></div>"

# the cells of a row: the text split at the | that has no backslash before it, each cell stripped
func tableCells cRow

	aCells = []
	cCell = ""
	nSize = len(cRow)
	for nChar = 1 to nSize
		c = cRow[nChar]
		if c = "|" and (nChar = 1 or cRow[nChar - 1] != "\")
			aCells + pyStrip(cCell)
			cCell = ""
		else
			cCell += c
		ok
	next
	aCells + pyStrip(cCell)
	return aCells

# the length of a list marker at the start of a line ("  - ", "1. "), or 0; the second item is true for a numbered item
func listMarker cLine

	nSize = len(cLine)
	i = 1
	while i <= nSize and isSpaceCh(cLine[i])
		i++
	end
	if i > nSize
		return [0,false]
	ok
	lOrdered = false
	if cLine[i] = "-" or cLine[i] = "*"
		i++
	but isDigitCh(cLine[i])
		while i <= nSize and isDigitCh(cLine[i])
			i++
		end
		if i > nSize or cLine[i] != "."
			return [0,false]
		ok
		i++
		lOrdered = true
	else
		return [0,false]
	ok
	if i > nSize or not isSpaceCh(cLine[i])
		return [0,false]
	ok
	while i <= nSize and isSpaceCh(cLine[i])
		i++
	end
	return [i - 1,lOrdered]

# the number of # at the start of a line when there are 1 to 4 and a space follows (the heading), else 0
func headingLevel cLine

	n = 0
	nSize = len(cLine)
	while n < nSize and cLine[n + 1] = "#"
		n++
	end
	if n >= 1 and n <= 4 and n < nSize and isSpaceCh(cLine[n + 1])
		return n
	ok
	return 0

# is the line one that ends a paragraph? (```, a heading, |, >, ![, {{, <)
func endsParagraph cLine

	if hasPrefix(cLine,"```") or hasPrefix(cLine,"|") or hasPrefix(cLine,">") or hasPrefix(cLine,"![") or hasPrefix(cLine,"{{") or hasPrefix(cLine,"<")
		return true
	ok
	return headingLevel(cLine) > 0

# ![alt](url "caption") alone in its line: [alt, url, caption] or []
func imageLine cLine

	if left(cLine,2) != "!["
		return []
	ok
	nSize = len(cLine)
	j = 3
	while j <= nSize and cLine[j] != "]"
		j++
	end
	if j > nSize or j + 1 > nSize or cLine[j + 1] != "("
		return []
	ok
	cAlt = part(cLine,3,j - 1)
	k = j + 2
	while k <= nSize and cLine[k] != ")" and not isSpaceCh(cLine[k])
		k++
	end
	if k = j + 2 or k > nSize
		return []
	ok
	cUrl = part(cLine,j + 2,k - 1)
	cCaption = ""
	lCaption = false
	if cLine[k] != ")"
		# white space, then "caption", then )
		m = k
		while m <= nSize and isSpaceCh(cLine[m])
			m++
		end
		if m > nSize or cLine[m] != '"'
			return []
		ok
		nQuote = m + 1
		while nQuote <= nSize and cLine[nQuote] != '"'
			nQuote++
		end
		if nQuote > nSize or nQuote + 1 > nSize or cLine[nQuote + 1] != ")"
			return []
		ok
		cCaption = part(cLine,m + 1,nQuote - 1)
		lCaption = true
		k = nQuote + 1
	ok
	# only white space may follow the )
	for m = k + 1 to nSize
		if not isSpaceCh(cLine[m])
			return []
		ok
	next
	return [cAlt,cUrl,cCaption,lCaption]

# the Markdown of a page as HTML
func markdown cText

	aLines = splitLines(cText)
	aOut = []
	nLines = len(aLines)
	i = 1
	while i <= nLines
		cLine = aLines[i]
		if pyStrip(cLine) = ""
			i++
			loop
		ok
		if hasPrefix(cLine,"```")
			nAt = 4
			nSize = len(cLine)
			while nAt <= nSize and isWordCh(cLine[nAt])
				nAt++
			end
			cLang = part(cLine,4,nAt - 1)
			cTitle = pyStrip(tail(cLine,nAt))
			if cLang = ""
				cLang = "text"
			ok
			i++
			aBuf = []
			while i <= nLines and not hasPrefix(aLines[i],"```")
				aBuf + aLines[i]
				i++
			end
			i++
			aOut + codeBlock(joinList(aBuf,nl),cLang,cTitle)
			loop
		ok
		nLevel = headingLevel(cLine)
		if nLevel > 0
			cTitle = pyStrip(tail(cLine,nLevel + 1))
			if nLevel = 1
				i++
				loop
			ok
			cId = slug(cTitle)
			aOut + ("<h" + nLevel + ' id="' + cId + '">' + inlineMd(cTitle) + '<a class="anchor" href="#' + cId + '">#</a></h' + nLevel + ">")
			i++
			loop
		ok
		if hasPrefix(cLine,"{{") and hasSuffix(pyRStrip(cLine),"}}")
			cCmd = pyStrip(cLine)
			cCmd = pyStrip(part(cCmd,3,len(cCmd) - 2))
			aOut + directiveHtml(cCmd)
			i++
			loop
		ok
		if hasPrefix(cLine,"<")
			aBuf = []
			while i <= nLines and pyStrip(aLines[i]) != ""
				aBuf + aLines[i]
				i++
			end
			aOut + joinList(aBuf,nl)
			loop
		ok
		aImage = imageLine(cLine)
		if len(aImage) > 0
			cCaption = aImage[3]
			if cCaption = ""
				cCaption = aImage[1]
			ok
			aOut + ('<figure class="shot"><img src="' + aImage[2] + '" alt="' + esc(aImage[1]) + '" loading="lazy"><figcaption>' + inlineMd(cCaption) + "</figcaption></figure>")
			i++
			loop
		ok
		if hasPrefix(cLine,"|")
			aBuf = []
			while i <= nLines and hasPrefix(aLines[i],"|")
				aBuf + aLines[i]
				i++
			end
			aOut + tableMd(aBuf)
			loop
		ok
		if hasPrefix(cLine,">")
			aBuf = []
			while i <= nLines and hasPrefix(aLines[i],">")
				aBuf + pyLStrip(tail(aLines[i],2))
				i++
			end
			cKind = "note"
			cLabel = "Note"
			cFirst = aBuf[1]
			if left(cFirst,2) = "[!"
				nWord = 3
				nSize = len(cFirst)
				while nWord <= nSize and isWordCh(cFirst[nWord])
					nWord++
				end
				if nWord > 3 and nWord <= nSize and cFirst[nWord] = "]"
					cName = upper(part(cFirst,3,nWord - 1))
					switch cName
					on "WARNING"
						cKind = "warn"
						cLabel = "Warning"
					on "TIP"
						cKind = "tip"
						cLabel = "Tip"
					other
						cKind = "note"
						cLabel = "Note"
					off
					aBuf[1] = pyLStrip(tail(cFirst,nWord + 1))
				ok
			ok
			cBody = markdown(joinList(aBuf,nl))
			aOut + ('<div class="callout ' + cKind + '"><span class="t">' + cLabel + "</span>" + cBody + "</div>")
			loop
		ok
		aMarker = listMarker(cLine)
		if aMarker[1] > 0
			lOrdered = false
			cNumbered = pyLStrip(cLine)
			if isDigitCh(left(cNumbered,1))
				lOrdered = true
			ok
			aItems = []
			while i <= nLines
				aNow = listMarker(aLines[i])
				if aNow[1] > 0
					aItems + tail(aLines[i],aNow[1] + 1)
				but hasPrefix(aLines[i],"  ") and pyStrip(aLines[i]) != ""
					aItems[len(aItems)] += " " + pyStrip(aLines[i])
				else
					exit
				ok
				i++
			end
			cTag = "ul"
			if lOrdered
				cTag = "ol"
			ok
			cItems = ""
			for cItem in aItems
				cItems += "<li>" + inlineMd(cItem) + "</li>"
			next
			aOut + ("<" + cTag + ">" + cItems + "</" + cTag + ">")
			loop
		ok
		if pyStrip(cLine) = "---"
			aOut + "<hr>"
			i++
			loop
		ok
		aBuf = []
		while i <= nLines and pyStrip(aLines[i]) != "" and not endsParagraph(aLines[i]) and listMarker(aLines[i])[1] = 0
			aBuf + pyStrip(aLines[i])
			i++
		end
		if len(aBuf) = 0
			i++
		ok
		aOut + ("<p>" + inlineMd(joinList(aBuf," ")) + "</p>")
	end
	return joinList(aOut,nl)
