# compression - GZip, Deflate and Brotli on streams, sizes, a round trip and a compressed file
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.IO.Compression"
	"System.Text"
}

func main
	# Compression looks for repetition. A text with many repeated parts becomes small; random data does not.
	cText = ""
	for i = 1 to 200
		cText += "The quick brown fox jumps over the lazy dog. "
	next
	oUtf8 = new UTF8Encoding()
	aBytes = oUtf8.GetBytes(cText)             # a byte[] is a Ring text of bytes in this package
	? "1. original text: " + len(aBytes) + " bytes"

	# 2. The three formats. Each one is a stream that WRAPS another stream: we write into the compressor, and the compressed
	#    bytes land in the memory stream below it. CompressionLevel.Optimal gives the smallest result.
	? nl + "2. compressed sizes:"
	for cFormat in ["GZip","Deflate","Brotli"]
		cPacked = compress(cFormat,aBytes)
		? "   " + padRight(cFormat,8) + len(cPacked) + " bytes   (" + floor(len(aBytes) / len(cPacked)) + " times smaller)"
	next

	# 3. The round trip: decompress and compare
	cPacked = compress("GZip",aBytes)
	cBack = decompress("GZip",cPacked)
	? nl + "3. after GZip and back: " + len(cBack) + " bytes, same as the original: " + (cBack = aBytes)

	# 4. GZip data starts with two fixed bytes (31 and 139): that is how a program recognises a .gz file
	? nl + "4. first bytes of a GZip result: " + ascii(cPacked[1]) + " " + ascii(cPacked[2])

	# 5. Data that does not repeat does not shrink (it grows a little because of the header)
	cNoise = ""
	for i = 1 to 2000
		cNoise += char(random(255))
	next
	cNoisePacked = compress("GZip",cNoise)
	? nl + "5. 2000 random bytes: the GZip result is larger than the original: " + (len(cNoisePacked) > 2000)

	# 6. A compressed file: write a .gz file, read it back line by line with a StreamReader on top of the decompressor
	cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet_tutorial88.txt.gz"])
	oFile = new FileStream(cFile,"Create")
	oGzip = dnNew("GZipStream",[ :stream = oFile, :mode = "Compress" ])
	oWriter = new StreamWriter(oGzip)
	for i = 1 to 3
		oWriter.WriteLine("line " + i + " of the compressed file")
	next
	oWriter.Dispose()                          # closing the writer also closes the compressor and the file
	? nl + "6. file size on disk: " + new FileInfo(cFile).Length + " bytes"
	oFile = new FileStream(cFile,"Open")
	oGzip = dnNew("GZipStream",[ :stream = oFile, :mode = "Decompress" ])
	oReader = new StreamReader(oGzip)
	while not oReader.EndOfStream
		? "   read: " + oReader.ReadLine()
	end
	oReader.Dispose()
	new File().Delete(cFile)

func compress cFormat,cData
	oMemory = new MemoryStream()
	oPacker = packer(cFormat,oMemory,"Compress")
	oPacker.Write(cData,0,len(cData))
	oPacker.Dispose()                          # Dispose finishes the compressed data: without it the end is missing
	return oMemory.ToArray()

func decompress cFormat,cData
	oSource = dnNew("MemoryStream",[ :buffer = cData ])
	oUnpacker = packer(cFormat,oSource,"Decompress")
	oOut = new MemoryStream()
	oUnpacker.CopyTo(oOut)
	return oOut.ToArray()

func packer cFormat,oStream,oMode
	switch cFormat
	on "GZip"    return dnNew("GZipStream",[ :stream = oStream, :mode = oMode ])
	on "Deflate" return dnNew("DeflateStream",[ :stream = oStream, :mode = oMode ])
	on "Brotli"  return dnNew("BrotliStream",[ :stream = oStream, :mode = oMode ])
	off

func padRight cText,nWidth
	return cText + copy(" ",nWidth - len(cText))
