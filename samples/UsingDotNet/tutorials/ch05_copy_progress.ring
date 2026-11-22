# copying a big file with progress - reading and writing in pieces with a byte buffer, a percentage, cancelling, and checking the copy
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Security.Cryptography"
}

func main
	oPath = new Path()
	oFile = new File()
	cFolder = oPath.Combine([ oPath.GetTempPath(), "ringdotnet-copy-" + oPath.GetRandomFileName() ])
	new Directory().CreateDirectory(cFolder)
	cSource = cFolder + "/source.bin"
	cTarget = cFolder + "/target.bin"

	# A source file of 3,000,000 bytes: a pattern of all 256 byte values, repeated (the program makes it, so that the output is always the same)
	cBlock = ""
	for i = 0 to 255
		cBlock += char(i)
	next
	cData = ""
	for i = 1 to 11719
		cData += cBlock
	next
	cData = left(cData,3000000)
	oFile.WriteAllBytes(cSource,cData)
	? "1. the source file has " + new FileInfo(cSource).Length + " bytes"

	# 2. A copy in PIECES. File.Copy does it in one call, but a program that shows a progress bar, or that can be canceled, reads and writes
	#    a piece at a time. The piece is a BYTE BUFFER (dnBuffer): Read fills it, and Write sends the same buffer on, so the bytes are
	#    never turned into a Ring text. The buffer has 64 KB: a small buffer means many calls, a huge one wastes memory.
	? nl + "2. copy with a progress report at each quarter:"
	nCopied = copyFile(cSource,cTarget,65536,0)
	? "   copied " + nCopied + " bytes"

	# 3. Check the copy: the same size and the same SHA-256 checksum (the tutorial about checking that files did not change)
	? nl + "3. the copy is complete: sizes " + yesNo(new FileInfo(cSource).Length = new FileInfo(cTarget).Length) + ", checksums " + yesNo(checksum(cSource) = checksum(cTarget))

	# 4. Cancel. The program stops after 1,000,000 bytes, as if the user pressed Cancel. A half copy is worse than none, so the target is deleted.
	oFile.Delete(cTarget)
	? nl + "4. cancel after 1,000,000 bytes:"
	nCopied = copyFile(cSource,cTarget,65536,1000000)
	? "   stopped at " + nCopied + " bytes; the half copy is deleted: " + yesNo(not oFile.Exists(cTarget))

	# 5. The size of the buffer. The last piece is smaller than the buffer, and Read says how many bytes it gave. A buffer of 1 byte
	#    would work and be very slow: count the calls for three sizes.
	? nl + "5. the number of Read calls for the 3,000,000 bytes:"
	for nSize in [ 4096, 65536, 1048576 ]
		? "   buffer of " + padLeft("" + nSize,8) + " bytes: " + countCalls(cSource,nSize) + " calls"
	next

	new Directory().Delete([ :path = cFolder, :recursive = True ])

# Copy a file in pieces. Progress is printed for the first piece after each quarter (the pieces are 64 KB, so it is a little over 25 percent). nStopAfter > 0 cancels when that many bytes were copied; the
# target is then deleted. The answer is the number of bytes copied.
func copyFile cSource,cTarget,nBufferSize,nStopAfter
	oIn = dnNew("FileStream",[ :path = cSource, :mode = "Open", :access = "Read" ])
	oOut = dnNew("FileStream",[ :path = cTarget, :mode = "Create", :access = "Write" ])
	nTotal = oIn.Length
	oBuffer = dnBuffer(nBufferSize)
	nCopied = 0
	nQuarter = 0
	lCanceled = False
	while True
		nRead = oIn.Read(oBuffer,0,nBufferSize)
		if nRead = 0
			exit                                          # Read gives 0 at the end of the file
		ok
		oOut.Write(oBuffer,0,nRead)                       # only the nRead bytes that were read
		nCopied += nRead
		nPercent = floor(100 * nCopied / nTotal)
		if floor(nPercent / 25) > nQuarter
			nQuarter = floor(nPercent / 25)
			? "   " + nPercent + " percent (" + nCopied + " of " + nTotal + " bytes)"
		ok
		if nStopAfter > 0 and nCopied >= nStopAfter
			lCanceled = True
			exit
		ok
	end
	oOut.Dispose()
	oIn.Dispose()
	if lCanceled
		new File().Delete(cTarget)
	ok
	return nCopied

# how many calls of Read a buffer of this size needs for the whole file
func countCalls cFile,nBufferSize
	oIn = dnNew("FileStream",[ :path = cFile, :mode = "Open", :access = "Read" ])
	oBuffer = dnBuffer(nBufferSize)
	nCalls = 0
	while oIn.Read(oBuffer,0,nBufferSize) > 0
		nCalls++
	end
	oIn.Dispose()
	return nCalls

func checksum cFile
	return new Convert().ToHexString(new SHA256().HashData(new File().ReadAllBytes(cFile)))

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"

func padLeft cText,nWidth
	return copy(" ",nWidth - len(cText)) + cText
