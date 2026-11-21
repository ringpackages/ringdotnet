# hashing and encryption basics - checksums, HMAC, random tokens, AES
load "dotnet.ring"
using {
	"System"
	"System.Security.Cryptography"
	"System.Text"
}

func main
	oConvert = new Convert()

	# A hash is a fingerprint of data: the same input always gives the same hash, you can not go back
	? "SHA-256 of 'abc'   : " + lower(oConvert.ToHexString(new SHA256().HashData("abc")))
	? "MD5 of 'abc'       : " + lower(oConvert.ToHexString(new MD5().HashData("abc"))) + "  (old: do not use it for security)"
	? "Changing one letter: " + left(lower(oConvert.ToHexString(new SHA256().HashData("abd"))),16) + "... is completely different"

	# HMAC: a hash with a secret key proves that a message was not changed
	oHmac = new HMACSHA256().@New([ :key = "secret key" ])          # the constructor that takes the key
	? nl + "HMAC             : " + left(lower(oConvert.ToHexString(oHmac.ComputeHash("message"))),32) + "..."

	# Random bytes for tokens: use RandomNumberGenerator, not Random
	? "Random token      : " + lower(oConvert.ToHexString(new RandomNumberGenerator().GetBytes(8)))

	# AES: encrypt and decrypt a text with a key
	oAes = new Aes().Create(NULL)
	oAes.GenerateKey()
	oAes.GenerateIV()
	cText = "Ring talks to .NET crypto"
	cCipher = oAes.CreateEncryptor(NULL).TransformFinalBlock(cText,0,len(cText))
	? nl + "Encrypted        : " + len(cCipher) + " bytes (the text had " + len(cText) + ")"
	? "Decrypted        : " + oAes.CreateDecryptor(NULL).TransformFinalBlock(cCipher,0,len(cCipher))
