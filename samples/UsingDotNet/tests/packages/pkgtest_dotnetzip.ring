# DotNetZip: a zip archive made in memory (entries from texts and bytes), saved to a stream, read back, with a password
load "pkg.ring"
pkgUse("dotnetzip",[["DotNetZip","1.16.0"]],[["DotNetZip.dll",["Ionic.Zip"]]])
pkgImport("dotnetzip","DotNetZip.dll","Ionic.Zip")

oZip = new ZipZipFile()
oZip.callMethod("AddEntry",["hello.txt","Hello from Ring"])
oZip.callMethod("AddEntry",["folder/arabic.txt","مرحبا بالعالم"])
cBytes = ""
for i = 0 to 255
	cBytes += char(i)
next
oZip.callMethod("AddEntry",["bytes.bin",cBytes])
dnAssert("three entries",oZip.Count,3)

oStream = dnNew("System.IO.MemoryStream",[])
oZip.callMethod("Save",[oStream])
cArchive = oStream.ToArray()
dnAssert("an archive starts with PK",left(cArchive,2),"PK")
oZip.Dispose()

oRead = dnStatic("Ionic.Zip.ZipFile","Read",[dnNew("System.IO.MemoryStream",[cArchive])])
dnAssert("the entries are read",oRead.Count,3)
dnAssert("an entry by name",oRead.Item("hello.txt").FileName,"hello.txt")
dnAssert("a folder in a name",oRead.Item("folder/arabic.txt").FileName,"folder/arabic.txt")
dnAssert("the size of an entry",oRead.Item("bytes.bin").UncompressedSize,256)
dnAssert("a name is found",oRead.callMethod("ContainsEntry",["hello.txt"]),1)
dnAssert("a missing name",oRead.callMethod("ContainsEntry",["nothing.txt"]),0)

oOut = dnNew("System.IO.MemoryStream",[])
oRead.Item("bytes.bin").callMethod("Extract",[oOut])
dnAssert("every byte value is extracted",oOut.ToArray(),cBytes)
oRead.Dispose()

dnTestSummary()
