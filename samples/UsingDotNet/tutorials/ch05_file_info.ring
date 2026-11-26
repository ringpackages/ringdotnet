# file information - size, attributes, times, read-only files, temporary files and copying with File and FileInfo
load "dotnet.ring"

using {
	"System"
	"System.IO"
}

func main

	oFile = new File()
	oPath = new Path()
	oDirectory = new Directory()

	# A work folder with a random name; the program deletes it at the end. The names of the folders are not printed (they differ on each computer).
	cFolder = oPath.Combine([ oPath.GetTempPath(), "ringdotnet-info-" + oPath.GetRandomFileName() ])
	oDirectory.CreateDirectory(cFolder)
	cFile = cFolder + "/report.txt"
	oFile.WriteAllText([ :path = cFile, :contents = "Line one" + nl + "Line two" + nl ])

	# 1. FileInfo describes one file: the name, the extension, the size and the folder. It is made from a path and it does not open the file.
	oInfo = new FileInfo(cFile)
	? "1. name: " + oInfo.Name + ", extension: " + oInfo.Extension + ", exists: " + yesNo(oInfo.Exists)
	? "   name without extension: " + oPath.GetFileNameWithoutExtension(cFile) + ", size: " + oInfo.Length + " bytes"

	# 2. The times of a file: created, last written, last read. The program sets one to a known moment, so that the output is always the same.
	oMoment = new DateTime
	oMoment.@New([ :year = 2024, :month = 3, :day = 15, :hour = 9, :minute = 30, :second = 0 ])
	oFile.SetLastWriteTime(cFile,oMoment)
	oInfo.Refresh()                                        # FileInfo keeps what it read: Refresh reads it again
	? nl + "2. last written: " + oInfo.LastWriteTime.Format("yyyy-MM-dd HH:mm")
	? "   older than a day: " + yesNo(daysOld(oInfo) > 1)

	# 3. Attributes: a file can be read-only, hidden, and more. They are flags in one value (a text such as "ReadOnly, Archive").
	? nl + "3. attributes: " + oFile.GetAttributes(cFile)
	oFile.SetAttributes(cFile,"ReadOnly")
	? "   after SetAttributes: " + oFile.GetAttributes(cFile) + ", IsReadOnly: " + yesNo(new FileInfo(cFile).IsReadOnly)

	# 4. A read-only file is protected: writing to it raises an error. The program shows the message and then removes the flag.
	try
		oFile.WriteAllText([ :path = cFile, :contents = "new text" ])
		? nl + "4. the file was changed"
	catch
		? nl + "4. writing failed: " + errorKind(cCatchError)
	done
	oFile.SetAttributes(cFile,"Normal")
	oFile.WriteAllText([ :path = cFile, :contents = "new text" ])
	? "   after removing the flag: " + oFile.ReadAllText(cFile)

	# 5. Copy. Copy raises an error when the target exists, unless the overwrite value is True. A copy has its own times.
	cCopy = cFolder + "/copy.txt"
	oFile.Copy([ :sourceFileName = cFile, :destFileName = cCopy ])
	try
		oFile.Copy([ :sourceFileName = cFile, :destFileName = cCopy ])
	catch
		? nl + "5. second copy: " + errorKind(cCatchError)
	done
	oFile.Copy([ :sourceFileName = cFile, :destFileName = cCopy, :overwrite = True ])
	? "   with overwrite = True: ok, size " + new FileInfo(cCopy).Length + " bytes"

	# 6. Temporary files: GetTempFileName creates an empty file with a unique name in the folder for temporary files. The program that asked for
	#    it must delete it.
	cTemp = oPath.GetTempFileName()
	? nl + "6. a temporary file: exists " + yesNo(oFile.Exists(cTemp)) + ", size " + new FileInfo(cTemp).Length + " bytes"
	oFile.Delete(cTemp)
	? "   after Delete: exists " + yesNo(oFile.Exists(cTemp))

	# 7. The files of a folder with their sizes, from DirectoryInfo (the names are sorted so that the output is always the same)
	oFolder = new DirectoryInfo(cFolder)
	aNames = []
	aItems = oFolder.GetFiles(NULL).toList()
	for oItem in aItems
		aNames + (oItem.Name + " (" + oItem.Length + " bytes)")
	next
	? nl + "7. in the folder:"
	aSortedNames = sort(aNames)
	for cName in aSortedNames
		? "   " + cName
	next

	oDirectory.Delete([ :path = cFolder, :recursive = True ])

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"

# how many days ago the file was written
func daysOld oInfo

	oNow = dnStatic("System.DateTime","get_Now",[])
	oSpan = oNow.Subtract(oInfo.LastWriteTime)
	return oSpan.TotalDays

# the kind of an error: the name of the .NET exception ("System.IO.IOException"). The message of the exception also has the path of the
# file, which is different on each computer, so the program prints only the kind.
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
