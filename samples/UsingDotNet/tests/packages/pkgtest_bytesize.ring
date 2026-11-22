# ByteSize: a struct with operators, unit conversions, parsing and text
load "pkg.ring"
pkgUse("bytesize",[["ByteSize","2.1.2"]],[["ByteSize.dll",["ByteSizeLib"]]])
pkgImport("bytesize","ByteSize.dll","ByteSizeLib")

oMega = dnStatic("ByteSizeLib.ByteSize","FromMegabytes",[1.5])
dnAssert("megabytes to bytes (decimal units)",oMega.Bytes,1500000)
dnAssert("megabytes to kilobytes",oMega.KiloBytes,1500)
dnAssert("megabytes",oMega.MegaBytes,1.5)
dnAssert("a text",oMega.ToString(),"1.5 MB")

oGiga = dnStatic("ByteSizeLib.ByteSize","FromGigabytes",[2])
dnAssert("gigabytes in megabytes",oGiga.MegaBytes,2000)
dnAssert("a bigger value compares",oGiga > oMega,1)

oSum = oMega + oGiga
dnAssert("a sum",oSum.MegaBytes,2001.5)
oDiff = oGiga - oMega
dnAssert("a difference",oDiff.MegaBytes,1998.5)

oParsed = dnStatic("ByteSizeLib.ByteSize","Parse",["10 KB"])
dnAssert("parse",oParsed.Bytes,10000)
dnAssert("the largest unit",oParsed.LargestWholeNumberDecimalSymbol,"KB")

dnAssert("TryParse of a bad text",dnStatic("ByteSizeLib.ByteSize","TryParse",["xyz"]) != 1,1)

dnTestSummary()
