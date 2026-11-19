# Binary data: a Ring text can hold any byte (a NUL, bytes that are not valid UTF-8), and a byte[] that .NET returns is such a text.
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Security.Cryptography"
}

# every byte value, and a text with a NUL and bytes that are not UTF-8 in the middle
cEvery = ""
for i = 0 to 255
	cEvery += char(i)
next
cOdd = "a" + char(0) + "b" + char(255) + char(254) + char(195) + char(40) + "z"
dnAssert("a Ring text keeps 256 bytes",len(cEvery),256)
dnAssert("a Ring text keeps a NUL",len(cOdd),8)

# a MemoryStream: write the bytes, read them back with ToArray
oStream = new MemoryStream()
oStream.Write(cEvery,0,len(cEvery))
dnAssert("MemoryStream length",oStream.Length,256)
dnAssert("MemoryStream.ToArray gives the same bytes",oStream.ToArray(),cEvery)
oStream.SetLength(0)
oStream.Write(cOdd,0,len(cOdd))
dnAssert("a NUL and invalid UTF-8 go through a stream",oStream.ToArray(),cOdd)
dnAssert("and all 8 bytes come back",len(oStream.ToArray()),8)

# a file
oFile = new File()
cFile = new Path().Combine([ new Path().GetTempPath(),"ringdotnet_binary_test.bin" ])
oFile.WriteAllBytes(cFile,cEvery)
dnAssert("a file of 256 bytes",new FileInfo(cFile).Length,256)
dnAssert("ReadAllBytes gives the same bytes",oFile.ReadAllBytes(cFile),cEvery)
oFile.WriteAllBytes(cFile,cOdd)
dnAssert("ReadAllBytes with a NUL in the middle",oFile.ReadAllBytes(cFile),cOdd)
dnAssert("and all 8 bytes come back from the file",len(oFile.ReadAllBytes(cFile)),8)
oFile.Delete(cFile)

# Base64 and hexadecimal round trips
cBase64 = dnStatic("System.Convert","ToBase64String",[ cEvery ])
dnAssert("Base64 of 256 bytes has 344 characters",len(cBase64),344)
dnAssert("Base64 starts like this",left(cBase64,20),"AAECAwQFBgcICQoLDA0O")
dnAssert("Base64 round trip",dnStatic("System.Convert","FromBase64String",[ cBase64 ]),cEvery)
dnAssert("hexadecimal round trip",new Convert().FromHexString(new Convert().ToHexString(cOdd)),cOdd)
dnAssert("hexadecimal of the odd bytes",new Convert().ToHexString(cOdd),"610062FFFEC3287A")

# a hash of bytes (the values were made with another program)
oHash = dnStatic("System.Security.Cryptography.SHA256","Create",[])
dnAssert("SHA-256 of all 256 bytes",new Convert().ToHexString(oHash.ComputeHash(cEvery)),"40AFF2E9D2D8922E47AFD4648E6967497158785FBD1DA870E7110266BF944880")
dnAssert("SHA-256 of bytes that are not UTF-8",new Convert().ToHexString(oHash.ComputeHash("a" + char(0) + "b" + char(255) + char(254) + char(195) + char(40) + "z")),"2375BA1EF1A990EDE1CA9BFF9FE91F96A53F1229B5B331BDF90983E9A8AC7A66")

# BitConverter: numbers as bytes (little endian)
oConverter = new BitConverter()
dnAssert("the bytes of 1000",oConverter.GetBytes(1000),char(232) + char(3) + char(0) + char(0))

# ---- a byte buffer that .NET fills (dnBuffer): Stream.Read writes into an array that Ring can read back
oBuffer = dnBuffer(300)
dnAssert("a buffer has the size that was asked",dnBufferSize(oBuffer),300)
oStream = new MemoryStream().New_([ :buffer = cEvery ])
nRead = oStream.Read(oBuffer,0,300)
dnAssert("Read gives the number of bytes",nRead,256)
dnAssert("the buffer has the bytes",dnBufferBytes(oBuffer,nRead),cEvery)
dnAssert("and all of them",len(dnBufferBytes(oBuffer,nRead)),256)

# reading in parts, with an offset
oStream = new MemoryStream().New_([ :buffer = cOdd ])
oPart = dnBuffer(16)
dnAssert("the first 3 bytes",oStream.Read(oPart,0,3),3)
dnAssert("they are there",dnBufferBytes(oPart,3),"a" + char(0) + "b")
dnAssert("the next 5 bytes, put at the place 3",oStream.Read(oPart,3,5),5)
dnAssert("8 bytes in the buffer",dnBufferBytes(oPart,8),cOdd)

# a buffer made from a text; the text is copied, the buffer is separate
oCopy = dnBuffer(cOdd)
dnAssert("a buffer made from a text",dnBufferBytes(oCopy,dnBufferSize(oCopy)),cOdd)
dnAssert("its size is the number of bytes",dnBufferSize(oCopy),8)

# a file stream
oFile.WriteAllBytes(cFile,cEvery)
oFileStream = dnNew("FileStream",[ :path = cFile, :mode = "Open" ])
oBig = dnBuffer(1000)
nFile = oFileStream.Read(oBig,0,1000)
oFileStream.Dispose()
oFile.Delete(cFile)
dnAssert("FileStream.Read",nFile,256)
dnAssert("FileStream.Read gives the bytes",dnBufferBytes(oBig,nFile),cEvery)

# a network stream: the bytes of a message cross a TCP connection
using { "System.Net" "System.Net.Sockets" }
oListener = new TcpListener(new IPAddress().Loopback,0)
oListener.Start(NULL)
oClient = new TcpClient().New_([ :hostname = "127.0.0.1", :port = oListener.LocalEndpoint.Port ])
oServerSide = oListener.AcceptTcpClient()
oClient.GetStream().Write(cOdd,0,len(cOdd))
oReceive = dnBuffer(64)
nGot = oServerSide.GetStream().Read(oReceive,0,64)
dnAssert("a TCP message: the number of bytes",nGot,8)
dnAssert("a TCP message: the bytes",dnBufferBytes(oReceive,nGot),cOdd)
oClient.Close()
oServerSide.Close()
oListener.Stop()

nFail = dnTestSummary()
