# text files and encodings - the bytes of a text, the byte order mark, reading a file in the right encoding, and strict decoding
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Text"
}

func main

	oFile = new File()
	oPath = new Path()
	cFolder = oPath.Combine([ oPath.GetTempPath(), "ringdotnet-enc-" + oPath.GetRandomFileName() ])
	new Directory().CreateDirectory(cFolder)

	# A file holds BYTES. An ENCODING says which bytes mean which characters. The text "Café €" has an accent and a euro sign, which
	# are not in the old 7-bit ASCII table.
	cText = "Caf" + char(195) + char(169) + " " + char(226) + char(130) + char(172)          # the UTF-8 bytes of  Café €
	oUtf8 = new Encoding().UTF8
	oUtf16 = new Encoding().Unicode                       # .NET calls UTF-16 (little endian) "Unicode"
	oLatin1 = new Encoding().Latin1
	oAscii = new Encoding().ASCII

	# 1. The same text in four encodings: different bytes, different sizes
	? "1. the bytes of the text 'Cafe' with an accent, a space and the euro sign:"
	for aItem in [ ["UTF-8",oUtf8], ["UTF-16",oUtf16], ["Latin-1",oLatin1], ["ASCII",oAscii] ]
		cBytes = aItem[2].GetBytes(cText)
		? "   " + padRight(aItem[1],8) + padRight("" + len(cBytes) + " bytes",10) + toHex(cBytes)
	next
	? "   UTF-8 uses 1 byte for the letters of English and 2 to 4 for the others; UTF-16 uses 2 or 4; Latin-1 has one byte for 256"
	? "   characters and no euro sign (it becomes ?); ASCII has 128 characters."

	# 2. The byte order mark (BOM): a few bytes at the start of a file that say which encoding it has. UTF-8 does not need one, and many
	#    programs write none; UTF-16 files have one almost always, because it also tells the order of the two bytes of a character.
	? nl + "2. the byte order marks:"
	oFile.WriteAllText([ :path = cFolder + "/a.txt", :contents = cText ])
	? "   File.WriteAllText with no encoding writes UTF-8 and no BOM: first bytes " + toHex(left(oFile.ReadAllBytes(cFolder + "/a.txt"),3))
	oWithBom = new UTF8Encoding
	oWithBom.@New(True)  # True: write the byte order mark
	oFile.WriteAllText([ :path = cFolder + "/e.txt", :contents = cText, :encoding = oWithBom ])
	? "   with UTF8Encoding(True) the file starts with " + toHex(left(oFile.ReadAllBytes(cFolder + "/e.txt"),3)) + "   (the BOM of UTF-8)"
	oFile.WriteAllText([ :path = cFolder + "/b.txt", :contents = cText, :encoding = oUtf16 ])
	? "   with the UTF-16 encoding the file starts with " + toHex(left(oFile.ReadAllBytes(cFolder + "/b.txt"),2)) + " and has " + len(oFile.ReadAllBytes(cFolder + "/b.txt")) + " bytes   (the BOM FF FE: little endian)"

	# 3. Reading. File.ReadAllText looks at the BOM and uses the right encoding by itself: the UTF-16 file reads back as the same text.
	? nl + "3. File.ReadAllText finds the BOM:"
	? "   the UTF-8 file:  " + yesNo(oFile.ReadAllText(cFolder + "/a.txt") = cText)
	? "   the UTF-16 file: " + yesNo(oFile.ReadAllText(cFolder + "/b.txt") = cText)
	? "   the UTF-16 file, with UTF-8 given as the encoding: " + yesNo(oFile.ReadAllText([ :path = cFolder + "/b.txt", :encoding = oUtf8 ]) = cText) + "   (a BOM in the file wins over the given encoding)"

	# 4. A file without a BOM and in an old encoding. The bytes of Latin-1 "Café" are 43 61 66 E9. Read as UTF-8 the byte E9 is not valid
	#    and becomes the replacement character; read as Latin-1 the text is right. Nothing in the file tells which: the program or the
	#    user must know. (Windows programs write old files in the code page of the computer: Latin-1 is a good first guess for Europe.)
	oFile.WriteAllBytes(cFolder + "/c.txt","Caf" + char(233))
	cAsUtf8 = oFile.ReadAllText(cFolder + "/c.txt")
	cAsLatin1 = oFile.ReadAllText([ :path = cFolder + "/c.txt", :encoding = oLatin1 ])
	? nl + "4. a Latin-1 file without BOM:"
	? "   read as UTF-8:   " + len(cAsUtf8) + " bytes, the last character is the replacement sign (EF BF BD): " + yesNo(right(cAsUtf8,3) = char(239) + char(191) + char(189))
	? "   read as Latin-1: " + yesNo(cAsLatin1 = "Caf" + char(195) + char(169)) + "  (the same text as 'Cafe' with the accent)"

	# 5. Strict decoding: UTF8Encoding(False, True) raises an error for bytes that are not valid UTF-8, instead of replacing them. That
	#    is a good test: "is this file UTF-8?". A text that is valid in UTF-8 and has accents is almost certainly UTF-8.
	? nl + "5. is it valid UTF-8?"
	? "   the UTF-8 file:   " + yesNo(isValidUtf8(oFile.ReadAllBytes(cFolder + "/a.txt")))
	? "   the Latin-1 file: " + yesNo(isValidUtf8(oFile.ReadAllBytes(cFolder + "/c.txt")))
	? "   a plain English file is valid UTF-8 and valid Latin-1: " + yesNo(isValidUtf8("Hello"))

	# 6. A program that must read a file from outside decides in this order: a BOM says it; else valid UTF-8 says UTF-8; else it uses a
	#    default (Latin-1 or the encoding the user chose). And it writes UTF-8, with a BOM only for programs that need it.
	? nl + "6. detecting the encoding of the three files:"
	for cName in [ "a.txt", "e.txt", "b.txt", "c.txt" ]
		? "   " + cName + ": " + detect(oFile.ReadAllBytes(cFolder + "/" + cName))
	next

	# 7. Line endings: Windows files use two characters (13 10), Unix files one (10). ReadAllLines understands both.
	oFile.WriteAllBytes(cFolder + "/d.txt","one" + char(13) + char(10) + "two" + char(10) + "three")
	aLines = oFile.ReadAllLines(cFolder + "/d.txt").toList()
	? nl + "7. a file with mixed line endings has " + len(aLines) + " lines: " + aLines[1] + ", " + aLines[2] + ", " + aLines[3]

	new Directory().Delete([ :path = cFolder, :recursive = True ])

# does the text of bytes decode without a replacement as UTF-8? (the strict encoding raises an error for bad bytes)
func isValidUtf8 cBytes

	oStrict = new UTF8Encoding
	oStrict.@New([ :encoderShouldEmitUTF8Identifier = False, :throwOnInvalidBytes = True ])
	try
		oStrict.GetString(cBytes)
		return True
	catch
		return False
	done

# the order of the tests
func detect cBytes

	if left(cBytes,3) = char(239) + char(187) + char(191)
		return "UTF-8 with a BOM"
	but left(cBytes,2) = char(255) + char(254)
		return "UTF-16 little endian (the BOM FF FE)"
	but left(cBytes,2) = char(254) + char(255)
		return "UTF-16 big endian (the BOM FE FF)"
	but isValidUtf8(cBytes)
		return "UTF-8 (no BOM)"
	ok
	return "not UTF-8: try Latin-1"

# the bytes of a text as hexadecimal pairs
func toHex cBytes

	cText = ""
	for i = 1 to len(cBytes)
		cText += right("0" + upper(hex(ascii(substr(cBytes,i,1)))),2) + " "
	next
	return trim(cText)

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"

func padRight cText,nWidth

	return cText + copy(" ",nWidth - len(cText))
