# Helpers of the documentation tools (build.ring, apipages.ring, makepdf.ring): text files, HTML escaping, strings, JSON text.
# Plain Ring (no RingDotNet), so that the documentation can be built before the package works.

C_UNICODE_ELLIPSIS = char(226) + char(128) + char(166)

# ---------------------------------------------------------------- files
# The text of a file with the line ends of Windows turned into one line feed (like the text mode of a file in other languages)
func readText cPath

	cText = read(cPath)
	if substr(cText,char(13)) > 0
		cText = substr(cText,char(13) + char(10),char(10))
		cText = substr(cText,char(13),char(10))
	ok
	return cText

# Writes a text file; on Windows each line feed becomes CR LF
func writeText cPath,cText

	if isWindows()
		cText = substr(cText,char(10),char(13) + char(10))
	ok
	write(cPath,cText)

# the folder of the program that runs (without a closing slash)
func programFolder

	cProgram = substr(sysargv[2],"\","/")
	nSlash = 0
	nMax = len(cProgram)
	for nChar = 1 to nMax
		if cProgram[nChar] = "/"
			nSlash = nChar
		ok
	next
	if nSlash = 0
		return substr(currentdir(),"\","/")
	ok
	cFolder = left(cProgram,nSlash - 1)
	if not (left(cFolder,1) = "/" or substr(cFolder,":") > 0)
		cFolder = substr(currentdir(),"\","/") + "/" + cFolder
	ok
	return cFolder

# the folder that holds a path (without a closing slash)
func parentFolder cPath

	nSlash = 0
	nMax = len(cPath)
	for nChar = 1 to nMax
		if cPath[nChar] = "/"
			nSlash = nChar
		ok
	next
	return left(cPath,nSlash - 1)

# makes a folder (and the folders above it) when it is not there
func makeFolder cPath

	if direxists(cPath)
		return
	ok
	if isWindows()
		system("mkdir " + substr(cPath,"/","\"))
	else
		system("mkdir -p '" + cPath + "'")
	ok

# the names in a folder (files and folders), sorted by the bytes of the names
func listNames cFolder

	aNames = []
	aItems = dir(cFolder)
	nMax = len(aItems)
	for nItem = 1 to nMax
		aNames + aItems[nItem][1]
	next
	return sort(aNames)

func isFolder cPath

	return direxists(cPath)

# ---------------------------------------------------------------- strings
func esc cText

	cText = "" + cText
	if substr(cText,"&") > 0
		cText = substr(cText,"&","&amp;")
	ok
	if substr(cText,"<") > 0
		cText = substr(cText,"<","&lt;")
	ok
	if substr(cText,">") > 0
		cText = substr(cText,">","&gt;")
	ok
	return cText

# html.escape with quote=True: also the quotes
func escQ cText

	cText = esc(cText)
	cText = substr(cText,'"',"&quot;")
	cText = substr(cText,"'","&#x27;")
	return cText

func hasPrefix cText,cPrefix

	return left(cText,len(cPrefix)) = cPrefix

func hasSuffix cText,cSuffix

	nSuffix = len(cSuffix)
	if nSuffix > len(cText)
		return false
	ok
	return right(cText,nSuffix) = cSuffix

func isSpaceCh c

	if c = " "
		return true
	ok
	n = ascii(c)
	return (n >= 9 and n <= 13) or (n >= 28 and n <= 31)

func isDigitCh c

	n = ascii(c)
	return n >= 48 and n <= 57

func isLetterCh c

	n = ascii(c)
	return (n >= 65 and n <= 90) or (n >= 97 and n <= 122)

# \w of a regular expression (ASCII)
func isWordCh c

	n = ascii(c)
	return (n >= 48 and n <= 57) or (n >= 65 and n <= 90) or (n >= 97 and n <= 122) or n = 95

# strip() of a text: the white space at both ends (the no-break space too)
func pyStrip cText

	return pyRStrip(pyLStrip(cText))

func pyLStrip cText

	nSize = len(cText)
	nStart = 1
	while nStart <= nSize
		c = cText[nStart]
		if isSpaceCh(c)
			nStart++
		but ascii(c) = 194 and nStart < nSize and ascii(cText[nStart + 1]) = 160
			nStart += 2
		else
			exit
		ok
	end
	if nStart = 1
		return cText
	ok
	if nStart > nSize
		return ""
	ok
	return substr(cText,nStart)

func pyRStrip cText

	nEnd = len(cText)
	while nEnd >= 1
		c = cText[nEnd]
		if isSpaceCh(c)
			nEnd--
		but ascii(c) = 160 and nEnd > 1 and ascii(cText[nEnd - 1]) = 194
			nEnd -= 2
		else
			exit
		ok
	end
	if nEnd = len(cText)
		return cText
	ok
	if nEnd < 1
		return ""
	ok
	return left(cText,nEnd)

func stripChar cText,cChar

	return rstripChar(lstripChar(cText,cChar),cChar)

func lstripChar cText,cChar

	nSize = len(cText)
	nStart = 1
	while nStart <= nSize and cText[nStart] = cChar
		nStart++
	end
	if nStart = 1
		return cText
	ok
	if nStart > nSize
		return ""
	ok
	return substr(cText,nStart)

func rstripChar cText,cChar

	nEnd = len(cText)
	while nEnd >= 1 and cText[nEnd] = cChar
		nEnd--
	end
	if nEnd = len(cText)
		return cText
	ok
	if nEnd < 1
		return ""
	ok
	return left(cText,nEnd)

# the text without the characters of cChars at the end (rstrip with a set of characters)
func rstripSet cText,cChars

	nEnd = len(cText)
	while nEnd >= 1 and substr(cChars,cText[nEnd]) > 0
		nEnd--
	end
	if nEnd = len(cText)
		return cText
	ok
	if nEnd < 1
		return ""
	ok
	return left(cText,nEnd)

# the lines of a text, like text.split("\n") (a text that ends with a line feed ends with an empty line)
func splitLines cText

	aLines = str2list(cText)
	if hasSuffix(cText,nl) or cText = ""
		aLines + ""
	ok
	return aLines

# the lines of a text that ends its lines with cEol (a line feed or CR LF), like text.split(eol)
func splitByEol cText,cEol

	if cEol = nl
		return splitLines(cText)
	ok
	cText = substr(cText,nl,char(2))
	cText = substr(cText,char(13) + char(2),nl)
	aLines = str2list(cText)
	if hasSuffix(cText,nl) or cText = ""
		aLines + ""
	ok
	nMax = len(aLines)
	for nLine = 1 to nMax
		if substr(aLines[nLine],char(2)) > 0
			aLines[nLine] = substr(aLines[nLine],char(2),nl)
		ok
	next
	return aLines

# The pieces of a big text between the occurrences of a separator (text.split(sep)). The text is not copied for each piece.
func splitOn cText,cSep

	if cText = ""
		return [""]
	ok
	cText = substr(cText,nl,char(2))
	cText = substr(cText,cSep,nl)
	aPieces = str2list(cText)
	if hasSuffix(cText,nl)
		aPieces + ""
	ok
	nMax = len(aPieces)
	for nPiece = 1 to nMax
		if substr(aPieces[nPiece],char(2)) > 0
			aPieces[nPiece] = substr(aPieces[nPiece],char(2),nl)
		ok
	next
	return aPieces

func joinList aList,cSep

	cOut = ""
	nMax = len(aList)
	for nItem = 1 to nMax
		if nItem > 1
			cOut += cSep
		ok
		cOut += aList[nItem]
	next
	return cOut

# the position of cSub in cText from nStart (0 when there is none)
func findFrom cText,cSub,nStart

	if nStart > len(cText)
		return 0
	ok
	if nStart <= 1
		return substr(cText,cSub)
	ok
	nPos = substr(substr(cText,nStart),cSub)
	if nPos = 0
		return 0
	ok
	return nPos + nStart - 1

# the text from nFrom to nTo (both included)
func part cText,nFrom,nTo

	if nTo < nFrom or nFrom > len(cText)
		return ""
	ok
	return substr(cText,nFrom,nTo - nFrom + 1)

# the text from nStart to the end ("" when nStart is after the end)
func tail cText,nStart

	if nStart > len(cText)
		return ""
	ok
	if nStart < 1
		return cText
	ok
	return substr(cText,nStart)

# 12345 -> "12,345"
func thousands n

	cNum = "" + floor(n)
	cOut = ""
	nSize = len(cNum)
	for nChar = 1 to nSize
		if nChar > 1 and (nSize - nChar + 1) % 3 = 0
			cOut += ","
		ok
		cOut += cNum[nChar]
	next
	return cOut

# the first nChars characters of an UTF-8 text
func utf8Left cText,nChars

	nSize = len(cText)
	nCount = 0
	for nByte = 1 to nSize
		n = ascii(cText[nByte])
		if n < 128 or n >= 192
			nCount++
			if nCount > nChars
				return left(cText,nByte - 1)
			ok
		ok
	next
	return cText

# ---------------------------------------------------------------- HTML entities
# html.unescape: the references that the pages have
func htmlUnescape cText

	if substr(cText,"&") = 0
		return cText
	ok
	aPieces = splitOn(cText,"&")
	cOut = aPieces[1]
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cPiece = aPieces[nPiece]
		nSemi = substr(cPiece,";")
		cRep = ""
		cName = ""
		if nSemi > 1 and nSemi <= 12
			cName = left(cPiece,nSemi - 1)
			cRep = entityText(cName)
		ok
		if cRep != ""
			cOut += cRep + tail(cPiece,nSemi + 1)
		else
			cOut += "&" + cPiece
		ok
	next
	return cOut

func entityText cName

	switch cName
	on "amp"
		return "&"
	on "lt"
		return "<"
	on "gt"
		return ">"
	on "quot"
		return '"'
	on "apos"
		return "'"
	on "nbsp"
		return char(194) + char(160)
	on "rarr"
		return char(226) + char(134) + char(146)
	on "larr"
		return char(226) + char(134) + char(144)
	on "hellip"
		return char(226) + char(128) + char(166)
	on "mdash"
		return char(226) + char(128) + char(148)
	on "ndash"
		return char(226) + char(128) + char(147)
	on "middot"
		return char(194) + char(183)
	on "copy"
		return char(194) + char(169)
	on "times"
		return char(195) + char(151)
	off
	if left(cName,1) = "#" and len(cName) > 1
		if lower(substr(cName,2,1)) = "x"
			cDigits = substr(cName,3)
			nCode = hexValue(cDigits)
		else
			cDigits = substr(cName,2)
			nCode = digitsValue(cDigits)
		ok
		if nCode >= 0
			return utf8Char(nCode)
		ok
	ok
	return ""

func digitsValue cDigits

	nSize = len(cDigits)
	if nSize = 0
		return -1
	ok
	nValue = 0
	for nChar = 1 to nSize
		if not isDigitCh(cDigits[nChar])
			return -1
		ok
		nValue = nValue * 10 + (ascii(cDigits[nChar]) - 48)
	next
	return nValue

func hexValue cDigits

	nSize = len(cDigits)
	if nSize = 0
		return -1
	ok
	nValue = 0
	for nChar = 1 to nSize
		n = ascii(lower(cDigits[nChar]))
		if n >= 48 and n <= 57
			nValue = nValue * 16 + (n - 48)
		but n >= 97 and n <= 102
			nValue = nValue * 16 + (n - 87)
		else
			return -1
		ok
	next
	return nValue

# the UTF-8 bytes of a code point
func utf8Char nCode

	if nCode < 128
		return char(nCode)
	but nCode < 2048
		return char(192 + floor(nCode / 64)) + char(128 + nCode % 64)
	but nCode < 65536
		return char(224 + floor(nCode / 4096)) + char(128 + floor(nCode / 64) % 64) + char(128 + nCode % 64)
	ok
	return char(240 + floor(nCode / 262144)) + char(128 + floor(nCode / 4096) % 64) + char(128 + floor(nCode / 64) % 64) + char(128 + nCode % 64)

# ---------------------------------------------------------------- JSON text
# a text as a JSON string (json.dumps: every character that is not ASCII is written as \uXXXX)
func jsonString cText

	cOut = '"'
	nSize = len(cText)
	nByte = 1
	while nByte <= nSize
		n = ascii(cText[nByte])
		if n < 128
			switch n
			on 34
				cOut += '\"'
			on 92
				cOut += "\\"
			on 10
				cOut += "\n"
			on 13
				cOut += "\r"
			on 9
				cOut += "\t"
			on 8
				cOut += "\b"
			on 12
				cOut += "\f"
			other
				if n < 32
					cOut += "\u" + hex4(n)
				else
					cOut += cText[nByte]
				ok
			off
			nByte++
		else
			nCode = n
			nMore = 0
			if n >= 240
				nCode = n % 8
				nMore = 3
			but n >= 224
				nCode = n % 16
				nMore = 2
			but n >= 192
				nCode = n % 32
				nMore = 1
			ok
			for nNext = 1 to nMore
				if nByte + nNext <= nSize
					nCode = nCode * 64 + (ascii(cText[nByte + nNext]) % 64)
				ok
			next
			nByte += nMore + 1
			if nCode >= 65536
				nCode -= 65536
				cOut += "\u" + hex4(55296 + floor(nCode / 1024)) + "\u" + hex4(56320 + nCode % 1024)
			else
				cOut += "\u" + hex4(nCode)
			ok
		ok
	end
	return cOut + '"'

func hex4 n

	cDigits = "0123456789abcdef"
	return cDigits[floor(n / 4096) % 16 + 1] + cDigits[floor(n / 256) % 16 + 1] + cDigits[floor(n / 16) % 16 + 1] + cDigits[n % 16 + 1]

# the text of a JSON string without its quotes (the escapes are decoded)
func jsonUnescape cRaw

	if substr(cRaw,"\") = 0
		return cRaw
	ok
	cOut = ""
	nSize = len(cRaw)
	nChar = 1
	while nChar <= nSize
		c = cRaw[nChar]
		if c != "\" or nChar = nSize
			cOut += c
			nChar++
			loop
		ok
		cNext = cRaw[nChar + 1]
		switch cNext
		on "n"
			cOut += nl
			nChar += 2
		on "r"
			cOut += char(13)
			nChar += 2
		on "t"
			cOut += char(9)
			nChar += 2
		on "b"
			cOut += char(8)
			nChar += 2
		on "f"
			cOut += char(12)
			nChar += 2
		on "u"
			nCode = hexValue(substr(cRaw,nChar + 2,4))
			nChar += 6
			if nCode >= 55296 and nCode < 56320 and substr(cRaw,nChar,2) = "\u"
				nLow = hexValue(substr(cRaw,nChar + 2,4))
				nCode = 65536 + (nCode - 55296) * 1024 + (nLow - 56320)
				nChar += 6
			ok
			cOut += utf8Char(nCode)
		other
			cOut += cNext
			nChar += 2
		off
	end
	return cOut

# ---------------------------------------------------------------- base64
func base64Encode cBytes

	cAlphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	aOut = []
	nSize = len(cBytes)
	nByte = 1
	while nByte <= nSize
		n1 = ascii(cBytes[nByte])
		n2 = 0
		n3 = 0
		nHave = 1
		if nByte + 1 <= nSize
			n2 = ascii(cBytes[nByte + 1])
			nHave = 2
		ok
		if nByte + 2 <= nSize
			n3 = ascii(cBytes[nByte + 2])
			nHave = 3
		ok
		nAll = n1 * 65536 + n2 * 256 + n3
		cGroup = cAlphabet[floor(nAll / 262144) % 64 + 1] + cAlphabet[floor(nAll / 4096) % 64 + 1]
		if nHave >= 2
			cGroup += cAlphabet[floor(nAll / 64) % 64 + 1]
		else
			cGroup += "="
		ok
		if nHave = 3
			cGroup += cAlphabet[nAll % 64 + 1]
		else
			cGroup += "="
		ok
		aOut + cGroup
		nByte += 3
	end
	return joinList(aOut,"")

# ---------------------------------------------------------------- templates
# A template with %(name)s places (the format of a dictionary): aValues is a list of [name, text]
func fillTemplate cTemplate,aValues

	aPieces = splitOn(cTemplate,"%(")
	aOut = [aPieces[1]]
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cPiece = aPieces[nPiece]
		nClose = substr(cPiece,")s")
		cName = left(cPiece,nClose - 1)
		cValue = ""
		for aValue in aValues
			if aValue[1] = cName
				cValue = aValue[2]
				exit
			ok
		next
		aOut + cValue
		aOut + tail(cPiece,nClose + 2)
	next
	return joinList(aOut,"")

# ---------------------------------------------------------------- running programs
func tempFolder

	cFolder = sysget("TEMP")
	if cFolder = ""
		cFolder = sysget("TMPDIR")
	ok
	if cFolder = ""
		cFolder = "/tmp"
	ok
	return substr(cFolder,"\","/")

# The output of a command (the output and the errors), run in a folder; RING_HOME is not set and the bin folder of the package is first in PATH
func runCommand cFolder,cCommand,cBinFolder

	cOutput = tempFolder() + "/ringdotnet_docs_output.txt"
	if fexists(cOutput)
		remove(cOutput)
	ok
	if isWindows()
		cLine = 'cd /d "' + substr(cFolder,"/","\") + '" && set RING_HOME=&& set "PATH=' + substr(cBinFolder,"/","\") + ';%PATH%" && ' + cCommand + ' > "' + substr(cOutput,"/","\") + '" 2>&1'
		system('cmd /c "' + cLine + '"')
	else
		cLine = "cd '" + cFolder + "' && env -u RING_HOME PATH='" + cBinFolder + ":'\"$PATH\" " + cCommand + " > '" + cOutput + "' 2>&1"
		system(cLine)
	ok
	cText = ""
	if fexists(cOutput)
		cText = readText(cOutput)
		remove(cOutput)
	ok
	return cText
