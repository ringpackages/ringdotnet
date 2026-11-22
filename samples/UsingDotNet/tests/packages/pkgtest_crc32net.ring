# Crc32.NET: CRC-32 and CRC-32C checksums as numbers (a uint) and as a HashAlgorithm object; the standard check values
load "pkg.ring"
pkgUse("crc32net",[["Crc32.NET","1.2.0"]],[["Crc32.NET.dll",["Force.Crc32"]]])
pkgImport("crc32net","Crc32.NET.dll","Force.Crc32")

dnAssert("CRC-32 check value 0xCBF43926",dnStatic("Force.Crc32.Crc32Algorithm","Compute",["123456789"]),3421780262)
dnAssert("CRC-32C check value 0xE3069283",dnStatic("Force.Crc32.Crc32CAlgorithm","Compute",["123456789"]),3808858755)
dnAssert("the CRC of nothing",dnStatic("Force.Crc32.Crc32Algorithm","Compute",[""]),0)

# a CRC that continues from the CRC of the first part
nFirst = dnStatic("Force.Crc32.Crc32Algorithm","Compute",["12345"])
nAll = dnStatic("Force.Crc32.Crc32Algorithm","Append",[nFirst,"6789"])
dnAssert("a CRC appended in parts",nAll,3421780262)

oHash = new Crc32Algorithm()
cHash = oHash.ComputeHash("123456789")
dnAssert("the hash is four bytes",len(cHash),4)

cBytes = ""
for i = 0 to 255
	cBytes += char(i)
next
dnAssert("a CRC of all byte values",dnStatic("Force.Crc32.Crc32Algorithm","Compute",[cBytes]),688229491)

dnTestSummary()
