# tar archives - make a .tar from a folder, list it, read one file from it and unpack it (System.Formats.Tar)
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Formats.Tar"
}

func main
	oPath = new Path()
	cBase = oPath.Combine([oPath.GetTempPath(),"ringdotnet_tutorial96"])
	cSource = oPath.Combine([cBase,"source"])
	cTar = oPath.Combine([cBase,"backup.tar"])
	cTarget = oPath.Combine([cBase,"unpacked"])
	oDirectory = new Directory()
	oFile = new File()
	if oDirectory.Exists(cBase)
		oDirectory.Delete([ :path = cBase, :recursive = True ])
	ok
	oDirectory.CreateDirectory(oPath.Combine([cSource,"notes"]))
	oFile.WriteAllText([ :path = oPath.Combine([cSource,"readme.txt"]), :contents = "Read me first" ])
	oFile.WriteAllText([ :path = oPath.Combine([cSource,"notes","a.txt"]), :contents = "Note A" ])
	oFile.WriteAllText([ :path = oPath.Combine([cSource,"notes","b.txt"]), :contents = "Note B, a little longer" ])

	# 1. Tar puts files and folders into ONE file (it does not compress: that is what gzip does, see the tutorial "Compression"). It is the usual
	#    format for packing a folder on Linux and macOS, and Docker images are tar files too.
	new TarFile().CreateFromDirectory(cSource,cTar,False)      # (source folder, tar file, include the folder itself)
	? "1. the tar file exists: " + oFile.Exists(cTar) + ", size is a multiple of 512 bytes: " + (new FileInfo(cTar).Length % 512 = 0)

	# 2. List what is inside: a TarReader gives the entries one after the other (GetNextEntry answers null at the end)
	oStream = new FileStream(cTar,"Open")
	oReader = new TarReader(oStream)
	aLines = []
	while true
		oEntry = oReader.GetNextEntry(NULL)
		if oEntry.isNull() exit ok
		aLines + (padRight(oEntry.EntryType,16) + padRight(oEntry.Name,18) + oEntry.Length + " bytes")
	end
	? nl + "2. " + len(aLines) + " entries (sorted here, because the order in a tar file is the order of the folder):"
	for cLine in sort(aLines)
		? "   " + cLine
	next
	oReader.Dispose()
	oStream.Dispose()

	# 3. Read one file from the archive without unpacking the others: look at each entry and read the data of the one we want
	oStream = new FileStream(cTar,"Open")
	oReader = new TarReader(oStream)
	cFound = ""
	while true
		oEntry = oReader.GetNextEntry(NULL)
		if oEntry.isNull() exit ok
		if oEntry.Name = "notes/b.txt"
			cFound = new StreamReader(oEntry.DataStream).ReadToEnd()
			exit
		ok
	end
	oReader.Dispose()
	oStream.Dispose()
	? nl + "3. text of notes/b.txt: " + cFound

	# 4. Unpack everything into a folder (it must exist) and read a file from there
	oDirectory.CreateDirectory(cTarget)
	new TarFile().ExtractToDirectory(cTar,cTarget,True)      # (tar file, target folder, overwrite files)
	? nl + "4. unpacked: " + oFile.ReadAllText(oPath.Combine([cTarget,"readme.txt"])) + " / " + oFile.ReadAllText(oPath.Combine([cTarget,"notes","a.txt"]))

	oDirectory.Delete([ :path = cBase, :recursive = True ])

func padRight cText,nWidth
	return cText + copy(" ",nWidth - len(cText))
