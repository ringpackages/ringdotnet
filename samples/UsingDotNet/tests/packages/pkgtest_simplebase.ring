# SimpleBase: Base16, Base32 and Base58 encodings (static encoder objects, byte arrays and text), round trips, known values
load "pkg.ring"
pkgUse("simplebase",[["SimpleBase","4.0.2"]],[["SimpleBase.dll",["SimpleBase"]]])
pkgImport("simplebase","SimpleBase.dll","SimpleBase")

oBitcoin = dnStatic("SimpleBase.Base58","Bitcoin",[])
dnAssert("Base58 of Hello",oBitcoin.Encode("Hello"),"9Ajdvzr")
dnAssert("Base58 back to bytes",oBitcoin.Decode("9Ajdvzr"),"Hello")

oRfc = dnStatic("SimpleBase.Base32","Rfc4648",[])
dnAssert("Base32 of foobar",oRfc.callMethod("Encode",["foobar"]),"MZXW6YTBOI")
dnAssert("Base32 back to bytes",oRfc.callMethod("Decode",["MZXW6YTBOI"]),"foobar")

oUpper = dnStatic("SimpleBase.Base16","UpperCase",[])
dnAssert("Base16 of foo",oUpper.callMethod("Encode",["foo"]),"666F6F")
dnAssert("Base16 back to bytes",oUpper.callMethod("Decode",["666F6F"]),"foo")

# every byte value round trips through each encoding
cBytes = ""
for i = 0 to 255
	cBytes += char(i)
next
dnAssert("Base58 keeps every byte value",oBitcoin.Decode(oBitcoin.Encode(cBytes)),cBytes)
dnAssert("Base32 keeps every byte value",oRfc.callMethod("Decode",[oRfc.callMethod("Encode",[cBytes])]),cBytes)
dnAssert("Base16 keeps every byte value",oUpper.callMethod("Decode",[oUpper.callMethod("Encode",[cBytes])]),cBytes)

# a text that is not Base58 is an error
cError = ""
try
	oBitcoin.Decode("0OIl")
catch
	cError = cCatchError
done
dnAssert("a wrong character raises an error",len(cError) > 0,1)

dnTestSummary()
