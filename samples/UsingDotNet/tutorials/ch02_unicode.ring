# Unicode and text encodings - characters, code points, bytes, and why len() is not the number of letters
load "dotnet.ring"
using {
	"System"
	"System.Globalization"
	"System.Text"
}

func main
	oUtf8 = new Encoding().UTF8
	oUtf16 = new Encoding().Unicode              # .NET's own text format: UTF-16
	oLatin1 = new Encoding().Latin1

	? "Ring len() | UTF-8 bytes | UTF-16 bytes | letters you see | text"
	aSamples = ["Ring","café","Привет","مرحبا","日本語","😀"]
	for cText in aSamples
		oInfo = textElements(cText)
		? padRight("" + len(cText),11) + " | " + padRight("" + len(oUtf8.GetBytes(cText)),11) + " | " + padRight("" + len(oUtf16.GetBytes(cText)),12) + " | " + padRight("" + oInfo.LengthInTextElements,16) + " | " + cText
	next

	# 1. A Ring text is a list of BYTES in UTF-8: len() counts bytes. 'é' is two bytes, the Arabic letters two bytes each, Japanese three, an emoji four.
	#    So left(text, 4) may cut a letter in the middle. Count and cut with the .NET classes when the text can have such letters.
	cWord = "café"
	? nl + "1. len('café') = " + len(cWord) + " (bytes), but " + textElements(cWord).LengthInTextElements + " letters"

	# 2. Encodings: the same text, different bytes. Reading with the WRONG encoding gives garbage ("mojibake")
	aBytes = oUtf8.GetBytes("é")
	? nl + "2. 'é' in UTF-8 is " + len(aBytes) + " bytes: " + ascii(aBytes[1]) + " and " + ascii(aBytes[2])
	? "   the same bytes read as Latin-1 give: " + oLatin1.GetString(aBytes) + "  (two wrong letters)"
	? "   read as UTF-8 again: " + oUtf8.GetString(aBytes)

	# 3. A round trip: text -> bytes -> text, with the same encoding, gives the same text
	cArabic = "مرحبا بالعالم"
	? nl + "3. Arabic text survives the round trip: " + yesNo(oUtf8.GetString(oUtf8.GetBytes(cArabic)) = cArabic)

	# 4. One letter you see can be several code points: 'é' can be e + a combining accent. An emoji with a skin colour is two.
	cDecomposed = "e" + char(204) + char(129)        # the bytes of 'e' followed by U+0301 (combining acute accent)
	oShown = textElements(cDecomposed)
	? nl + "4. 'e' + a combining accent: " + len(cDecomposed) + " bytes, " + oShown.LengthInTextElements + " letter shown: " + cDecomposed

	# 5. Comparing texts: "é" typed in the two ways looks the same but the bytes differ. Normalize before comparing.
	cComposed = "é"
	? nl + "5. Looks the same, but equal as bytes? " + yesNo(cComposed = cDecomposed)
	nSame = new String().Compare([ :strA = cComposed, :strB = cDecomposed, :ignoreCase = False, :culture = new CultureInfo("en-US") ])
	? "   Compared as TEXT with a culture (en-US): " + yesNo(nSame = 0)

	# 6. Categories: .NET knows what kind of character something is
	for cChar in ["A","7","€","!"]
		? "   '" + cChar + "' is: " + new CharUnicodeInfo().GetUnicodeCategory(cChar)
	next

# text padded with spaces on the right (the columns of the table)
func padRight cText, nWidth
	cResult = cText
	while len(cResult) < nWidth
		cResult += " "
	end
	return cResult

# a StringInfo knows the letters you see (text elements) of a text
func textElements cText
	return new StringInfo().@New([ :value = cText ])

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
