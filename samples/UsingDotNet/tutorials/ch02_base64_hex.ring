# bytes as text - Base64, Base64 for URLs and hexadecimal: encoding and decoding, the size of the result, line breaks, and data URIs
load "dotnet.ring"
using {
	"System"
	"System.Text"
	"System.Security.Cryptography"
}

func main
	oConvert = new Convert()

	# Bytes can hold any value from 0 to 255, but many places accept only TEXT: an e-mail, a JSON file, a URL, an XML attribute. An
	# ENCODING turns bytes into letters and digits that are safe in such places, and back. The two common ones are Base64 and hexadecimal.
	cData = "Ring + .NET"

	# 1. Base64: 3 bytes become 4 characters from A-Z a-z 0-9 + /, and = fills the end. The result is a third longer than the bytes.
	? "1. Base64 of '" + cData + "':"
	cBase64 = toBase64(cData)
	? "   " + cBase64 + "   (" + len(cData) + " bytes -> " + len(cBase64) + " characters)"
	? "   decoded again: " + fromBase64(cBase64) + "   same as before: " + yesNo(fromBase64(cBase64) = cData)

	# 2. The padding: the number of = at the end shows how many bytes were missing in the last group of three
	? nl + "2. the padding for 1, 2 and 3 bytes:"
	for cText in [ "a", "ab", "abc", "abcd" ]
		? "   " + padRight(cText,6) + padRight(toBase64(cText),10) + "(" + len(cText) + " bytes)"
	next

	# 3. Any bytes, including the ones that are not text: all the 256 byte values go through Base64 and come back
	cEveryByte = ""
	for i = 0 to 255
		cEveryByte += char(i)
	next
	cEncoded = toBase64(cEveryByte)
	? nl + "3. all 256 byte values: " + len(cEveryByte) + " bytes -> " + len(cEncoded) + " characters, back again the same: " + yesNo(fromBase64(cEncoded) = cEveryByte)

	# 4. Base64 for URLs and file names. The signs + and / have a meaning in a URL, so they are replaced by - and _, and the = is
	#    left out. The bytes 251 255 show the difference.
	cSpecial = char(251) + char(255)
	cStandard = toBase64(cSpecial)
	cUrlSafe = substr(substr(substr(cStandard,"+","-"),"/","_"),"=","")
	? nl + "4. the bytes 251 255:"
	? "   standard Base64: " + cStandard
	? "   for URLs:        " + cUrlSafe + "   (+ becomes -, / becomes _, and the = is dropped)"

	#    A decoder for the URL form must put the signs back and add the padding
	? "   decoded again:   " + yesNo(fromBase64(addPadding(substr(substr(cUrlSafe,"-","+"),"_","/"))) = cSpecial)

	# 5. Hexadecimal: each byte becomes two characters 0-9 A-F. The result is twice as long, but it is easy to read and to compare.
	cHex = oConvert.ToHexString(cData)
	? nl + "5. hexadecimal of '" + cData + "': " + cHex + "   (" + len(cData) + " bytes -> " + len(cHex) + " characters)"
	? "   decoded again: " + oConvert.FromHexString(cHex)
	? "   the hexadecimal of the bytes 0, 15, 16 and 255: " + oConvert.ToHexString(char(0) + char(15) + char(16) + char(255))

	# 6. A wrong text raises an error: a character that is not in the alphabet, or a hexadecimal text with an odd length
	? nl + "6. wrong input:"
	? "   Base64 'not base64!': " + tryDecode("not base64!")
	? "   hexadecimal 'ABC' (odd length): " + tryHex("ABC")

	# 7. A data URI puts a small file inside the text of a page or a style sheet: the type, the word base64 and the Base64 text
	cDataUri = "data:text/plain;base64," + toBase64("Hello")
	? nl + "7. a data URI: " + cDataUri

	# 8. Where each one is used: Base64 for e-mail attachments, certificates, JSON that carries bytes, and tokens; hexadecimal for hashes,
	#    colors and the bytes in a debugger
	? nl + "8. the SHA-256 hash of 'abc' in hexadecimal:"
	? "   " + hashHex("abc")

func toBase64 cBytes
	return new Convert().ToBase64String(cBytes)

func fromBase64 cText
	return new Convert().FromBase64String(cText)

# a Base64 text needs a length that is a multiple of 4: = fills the missing places
func addPadding cText
	nMissing = (4 - len(cText) % 4) % 4
	return cText + copy("=",nMissing)

func tryDecode cText
	try
		fromBase64(cText)
		return "decoded"
	catch
		return errorKind(cCatchError)
	done

func tryHex cText
	try
		new Convert().FromHexString(cText)
		return "decoded"
	catch
		return errorKind(cCatchError)
	done

func hashHex cText
	return new Convert().ToHexString(new SHA256().HashData(cText))

func errorKind cMessage
	cText = trim(cMessage)
	nStart = substr(cText,"DotNet Error: ")
	if nStart > 0
		cText = substr(cText,nStart + 14)
	ok
	nEnd = substr(cText,":")
	if nEnd > 0
		cText = left(cText,nEnd - 1)
	ok
	return cText

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"

func padRight cText,nWidth
	return cText + copy(" ",nWidth - len(cText))
