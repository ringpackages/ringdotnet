# Snappier: Snappy compression of byte arrays through spans (static methods that take a ReadOnlySpan<byte> and return a byte array)
load "pkg.ring"
pkgUse("snappier",[["Snappier","1.1.6"]],[["Snappier.dll",["Snappier"]]])
pkgImport("snappier","Snappier.dll","Snappier")

cText = copy("Ring and .NET together. ",200)
cPacked = dnStatic("Snappier.Snappy","CompressToArray",[cText])
dnAssert("a repetitive text is smaller",len(cPacked) < len(cText) / 4,1)
dnAssert("and reads back",dnStatic("Snappier.Snappy","DecompressToArray",[cPacked]),cText)

cBytes = ""
for i = 0 to 255
	cBytes += char(i)
next
cBinary = copy(cBytes,20)
dnAssert("every byte value round trips",dnStatic("Snappier.Snappy","DecompressToArray",[dnStatic("Snappier.Snappy","CompressToArray",[cBinary])]),cBinary)

dnAssert("the length of the uncompressed data",dnStatic("Snappier.Snappy","GetUncompressedLength",[cPacked]),len(cText))
dnAssert("an empty input",dnStatic("Snappier.Snappy","DecompressToArray",[dnStatic("Snappier.Snappy","CompressToArray",[""])]),"")

cArabic = copy("مرحبا بالعالم ",100)
dnAssert("Arabic text round trips",dnStatic("Snappier.Snappy","DecompressToArray",[dnStatic("Snappier.Snappy","CompressToArray",[cArabic])]),cArabic)

cError = ""
try
	dnStatic("Snappier.Snappy","DecompressToArray",["this is not snappy data at all"])
catch
	cError = cCatchError
done
dnAssert("bad data raises an error",len(cError) > 0,1)

dnTestSummary()
