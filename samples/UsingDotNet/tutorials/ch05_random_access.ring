# random access files - FileStream: records of a fixed size, Seek, changing one record in place, SetLength and locking a file with FileShare
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Text"
}

nSize = 20                        # every record has 20 bytes: the name in 12, the quantity in 4, and 4 spaces

func main
	oPath = new Path()
	cFolder = oPath.Combine([ oPath.GetTempPath(), "ringdotnet-records-" + oPath.GetRandomFileName() ])
	new Directory().CreateDirectory(cFolder)
	cFile = cFolder + "/stock.dat"

	# A text file is read from the first byte to the last. A file of RECORDS with the same size can be used like a table: record number n
	# starts at the byte n * size, so the program goes to it with Seek, without reading the records before it.

	# 1. Write five records. The FileStream is opened with a mode (Create: a new empty file) and an access (what the program may do).
	oStream = openFile(cFile,"Create","ReadWrite","None")
	for aItem in [ ["Tea",40], ["Coffee",25], ["Sugar",100], ["Milk",8], ["Honey",12] ]
		writeRecord(oStream,aItem[1],aItem[2])
	next
	oStream.Flush(NULL)                               # push what is in the memory of the program to the file
	? "1. five records written, the file has " + oStream.Length + " bytes (5 x " + nSize + ")"

	# 2. Read record 3 without reading the first two: Seek(offset, origin) moves the position; "Begin" counts from the start of the file
	? nl + "2. record 3: " + showRecord(readRecord(oStream,3))
	? "   the position is now " + oStream.Position + ", right after that record"

	# 3. Change one record IN PLACE: seek to it and write the new bytes over the old ones. The other records are not touched.
	writeRecordAt(oStream,3,"Sugar",90)
	? nl + "3. after selling 10 of the sugar:"
	for i = 1 to 5
		? "   " + i + ". " + showRecord(readRecord(oStream,i))
	next

	# 4. Add a record at the end: seek to the end of the file (Length) and write
	writeRecordAt(oStream,6,"Jam",30)
	? nl + "4. a sixth record was added: the file has " + oStream.Length + " bytes, " + (oStream.Length / nSize) + " records"

	# 5. SetLength cuts the file (or makes it longer: the new bytes are zero). Three records stay.
	oStream.SetLength(3 * nSize)
	? nl + "5. after SetLength(3 * " + nSize + "): " + (oStream.Length / nSize) + " records, the last is " + showRecord(readRecord(oStream,3))
	oStream.Dispose()

	# 6. Locking. FileShare says what OTHER programs (and other FileStreams of this program) may do while the file is open. "None": nobody.
	#    A second open raises an IOException: the file is in use. This is how a program makes sure that only one writer works on a file.
	oFirst = openFile(cFile,"Open","ReadWrite","None")
	? nl + "6. the file is open with FileShare.None:"
	? "   a second open for reading: " + tryOpen(cFile,"Read","Read")
	oFirst.Dispose()
	? "   after the first stream was closed: " + tryOpen(cFile,"Read","Read")

	# 7. "Read" shares reading: many readers are fine at the same time, and a writer is refused
	oReader = openFile(cFile,"Open","Read","Read")
	? nl + "7. the file is open for reading with FileShare.Read:"
	? "   another reader: " + tryOpen(cFile,"Read","Read")
	? "   a writer:       " + tryOpen(cFile,"ReadWrite","Read")
	oReader.Dispose()

	new Directory().Delete([ :path = cFolder, :recursive = True ])

# a FileStream: the path, the mode, the access and the share
func openFile cFile,cMode,cAccess,cShare
	return dnNew("FileStream",[ :path = cFile, :mode = cMode, :access = cAccess, :share = cShare ])

# a record: the name to 12 characters (spaces on the right), the quantity to 4 digits (zeros on the left), and 4 spaces
func makeRecord cName,nQuantity
	return left(cName + copy(" ",12),12) + right("0000" + nQuantity,4) + "    "

func writeRecord oStream,cName,nQuantity
	cRecord = makeRecord(cName,nQuantity)
	oStream.Write(cRecord,0,nSize)

# record number n (from 1): go to its place and write
func writeRecordAt oStream,n,cName,nQuantity
	oStream.Seek((n - 1) * nSize,"Begin")
	writeRecord(oStream,cName,nQuantity)

func readRecord oStream,n
	oStream.Seek((n - 1) * nSize,"Begin")
	oReader = dnNew("BinaryReader",[ :input = oStream, :encoding = new UTF8Encoding(), :leaveOpen = True ])
	return oReader.ReadBytes(nSize)

func showRecord cRecord
	return trim(left(cRecord,12)) + ", quantity " + (0 + substr(cRecord,13,4))

# try to open a file; the answer is "ok" or the kind of the error
func tryOpen cFile,cAccess,cShare
	try
		oStream = openFile(cFile,"Open",cAccess,cShare)
		oStream.Dispose()
		return "ok"
	catch
		return errorKind(cCatchError)
	done

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
