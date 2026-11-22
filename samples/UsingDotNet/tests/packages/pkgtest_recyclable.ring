# Microsoft.IO.RecyclableMemoryStream: a manager and pooled memory streams; write, seek, read, length, the bytes
load "pkg.ring"
pkgUse("recyclable",[["Microsoft.IO.RecyclableMemoryStream","3.0.1"]],[["Microsoft.IO.RecyclableMemoryStream.dll",["Microsoft.IO"]]])
pkgImport("recyclable","Microsoft.IO.RecyclableMemoryStream.dll","Microsoft.IO")

oManager = new RecyclableMemoryStreamManager()
oStream = oManager.GetStream(NULL)
dnAssert("a new stream is empty",oStream.Length,0)

cData = ""
for i = 0 to 255
	cData += char(i)
next
oStream.Write(cData,0,256)
dnAssert("the length after a write",oStream.Length,256)
dnAssert("the position",oStream.Position,256)

oStream.Seek(0,dnStatic("System.IO.SeekOrigin","Begin",[]))
dnAssert("a seek",oStream.Position,0)
cBack = oStream.ToArray()
dnAssert("all 256 byte values",cBack = cData,1)

# a stream bigger than a block
oBig = oManager.GetStream(NULL)
cBlock = copy(cData,1000)
oBig.Write(cBlock,0,len(cBlock))
dnAssert("a big stream",oBig.Length,256000)
dnAssert("a big stream, read as a whole",oBig.ToArray() = cBlock,1)
oBig.Dispose()
oStream.Dispose()

dnTestSummary()
