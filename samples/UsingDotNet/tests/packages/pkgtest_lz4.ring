# K4os.Compression.LZ4: LZ4 blocks and frames; Span parameters take a byte string, the sizes are numbers, the filled buffers are in the answer
load "pkg.ring"
pkgUse("lz4",[["K4os.Compression.LZ4","1.3.8"],["K4os.Compression.LZ4.Streams","1.3.8"]],[["K4os.Compression.LZ4.dll",["K4os.Compression.LZ4"]],["K4os.Compression.LZ4.Streams.dll",["K4os.Compression.LZ4.Streams"]]])
pkgImport("lz4","K4os.Compression.LZ4.dll","K4os.Compression.LZ4")
pkgImport("lz4","K4os.Compression.LZ4.Streams.dll","K4os.Compression.LZ4.Streams")
dnImport("System.IO")

cOriginal = copy("ring and .NET ",100)

# the whole text in one step
cPacked = dnStatic("K4os.Compression.LZ4.LZ4Pickler","Pickle",[cOriginal])
dnAssert("the packed text is smaller",len(cPacked) < len(cOriginal) / 4,1)
cBack = dnStatic("K4os.Compression.LZ4.LZ4Pickler","Unpickle",[cPacked])
dnAssert("the text read back",cBack,cOriginal)

# a block with a given level (named arguments)
cHigh = dnStatic("K4os.Compression.LZ4.LZ4Pickler","Pickle",[cOriginal,dnStatic("K4os.Compression.LZ4.LZ4Level","L09_HC",[])])
dnAssert("a higher level also reads back",dnStatic("K4os.Compression.LZ4.LZ4Pickler","Unpickle",[cHigh]),cOriginal)

# the maximum size of the output of a block
nMax = dnStatic("K4os.Compression.LZ4.LZ4Codec","MaximumOutputSize",[1000])
dnAssert("the maximum output is more than the input",nMax > 1000,1)

# a frame in a stream
oPacked = new MemoryStream()
oFrame = dnRequest("callnamed",[dnType("K4os.Compression.LZ4.Streams.LZ4Stream"),"Encode",[ ["stream",oPacked], ["leaveOpen",1] ]])          # the stream stays open when the frame is closed
oFrame.Write(cOriginal,0,len(cOriginal))
oFrame.Dispose()
dnAssert("the frame is smaller",oPacked.Length < len(cOriginal) / 4,1)
oPacked2 = new MemoryStream().@New(oPacked.ToArray())
oDecoded = dnStatic("K4os.Compression.LZ4.Streams.LZ4Stream","Decode",[oPacked2])
dnAssert("the frame read back",dnNew("System.IO.StreamReader",[oDecoded]).ReadToEnd(),cOriginal)

dnTestSummary()
