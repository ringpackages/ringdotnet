# System.IO.Hashing: Crc32, XxHash32/64 over byte arrays and Spans; known check values
load "pkg.ring"
pkgUse("iohashing",[["System.IO.Hashing","9.0.0"]],[["System.IO.Hashing.dll",["System.IO.Hashing"]]])
pkgImport("iohashing","System.IO.Hashing.dll","System.IO.Hashing")

# CRC-32 of "123456789" is 0xCBF43926 (the standard check value)
cCrc = dnStatic("System.IO.Hashing.Crc32","Hash",["123456789"])
dnAssert("the CRC-32 check value",hexs(cCrc),"2639f4cb")
dnAssert("a CRC-32 is 4 bytes",len(cCrc),4)
dnAssert("the CRC-32 as a number",dnStatic("System.IO.Hashing.Crc32","HashToUInt32",["123456789"]),3421780262)

# the same data, the same hash; other data, other hash
dnAssert("XxHash64 is 8 bytes",len(dnStatic("System.IO.Hashing.XxHash64","Hash",["ring"])),8)
dnAssert("XxHash32 is 4 bytes",len(dnStatic("System.IO.Hashing.XxHash32","Hash",["ring"])),4)
dnAssert("a hash is determined",dnStatic("System.IO.Hashing.XxHash64","Hash",["ring"]) = dnStatic("System.IO.Hashing.XxHash64","Hash",["ring"]),1)
dnAssert("another text, another hash",dnStatic("System.IO.Hashing.XxHash64","Hash",["ring"]) != dnStatic("System.IO.Hashing.XxHash64","Hash",["ring2"]),1)

# XxHash3 of the empty input and an incremental hasher that is fed in parts
oHasher = new Crc32()
oHasher.Append("1234")
oHasher.Append("56789")
dnAssert("an incremental CRC-32 is the same as one call",oHasher.GetCurrentHash() = cCrc,1)
oHasher.Reset()
oHasher.Append("123456789")
dnAssert("after a reset",oHasher.GetHashAndReset() = cCrc,1)

dnTestSummary()

func hexs cBytes
	cOut = ""
	for i = 1 to len(cBytes)
		cOut += right("0" + hex(ascii(cBytes[i])),2)
	next
	return cOut
