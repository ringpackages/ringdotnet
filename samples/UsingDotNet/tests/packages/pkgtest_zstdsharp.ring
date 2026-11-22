# ZstdSharp.Port: Zstandard with Compressor and Decompressor objects (Wrap and Unwrap take and return byte arrays) and levels
load "pkg.ring"
pkgUse("zstdsharp",[["ZstdSharp.Port","0.8.6"]],[["ZstdSharp.dll",["ZstdSharp"]]])
pkgImport("zstdsharp","ZstdSharp.dll","ZstdSharp")

cText = copy("Ring talks to .NET. ",500)
oCompressor = new Compressor().@New(3)
cPacked = oCompressor.callMethod("Wrap",[cText])
dnAssert("a repetitive text is much smaller",len(cPacked) < len(cText) / 10,1)

oDecompressor = new Decompressor()
dnAssert("and reads back",oDecompressor.callMethod("Unwrap",[cPacked]),cText)

oHigh = new Compressor().@New(19)
dnAssert("a higher level is not bigger",len(oHigh.callMethod("Wrap",[cText])) <= len(cPacked),1)

cBytes = ""
for i = 0 to 255
	cBytes += char(i)
next
cBinary = copy(cBytes,30)
dnAssert("every byte value round trips",oDecompressor.callMethod("Unwrap",[oCompressor.callMethod("Wrap",[cBinary])]),cBinary)

dnAssert("an empty input",oDecompressor.callMethod("Unwrap",[oCompressor.callMethod("Wrap",[""])]),"")

cError = ""
try
	oDecompressor.callMethod("Unwrap",["not zstd data"])
catch
	cError = cCatchError
done
dnAssert("bad data raises an error",len(cError) > 0,1)

oCompressor.Dispose()
oHigh.Dispose()
oDecompressor.Dispose()
dnTestSummary()
