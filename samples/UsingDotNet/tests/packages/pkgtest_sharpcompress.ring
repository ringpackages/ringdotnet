# SharpCompress: archives in memory (ZIP written with entries, then opened and read), the entries with their names and sizes
load "pkg.ring"
pkgUse("sharpcompress",[["SharpCompress","1.0.0"]],[["SharpCompress.dll",["SharpCompress.Archives","SharpCompress.Archives.Zip","SharpCompress.Common","SharpCompress.Writers","SharpCompress.Readers"]]])
pkgImport("sharpcompress","SharpCompress.dll","SharpCompress.Archives")
pkgImport("sharpcompress","SharpCompress.dll","SharpCompress.Archives.Zip")
pkgImport("sharpcompress","SharpCompress.dll","SharpCompress.Common")
pkgImport("sharpcompress","SharpCompress.dll","SharpCompress.Writers")
pkgImport("sharpcompress","SharpCompress.dll","SharpCompress.Readers")
dnImport("System.IO")

# a ZIP in memory with two entries
oArchive = dnStatic("SharpCompress.Archives.Zip.ZipArchive","Create",[])
for cName in ["hello.txt","docs/readme.txt"]
	cText = "content of " + cName
	oStream = new MemoryStream().@New(cText)
	oArchive.AddEntry([ :key = cName, :source = oStream, :closeStream = 1 ])
next
oMemory = new MemoryStream()
oArchive.SaveTo(oMemory)          # the options are optional: the default compression
dnAssert("the archive has bytes",oMemory.Length > 100,1)

# open it and read the entries
oMemory.Position = 0
oRead = dnStatic("SharpCompress.Archives.Zip.ZipArchive","Open",[oMemory])
dnAssert("two entries",len(oRead.Entries.toList()),2)
aEntries = oRead.Entries.toList()          # the entries are a collection: toList() makes a Ring list
oFirst = aEntries[1]
dnAssert("the name of an entry",oFirst.Key,"hello.txt")
dnAssert("the size of an entry",oFirst.Size,len("content of hello.txt"))
oReader = dnNew("System.IO.StreamReader",[oFirst.OpenEntryStream()])
dnAssert("the content of an entry",oReader.ReadToEnd(),"content of hello.txt")
dnAssert("an entry that is not a directory",oFirst.IsDirectory,0)
dnAssert("the archive type",oRead.Type,"Zip")

dnTestSummary()
