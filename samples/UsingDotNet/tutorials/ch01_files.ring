# files and folders - Path, Directory, File, reading and writing, zip
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.IO.Compression"
}

func main
	oPath = new Path()
	oFile = new File()
	oDirectory = new Directory()

	# Never build paths by joining text: Path.Combine uses the right separator
	cFolder = oPath.Combine([oPath.GetTempPath(),"ringdotnet_files"])
	if oDirectory.Exists(cFolder)
		oDirectory.Delete([ :path = cFolder, :recursive = True ])
	ok
	oDirectory.CreateDirectory(cFolder)
	? "Folder created     : " + oDirectory.Exists(cFolder)

	# Write a text file and read it back
	cNotes = oPath.Combine([cFolder,"notes.txt"])
	oFile.WriteAllText([ :path = cNotes, :contents = "first line" + windowsnl() + "second line" + windowsnl() + "third line" ])
	? "File exists        : " + oFile.Exists(cNotes)
	? "All the text       : " + len(oFile.ReadAllText(cNotes)) + " characters"
	aLines = oFile.ReadAllLines(cNotes).toList()
	? "Lines              : " + len(aLines) + ", the last is '" + aLines[len(aLines)] + "'"

	# Append without erasing
	oFile.AppendAllText([ :path = cNotes, :contents = windowsnl() + "fourth line" ])
	? "After appending    : " + len(oFile.ReadAllLines(cNotes).toList()) + " lines"

	# Read a big file line by line with a reader
	oReader = new StreamReader(cNotes)
	nCount = 0
	while not oReader.EndOfStream
		oReader.ReadLine()
		nCount++
	end
	oReader.Close()
	? "Counted with reader: " + nCount

	# Information about a file
	oInfo = new FileInfo(cNotes)
	? "Name and size      : " + oInfo.Name + ", " + oInfo.Length + " bytes"
	? "Extension          : " + oPath.GetExtension(cNotes)
	? "File name only     : " + oPath.GetFileNameWithoutExtension(cNotes)

	# Copy a file and list the folder
	oFile.Copy([ :sourceFileName = cNotes, :destFileName = oPath.Combine([cFolder,"copy.txt"]) ])
	? "Files in the folder: " + len(oDirectory.GetFiles(cFolder).toList())

	# Zip a folder and unzip it somewhere else
	cZip = oPath.Combine([oPath.GetTempPath(),"ringdotnet_files.zip"])
	if oFile.Exists(cZip)
		oFile.Delete(cZip)
	ok
	new ZipFile().CreateFromDirectory([ :sourceDirectoryName = cFolder, :destinationArchiveFileName = cZip ])
	? "Zip size           : " + new FileInfo(cZip).Length + " bytes"
	oFile.Delete(cZip)

	# Clean up
	oDirectory.Delete([ :path = cFolder, :recursive = True ])
	? "Cleaned up         : " + (not oDirectory.Exists(cFolder))
