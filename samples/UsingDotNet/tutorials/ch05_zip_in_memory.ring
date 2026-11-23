# ZIP archives in memory - ZipArchive on a MemoryStream, entries, reading one file, compression levels, and updating an archive
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.IO.Compression"
	"System.Text"
}

func main

	oUtf8 = new UTF8Encoding()

	# 1. A ZIP archive does not have to be a file. ZipArchive works on any stream: a MemoryStream keeps the whole archive in memory, which is
	#    what a web program does when it sends a download, or a test that does not want to leave files on the disk.
	oMemory = new MemoryStream
	oZip = dnNew("ZipArchive",[ :stream = oMemory, :mode = "Create", :leaveOpen = True ])
	addEntry(oZip,"readme.txt","Read me first." + nl + "Second line.")
	addEntry(oZip,"data/numbers.txt",copy("1234567890 ",500))
	addEntry(oZip,"data/names.txt","Ann" + nl + "Bob" + nl + "Cy")
	oZip.Dispose()                       # Dispose writes the end of the archive: without it the archive is incomplete
	? "1. an archive with 3 files is in memory, it has bytes: " + (oMemory.Length > 0)

	# 2. Read it: open the archive again for reading and list the entries (full name, size, compressed size)
	oMemory.Position = 0
	oRead = dnNew("ZipArchive",[ :stream = oMemory, :mode = "Read", :leaveOpen = True ])
	? nl + "2. the entries:"
	for oEntry in oRead.Entries.toList()
		? "   " + padRight(oEntry.FullName,18) + padLeft("" + oEntry.Length,6) + " bytes, packed smaller than the original: " + (oEntry.CompressedLength < oEntry.Length)
	next

	# 3. Read one file: GetEntry finds it by name (null when it is not there), Open gives a stream to read it
	oEntry = oRead.GetEntry("data/names.txt")
	oReader = new StreamReader(oEntry.Open())
	? nl + "3. data/names.txt contains: " + substr(substr(oReader.ReadToEnd(),char(13),""),nl,", ")
	oReader.Dispose()
	oMissing = oRead.GetEntry("nothing.txt")
	? "   GetEntry of a missing name is null: " + oMissing.isNull()
	oRead.Dispose()

	# 4. The same text with different compression levels. The size of the archive is the size of the MemoryStream after the archive was
	#    closed. The exact numbers depend on the version of the compression library, so the program compares them.
	cLong = copy("1234567890 ",500)
	nNone = packSize("NoCompression",cLong)
	nFast = packSize("Fastest",cLong)
	nBest = packSize("SmallestSize",cLong)
	? nl + "4. the same 5500 characters in an archive:"
	? "   without compression the archive is bigger than the text: " + (nNone > len(cLong))
	? "   fastest is much smaller than no compression:             " + (nFast < nNone / 10)
	? "   smallest size is not bigger than fastest:                " + (nBest <= nFast)

	# 5. Update: open the archive in Update mode, add a file and delete another one
	oMemory.Position = 0
	oUpdate = dnNew("ZipArchive",[ :stream = oMemory, :mode = "Update", :leaveOpen = True ])
	addEntry(oUpdate,"notes/new.txt","added later")
	oUpdate.GetEntry("data/numbers.txt").Delete()
	oUpdate.Dispose()
	oMemory.Position = 0
	oCheck = dnNew("ZipArchive",[ :stream = oMemory, :mode = "Read" ])
	cNames = ""
	for oItem in oCheck.Entries.toList()
		cNames += oItem.FullName + " "
	next
	? nl + "5. after the update: " + cNames
	oCheck.Dispose()

	# 6. Names inside an archive use / and must stay inside: an entry called ../../x would be written outside the target folder when
	#    somebody unpacks it (the tutorial "Tar archives" warns about it). Check each name before you unpack by hand.
	? nl + "6. a safe name has no '..' part and does not start with '/': " + safeName("data/names.txt") + ", " + safeName("../../etc/passwd") + ", " + safeName("/absolute.txt")

func addEntry oZip,cName,cText

	oEntry = oZip.CreateEntry(cName)
	oWriter = new StreamWriter(oEntry.Open())
	oWriter.Write(cText)
	oWriter.Dispose()

func packSize cLevel,cText

	oStream = new MemoryStream
	oZip = dnNew("ZipArchive",[ :stream = oStream, :mode = "Create", :leaveOpen = True ])
	oEntry = oZip.CreateEntry([ :entryName = "text.txt", :compressionLevel = cLevel ])
	oWriter = new StreamWriter(oEntry.Open())
	oWriter.Write(cText)
	oWriter.Dispose()
	oZip.Dispose()                       # the size is known when the archive is closed
	return oStream.Length

func safeName cName

	if left(cName,1) = "/" or left(cName,1) = "\" or substr(cName,"..") > 0
		return "unsafe"
	ok
	return "safe"

func padRight cText,nWidth

	return cText + copy(" ",nWidth - len(cText))

func padLeft cText,nWidth

	return copy(" ",nWidth - len(cText)) + cText
