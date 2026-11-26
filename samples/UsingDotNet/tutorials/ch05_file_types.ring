# finding out what a file is - the first bytes (magic numbers), a signature table, text or binary, and a file whose name tells a lie
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Text"
}

aSignatures = []                  # [ name, mime type, the first bytes ]

func main

	oFile = new File()
	oPath = new Path()
	cFolder = oPath.Combine([ oPath.GetTempPath(), "ringdotnet-types-" + oPath.GetRandomFileName() ])
	new Directory().CreateDirectory(cFolder)

	# The NAME of a file is only a habit: anybody can call a picture "notes.txt". Many file formats start with a few fixed bytes, the
	# MAGIC NUMBER (or signature), and a program that wants to know what a file really is looks at the first bytes.
	addSignatures()

	# 1. Files made by the program: only the first bytes are real, and the rest is filler (that is all the detection looks at)
	makeFile(cFolder + "/picture.png",char(137) + "PNG" + char(13) + char(10) + char(26) + char(10),"filler")
	makeFile(cFolder + "/animation.gif","GIF89a","filler")
	makeFile(cFolder + "/photo.jpg",char(255) + char(216) + char(255) + char(224),"filler")
	makeFile(cFolder + "/archive.zip","PK" + char(3) + char(4),"filler")
	makeFile(cFolder + "/document.pdf","%PDF-1.7","filler")
	makeFile(cFolder + "/program.exe","MZ" + char(144) + char(0),"filler")
	makeFile(cFolder + "/packed.gz",char(31) + char(139) + char(8),"filler")
	oFile.WriteAllText([ :path = cFolder + "/readme.txt", :contents = "Just a text file" + nl ])
	oFile.WriteAllBytes(cFolder + "/data.bin","a" + char(0) + char(1) + char(2) + char(200) + char(201))
	oFile.WriteAllBytes(cFolder + "/empty.dat","")
	? "1. what each file is:"
	aNames = sortNames(cFolder)
	for cName in aNames
		? "   " + padRight(cName,14) + describe(cFolder + "/" + cName)
	next

	# 2. A file with a wrong name: a PNG picture that is called notes.txt, and a text called photo.jpg. The program compares what the
	#    NAME says with what the BYTES say.
	oFile.Move([ :sourceFileName = cFolder + "/picture.png", :destFileName = cFolder + "/notes.txt" ])
	oFile.Move([ :sourceFileName = cFolder + "/readme.txt", :destFileName = cFolder + "/photo2.jpg" ])
	? nl + "2. names that tell a lie:"
	for cName in [ "notes.txt", "photo2.jpg", "photo.jpg" ]
		? "   " + padRight(cName,12) + checkName(cFolder + "/" + cName)
	next

	# 3. Why this is a security matter: a web site that lets users upload "pictures" must not trust the name or the type that the
	#    browser sends, but look at the bytes. (The bytes can lie too: only the first bytes are checked. A real check opens the picture.)
	? nl + "3. an upload check: is the file a PNG, a JPEG or a GIF picture?"
	for cName in [ "notes.txt", "photo.jpg", "animation.gif", "program.exe" ]
		? "   " + padRight(cName,14) + yesNo(isPicture(cFolder + "/" + cName))
	next

	new Directory().Delete([ :path = cFolder, :recursive = True ])

# the known signatures: the bytes at the start of the file
func addSignatures

	aSignatures + [ "PNG picture","image/png",char(137) + "PNG" + char(13) + char(10) + char(26) + char(10) ]
	aSignatures + [ "GIF picture","image/gif","GIF8" ]
	aSignatures + [ "JPEG picture","image/jpeg",char(255) + char(216) + char(255) ]
	aSignatures + [ "ZIP archive","application/zip","PK" + char(3) + char(4) ]
	aSignatures + [ "GZip data","application/gzip",char(31) + char(139) ]
	aSignatures + [ "PDF document","application/pdf","%PDF-" ]
	aSignatures + [ "Windows program","application/x-msdownload","MZ" ]

func makeFile cFile,cStart,cFill

	new File().WriteAllBytes(cFile,cStart + copy(cFill,20))

# the first nCount bytes of a file (fewer when the file is shorter), read into a byte buffer
func firstBytes cFile,nCount

	oStream = new FileStream
	oStream.@New([ :path = cFile, :mode = "Open", :access = "Read" ])
	oBuffer = dnBuffer(nCount)
	nRead = oStream.Read(oBuffer,0,nCount)
	oStream.Dispose()
	return dnBufferBytes(oBuffer,nRead)

# [name, mime type] of a file, from its first bytes
func detect cFile

	cStart = firstBytes(cFile,16)
	if len(cStart) = 0
		return [ "empty file","" ]
	ok
	for aSignature in aSignatures
		if left(cStart,len(aSignature[3])) = aSignature[3]
			return [ aSignature[1],aSignature[2] ]
		ok
	next
	if looksLikeText(cStart)
		return [ "text","text/plain" ]
	ok
	return [ "unknown binary data","application/octet-stream" ]

# text has no NUL and no control characters except tab, new line and return, and it is valid UTF-8
func looksLikeText cBytes

	for i = 1 to len(cBytes)
		nCode = ascii(substr(cBytes,i,1))
		if nCode = 0 or (nCode < 32 and nCode != 9 and nCode != 10 and nCode != 13)
			return False
		ok
	next
	oStrict = dnNew("UTF8Encoding",[ False, True ])
	try
		oStrict.GetString(cBytes)
		return True
	catch
		return False
	done

func describe cFile

	aType = detect(cFile)
	if aType[2] = ""
		return aType[1]
	ok
	return padRight(aType[1],22) + aType[2]

# what the name says (the extension) and what the bytes say
func checkName cFile

	cExtension = lower(new Path().GetExtension(cFile))
	aType = detect(cFile)
	aExpected = [ [".png","PNG picture"], [".gif","GIF picture"], [".jpg","JPEG picture"], [".jpeg","JPEG picture"], [".zip","ZIP archive"], [".pdf","PDF document"], [".gz","GZip data"], [".txt","text"] ]
	for aItem in aExpected
		if aItem[1] = cExtension
			if aItem[2] = aType[1]
				return "the name fits the content (" + aType[1] + ")"
			ok
			return "THE NAME SAYS " + aItem[2] + " BUT THE BYTES SAY " + aType[1]
		ok
	next
	return "unknown extension, the bytes say " + aType[1]

func isPicture cFile

	cMime = detect(cFile)[2]
	return cMime = "image/png" or cMime = "image/jpeg" or cMime = "image/gif"

func sortNames cFolder

	aList = []
	aItems = new DirectoryInfo(cFolder).GetFiles(NULL).toList()
	for oItem in aItems
		aList + oItem.Name
	next
	return sort(aList)

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"

func padRight cText,nWidth

	return cText + copy(" ",nWidth - len(cText))
