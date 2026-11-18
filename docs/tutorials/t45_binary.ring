# Tutorial 45: binary files - bytes, BinaryWriter and BinaryReader, a file format, and a hex dump
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Text"
}

func main
	cFile = new Path().Combine(new Path().GetTempPath(),"tutorial45.dat")

	# 1. A binary file stores values as bytes, not as readable text. We invent a tiny format:
	#      the text "RDN1" (a "magic number": it says what kind of file this is), then
	#      a 32-bit whole number (the count), a text (the title), and that many decimal numbers.
	#   Note: Write(21.5) writes a decimal number (8 bytes); Write(23) would write a whole number (4 bytes). The type that you pass decides.
	oStream = new FileStream(cFile,"Create")
	oWriter = new BinaryWriter(oStream)
	oWriter.Write("RDN1")
	oWriter.Write(3)
	oWriter.Write("Temperatures")
	oWriter.Write(21.5)
	oWriter.Write(19.25)
	oWriter.Write(23.75)
	oWriter.Close()
	? "1. Written: " + new FileInfo(cFile).Length + " bytes"

	# 2. The raw bytes: a hex dump shows offset, bytes in hex, and the printable characters
	? nl + "2. The hex dump of the file:"
	? hexDump(cFile)

	# 3. Read it back with a BinaryReader: the reads must follow the same order as the writes
	oReader = new BinaryReader(new FileStream(cFile,"Open"))
	cMagic = oReader.ReadString()
	nCount = oReader.ReadInt32()
	cTitle = oReader.ReadString()
	? nl + "3. Magic '" + cMagic + "', " + nCount + " values, title '" + cTitle + "'"
	for nIndex = 1 to nCount
		? "   value " + nIndex + " = " + oReader.ReadDouble()
	next
	oReader.Close()

	# 4. Checking the magic number protects against opening the wrong kind of file
	new File().WriteAllText(cFile,"just some text, not our format")
	if readMagic(cFile) != "RDN1"
		? nl + "4. Not our file format: refused"
	ok

	# 5. Bytes and numbers: BitConverter shows how a number is stored. Little endian: the smallest byte comes first
	aBytes = new BitConverter().GetBytes(1000)
	? nl + "5. 1000 as bytes: " + len(aBytes) + " bytes, the first two are " + ascii(aBytes[1]) + " and " + ascii(aBytes[2]) + " (1000 = 3 * 256 + 232)"
	new File().Delete(cFile)

# a hex dump: 8 bytes per line
func hexDump cFile
	cData = new File().ReadAllBytes(cFile)
	cOut = ""
	for nStart = 1 to len(cData) step 8
		cHex = ""
		cChars = ""
		for nIndex = nStart to min(nStart + 7,len(cData))
			nByte = ascii(cData[nIndex])
			cHex += right("0" + hex(nByte),2) + " "
			if nByte >= 32 and nByte < 127
				cChars += cData[nIndex]
			else
				cChars += "."
			ok
		next
		cOut += "   " + right("0000" + hex(nStart - 1),4) + "  " + cHex + copies("   ",8 - (min(nStart + 7,len(cData)) - nStart + 1)) + " " + cChars + nl
	next
	return cOut

func readMagic cFile
	cMagic = ""
	oReader = ""
	try
		oReader = new BinaryReader(new FileStream(cFile,"Open"))
		cMagic = oReader.ReadString()
	catch
		cMagic = ""
	done
	# close the file in every case, also after an error: an open file can not be deleted
	if isobject(oReader)
		oReader.Close()
	ok
	return cMagic

func copies cText, nTimes
	cResult = ""
	for nIndex = 1 to nTimes
		cResult += cText
	next
	return cResult
