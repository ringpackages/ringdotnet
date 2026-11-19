# shared memory - a memory-mapped file seen by two programs, numbers and text in it, and a file that is edited in place
#   ring ch06_shared_memory.ring            the parent: it makes the memory and starts the child
#   ring ch06_shared_memory.ring --child    the child (the parent starts it)
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Diagnostics"
	"System.IO.MemoryMappedFiles"
	"System.Threading"
}

C_NAME = "ringdotnet_tutorial82"

func main
	if find(sysargv,"--child") > 0
		runChild()
		return
	ok
	runParent()
	editFileInPlace()

# ---------------------------------------------------------------- two programs, one block of memory

func runParent
	# 1. A memory-mapped file is a block of memory with a NAME. Any program of this computer that knows the name can open it.
	oMap = new MemoryMappedFile().CreateNew([ :mapName = C_NAME, :capacity = 4096 ])
	oAccessor = oMap.CreateViewAccessor(NULL)               # a view with Read and Write methods at a position (in bytes)

	# 2. Numbers: Write(position, value) and ReadInt32(position), ReadDouble(position). A whole Ring number is written as 4 bytes
	#    (an int), a number with decimals as 8 bytes (a double). The positions are chosen by us: 0 = the first number, 4 = the second...
	oAccessor.Write(0,21)
	oAccessor.Write(8,3.5)
	? "1. the parent wrote the int 21 at position 0 and the double 3.5 at position 8"

	# 3. Text: a stream on the memory (CreateViewStream) works with StreamWriter and StreamReader like a file does. The text starts at 100.
	#    (The memory is zero-filled, so a reader sees the text and then zeros: the reading side cuts the text at the first zero byte.)
	oStream = oMap.CreateViewStream([ :offset = 100, :size = 200 ])
	oWriter = new StreamWriter(oStream)
	oWriter.Write("Hello from the parent")
	oWriter.Flush()
	oStream.Dispose()
	? "2. the parent wrote a text at position 100"

	# 4. Start the child and read what it prints. It finds the memory by its name, reads the numbers and the text, and answers in the same memory.
	oInfo = new ProcessStartInfo().New_([ :fileName = exefilename(), :arguments = '"' + filename() + '" --child' ])
	oInfo {
		UseShellExecute = False
		CreateNoWindow = True
		RedirectStandardOutput = True
	}
	oChild = new Process().Start(oInfo)
	cOutput = oChild.StandardOutput.ReadToEnd()
	oChild.WaitForExit(NULL)
	? nl + "3. the child says:"
	? "   " + substr(chomp(cOutput),char(10),nl + "   ")

	# 5. The answer of the child is in the same memory: read it from the positions that were agreed
	? nl + "4. the answer of the child at position 4 (21 * 2): " + oAccessor.ReadInt32(4)
	oAnswer = oMap.CreateViewStream([ :offset = 300, :size = 200 ])
	cAnswer = textOf(new StreamReader(oAnswer).ReadLine())
	? "   the text of the child at position 300: " + cAnswer
	oAccessor.Dispose()
	oMap.Dispose()

func runChild
	oMap = new MemoryMappedFile().OpenExisting(C_NAME)      # open: the parent made it
	oAccessor = oMap.CreateViewAccessor(NULL)
	nNumber = oAccessor.ReadInt32(0)
	nDecimal = oAccessor.ReadDouble(8)
	oStream = oMap.CreateViewStream([ :offset = 100, :size = 200 ])
	cText = textOf(new StreamReader(oStream).ReadLine())
	? "I read the int " + nNumber + ", the double " + nDecimal
	? "and the text '" + cText + "'"
	oAccessor.Write(4,nNumber * 2)
	oAnswer = oMap.CreateViewStream([ :offset = 300, :size = 200 ])
	oWriter = new StreamWriter(oAnswer)
	oWriter.Write("Hello from the child")
	oWriter.Flush()

# ---------------------------------------------------------------- a file edited in place

func editFileInPlace
	# 6. Map a FILE: the view is the content of the file, and a change in memory is a change in the file. Nothing is read or written
	#    by you: the system moves the data. The program changes the second of three numbers in a file without touching the others.
	cFile = new Path().Combine([new Path().GetTempPath(),"tutorial82.bin"])
	oConverter = new BitConverter()
	new File().WriteAllBytes(cFile,oConverter.GetBytes(10) + oConverter.GetBytes(20) + oConverter.GetBytes(30))
	oMap = new MemoryMappedFile().CreateFromFile(cFile)
	oAccessor = oMap.CreateViewAccessor(NULL)
	nOld = oAccessor.ReadInt32(4)
	oAccessor.Write(4,99)
	oAccessor.Flush()
	oAccessor.Dispose()
	oMap.Dispose()
	cBytes = new File().ReadAllBytes(cFile)
	? nl + "5. a file of " + len(cBytes) + " bytes: the second number was " + nOld + ", now it is " + oConverter.ToInt32(cBytes,4) + "; the first is " + oConverter.ToInt32(cBytes,0) + " and the third " + oConverter.ToInt32(cBytes,8)
	new File().Delete(cFile)

# the memory is filled with zero bytes: a text ends at the first one
func textOf cText
	nZero = substr(cText,char(0))
	if nZero > 0
		return left(cText,nZero - 1)
	ok
	return cText

func chomp cText
	while right(cText,1) = char(10) or right(cText,1) = char(13)
		cText = left(cText,len(cText) - 1)
	end
	return cText
