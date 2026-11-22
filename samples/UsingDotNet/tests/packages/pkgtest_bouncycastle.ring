# Portable.BouncyCastle: digests (SHA-256 with its buffer filled by DoFinal), HMAC, hex, and AES in CBC mode with padding (byte strings are keys, IVs and data)
load "pkg.ring"
pkgUse("bouncycastle",[["Portable.BouncyCastle","1.9.0"]],[["BouncyCastle.Crypto.dll",["Org.BouncyCastle.Crypto.Digests","Org.BouncyCastle.Crypto.Macs","Org.BouncyCastle.Crypto.Parameters","Org.BouncyCastle.Crypto.Engines","Org.BouncyCastle.Crypto.Modes","Org.BouncyCastle.Crypto.Paddings","Org.BouncyCastle.Utilities.Encoders"]]])
for cNamespace in ["Org.BouncyCastle.Crypto.Digests","Org.BouncyCastle.Crypto.Macs","Org.BouncyCastle.Crypto.Parameters","Org.BouncyCastle.Crypto.Engines","Org.BouncyCastle.Crypto.Modes","Org.BouncyCastle.Crypto.Paddings","Org.BouncyCastle.Utilities.Encoders"]
	pkgImport("bouncycastle","BouncyCastle.Crypto.dll",cNamespace)
next

# SHA-256 of a text: update with the bytes, then DoFinal writes the hash into a buffer
oSha = new Sha256Digest()
dnAssert("the size of the digest",oSha.GetDigestSize(),32)
cData = "abc"
oSha.BlockUpdate(cData,0,len(cData))
oBuffer = dnBuffer(32)
oSha.DoFinal(oBuffer,0)
cHex = dnStatic("Org.BouncyCastle.Utilities.Encoders.Hex","ToHexString",[dnBufferBytes(oBuffer,32)])
dnAssert("SHA-256 of abc",cHex,"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
dnAssert("the name of the algorithm",oSha.AlgorithmName,"SHA-256")

# the hex encoding both ways
cRaw = dnStatic("Org.BouncyCastle.Utilities.Encoders.Hex","Decode",["48656c6c6f"])
dnAssert("hex to bytes",cRaw,"Hello")
dnAssert("bytes to hex",dnStatic("Org.BouncyCastle.Utilities.Encoders.Hex","ToHexString",["Hello"]),"48656c6c6f")

# HMAC-SHA256
oHmacDigest = new Sha256Digest()
oHmac = new MacsHMac(oHmacDigest)          # the class is named MacsHMac: Ring names are not case sensitive, and System.Security.Cryptography has an HMAC
oMacKey = new KeyParameter("secret key")
oHmac.@Init(oMacKey)
oHmac.BlockUpdate("message",0,7)
oMac = dnBuffer(32)
oHmac.DoFinal(oMac,0)
dnAssert("an HMAC has 32 bytes",oHmac.GetMacSize(),32)
dnAssert("an HMAC of the same input is the same",len(dnBufferBytes(oMac,32)),32)

# AES-CBC with PKCS7 padding: encrypt a text and decrypt it (the objects are made in variables first: a new inside the arguments of another new is not given a .NET object)
cKey = copy("k",16)
cIv = copy("i",16)
cText = "a text that is longer than one block of sixteen bytes"
oAes = new AesEngine()
oCbc = new CbcBlockCipher(oAes)
oCipher = new PaddedBufferedBlockCipher(oCbc)
oKey = new KeyParameter(cKey)
oParams = new ParametersWithIV(oKey,cIv)
oCipher.@Init(1,oParams)
cEncrypted = oCipher.DoFinal(cText)
dnAssert("the encrypted data is a whole number of blocks",len(cEncrypted) % 16,0)
dnAssert("and not the text",cEncrypted != cText,1)
oAes2 = new AesEngine()
oCbc2 = new CbcBlockCipher(oAes2)
oCipher2 = new PaddedBufferedBlockCipher(oCbc2)
oCipher2.@Init(0,oParams)
dnAssert("decrypted",oCipher2.DoFinal(cEncrypted),cText)

dnTestSummary()
