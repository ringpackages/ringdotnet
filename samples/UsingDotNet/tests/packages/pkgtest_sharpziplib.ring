# SharpZipLib: a ZIP archive in memory (entries written and read back), GZip of a text, and Tar
load "pkg.ring"
pkgUse("sharpziplib",[["SharpZipLib","1.4.2"]],[["ICSharpCode.SharpZipLib.dll",["ICSharpCode.SharpZipLib.Zip","ICSharpCode.SharpZipLib.GZip"]]])
pkgImport("sharpziplib","ICSharpCode.SharpZipLib.dll","ICSharpCode.SharpZipLib.Zip")
pkgImport("sharpziplib","ICSharpCode.SharpZipLib.dll","ICSharpCode.SharpZipLib.GZip")
dnImport("System.IO")

# a ZIP in memory: two entries
oMemory = new MemoryStream()
oZip = dnNew("ICSharpCode.SharpZipLib.Zip.ZipOutputStream",[oMemory])
oZip.IsStreamOwner = 0
oZip.SetLevel(9)
for cName in ["hello.txt","docs/readme.txt"]
	oEntry = dnNew("ICSharpCode.SharpZipLib.Zip.ZipEntry",[cName])
	oZip.PutNextEntry(oEntry)
	cText = "content of " + cName
	oZip.Write(cText,0,len(cText))
	oZip.CloseEntry()
next
oZip.Finish()
oZip.Close()
dnAssert("the archive has bytes",oMemory.Length > 100,1)

# read it back
oMemory.Position = 0
oFile = dnNew("ICSharpCode.SharpZipLib.Zip.ZipFile",[oMemory])
dnAssert("two entries",oFile.Count,2)
oFirst = oFile.GetEntry("docs/readme.txt")
dnAssert("an entry by name",oFirst.Name,"docs/readme.txt")
dnAssert("the size of an entry",oFirst.Size,len("content of docs/readme.txt"))
oStream = oFile.GetInputStream(oFirst)
oReader = dnNew("System.IO.StreamReader",[oStream])
dnAssert("the content of an entry",oReader.ReadToEnd(),"content of docs/readme.txt")
dnAssert("a missing entry is null",oFile.GetEntry("nothing.txt").isNull(),1)
oFile.Close()

# GZip: compress a text and read it back
cOriginal = copy("ring ",200)
oPacked = new MemoryStream()
oGzip = dnNew("ICSharpCode.SharpZipLib.GZip.GZipOutputStream",[oPacked])
oGzip.IsStreamOwner = 0
oGzip.Write(cOriginal,0,len(cOriginal))
oGzip.Close()
dnAssert("the packed text is smaller",oPacked.Length < len(cOriginal) / 4,1)
oPacked.Position = 0
oUnpack = dnNew("ICSharpCode.SharpZipLib.GZip.GZipInputStream",[oPacked])
dnAssert("the text read back",dnNew("System.IO.StreamReader",[oUnpack]).ReadToEnd(),cOriginal)

dnTestSummary()
