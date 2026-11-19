# international domain names - Punycode with IdnMapping, Uri.IdnHost, invalid names, and look-alike letters (homograph attacks)
load "dotnet.ring"
using {
	"System"
	"System.Globalization"
	"System.Text"
}

func main
	oIdn = new IdnMapping()

	# The system of domain names (DNS) knows only the letters a-z, the digits and the hyphen. A name with other letters is sent as
	# PUNYCODE: the text "xn--" followed by an encoding of the letters in ASCII. IdnMapping converts both ways.
	cGerman = "b" + char(195) + char(188) + "cher.example"                                 # bücher.example
	cArabic = char(217) + char(133) + char(217) + char(136) + char(217) + char(130) + char(216) + char(185) + ".example"          # موقع.example
	? "1. German:  " + cGerman + "  ->  " + oIdn.GetAscii(cGerman)
	? "   Arabic:  the name with the word for 'site' ->  " + oIdn.GetAscii(cArabic)
	? "   back:    " + oIdn.GetUnicode(oIdn.GetAscii(cGerman)) + "  and the round trip is exact: " + (oIdn.GetUnicode(oIdn.GetAscii(cGerman)) = cGerman)
	? "   a name that is plain ASCII does not change: " + oIdn.GetAscii("www.example.com")

	# 2. The Uri class keeps both forms: Host is the name as it was written and IdnHost the ASCII form that goes to the network
	oUri = new Uri("https://" + cGerman + "/path")
	? nl + "2. Host: " + oUri.Host + "   IdnHost (for DNS and certificates): " + oUri.IdnHost
	? "   an HTTP client sends the IdnHost; a certificate for this site names it in the Punycode form"

	# 3. Names that are not valid: a part (label) is at most 63 characters, it must not be empty, and it must not start or end with a
	#    hyphen. GetAscii raises an error for them.
	oStrict = new IdnMapping()
	oStrict.UseStd3AsciiRules = True                       # only letters, digits and hyphens are allowed in a name (a space is refused)
	? nl + "3. checking names (the second answer is with UseStd3AsciiRules):"
	for cName in ["good-name.example","-bad.example","empty..label.example",copy("a",64) + ".example","has space.example"]
		? "   " + padRight(shortText(cName),24) + padRight(checkName(oIdn,cName),32) + checkName(oStrict,cName)
	next

	# 4. Look-alike letters. The Cyrillic letter U+0430 looks the same as the Latin letter a, so "apple.com" can be written with it:
	#    a different name that a person cannot tell apart. This is called a HOMOGRAPH attack. Punycode shows the difference at once.
	cLatin = "apple.com"
	cLookAlike = char(208) + char(176) + "pple.com"                                       # the first letter is Cyrillic
	? nl + "4. apple.com in two spellings:"
	? "   Latin:      " + cLatin + "   " + oIdn.GetAscii(cLatin)
	? "   look-alike: " + cLookAlike + "   " + oIdn.GetAscii(cLookAlike)
	? "   they look the same on the screen but they are different names: " + (cLatin != cLookAlike)

	# 5. A defence: look at the SCRIPTS (alphabets) of the letters in each part. A normal name uses one script; a name that mixes
	#    Latin and Cyrillic letters is suspicious. Browsers show such names in Punycode instead of the letters.
	? nl + "5. the alphabets in each part of the name (the parts are separated by dots):"
	for cName in [cLatin,cLookAlike,cGerman,cArabic,"dom" + char(208) + char(176) + "in.com"]
		? "   " + padRight(oIdn.GetAscii(cName),26) + padRight(scriptsOf(cName),18) + decision(cName)
	next

	# 6. Safe display: show the Unicode form only when it is safe, otherwise the Punycode form
	? nl + "6. what to show to a person: " + displayName(oIdn,cArabic) + ", " + displayName(oIdn,cLookAlike)

# the checks of GetAscii: an error means that the name is not valid
func checkName oIdn,cName
	try
		return "valid: " + oIdn.GetAscii(cName)
	catch
		return "not valid"
	done

# the code of every letter of a text (Unicode code points): UTF-32 has four bytes for each letter
func codePoints cText
	aCodes = []
	cBytes = new UTF32Encoding().GetBytes(cText)
	for nPos = 1 to len(cBytes) step 4
		aCodes + (ascii(cBytes[nPos]) + ascii(cBytes[nPos + 1]) * 256 + ascii(cBytes[nPos + 2]) * 65536)
	next
	return aCodes

# the alphabet of a letter, from the range of its code (only a few alphabets, to show the idea)
func scriptOf nCode
	cScript = "other"
	if nCode >= 65 and nCode <= 122 and not (nCode > 90 and nCode < 97)
		cScript = "Latin"
	but nCode >= 192 and nCode <= 591
		cScript = "Latin"
	but nCode >= 880 and nCode <= 1023
		cScript = "Greek"
	but nCode >= 1024 and nCode <= 1327
		cScript = "Cyrillic"
	but nCode >= 1536 and nCode <= 1791
		cScript = "Arabic"
	ok
	return cScript

# the alphabets used in the letters of ONE part of a name (digits and hyphens are not letters of an alphabet)
func scriptList cLabel
	aScripts = []
	for nCode in codePoints(cLabel)
		cScript = scriptOf(nCode)
		if cScript != "other" and find(aScripts,cScript) = 0
			aScripts + cScript
		ok
	next
	return aScripts

# the labels of a name are separated by dots; each label is checked alone (an Arabic name under the Latin ".example" is normal)
func labels cName
	return str2list(substr(cName,".",nl))

func scriptsOf cName
	cText = ""
	for cLabel in labels(cName)
		cText += joinWith(scriptList(cLabel),"+") + " "
	next
	return cText

func isMixed cName
	for cLabel in labels(cName)
		if len(scriptList(cLabel)) > 1
			return True
		ok
	next
	return False

func decision cName
	if isMixed(cName)
		return "MIXED in one part: suspicious"
	ok
	return "one alphabet in each part"

func displayName oIdn,cName
	if isMixed(cName)
		return oIdn.GetAscii(cName) + " (Punycode: mixed alphabets)"
	ok
	return cName + " (shown as written)"

func shortText cText
	if len(cText) > 22
		return left(cText,20) + "..."
	ok
	return cText

func padRight cText,nWidth
	return cText + copy(" ",nWidth - len(cText))

func joinWith aList,cSeparator
	cText = ""
	for item in aList
		if cText != ""
			cText += cSeparator
		ok
		cText += "" + item
	next
	return cText
