# streams and compression - the same data in memory, in a file, and squeezed with GZip
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.IO.Compression"
	"System.Text"
}

func main
	oUtf8 = new Encoding().UTF8

	# 1. A stream is a flow of bytes. A MemoryStream keeps them in memory: no file is needed to learn the pattern.
	oMemory = new MemoryStream()
	oWriter = new StreamWriter(oMemory)
	oWriter.WriteLine("first line")
	oWriter.WriteLine("second line")
	oWriter.Flush()                                   # the writer keeps a buffer: Flush sends it to the stream
	? "1. bytes in the memory stream: " + oMemory.Length

	# 2. Go back to the start and read what was written
	oMemory.Position = 0
	oReader = new StreamReader(oMemory)
	? "2. read back: " + oReader.ReadLine() + " / " + oReader.ReadLine()

	# 3. Compression: repeated text becomes much smaller. GZipStream wraps another stream: what you write is compressed on the way.
	cText = ""
	for nI = 1 to 200
		cText += "The quick brown fox jumps over the lazy dog. "
	next
	aBytes = oUtf8.GetBytes(cText)
	oPacked = new MemoryStream()
	oGzip = dnNew("GZipStream",[ :stream = oPacked, :mode = "Compress", :leaveOpen = True ])   # leaveOpen: keep the inner stream usable
	oGzipWriter = new StreamWriter(oGzip)
	oGzipWriter.Write(cText)
	oGzipWriter.Dispose()                             # Dispose finishes the compressed data: without it the result is incomplete
	? nl + "3. " + len(aBytes) + " bytes became " + oPacked.Length + " bytes (" + floor(oPacked.Length * 100 / len(aBytes)) + " %)"

	# 4. And back again: reading through a GZipStream decompresses
	oPacked.Position = 0
	oUnzip = new GZipStream(oPacked,"Decompress")
	oBack = new StreamReader(oUnzip)
	cBack = oBack.ReadToEnd()
	? "4. the text is the same after the round trip: " + yesNo(cBack = cText)

	# 5. Files are streams too: File.OpenRead / OpenWrite give a FileStream, with the same Read/Write methods
	cFile = new Path().Combine([new Path().GetTempPath(),"tutorial57.gz"])
	oFileStream = new File().Create(cFile)
	oFileGzip = new GZipStream(oFileStream,"Compress")
	oFileWriter = new StreamWriter(oFileGzip)
	oFileWriter.Write(cText)
	oFileWriter.Dispose()                             # closes the writer, the GZipStream and the file
	? nl + "5. the .gz file has " + new FileInfo(cFile).Length + " bytes"
	new File().Delete(cFile)

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
