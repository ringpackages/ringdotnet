# Tutorial 8: hashing and encryption basics - checksums, password hashes, random tokens, AES
load "dotnetlib.ring"
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

	# Never store a password: store a salted slow hash (PBKDF2) of it
	cPassword = "correct horse battery staple"
	oSalt = new RandomNumberGenerator().GetBytes(16)
	cHash = hashPassword(cPassword,oSalt)
	? nl + "Stored hash       : " + left(cHash,32) + "... (" + len(cHash) + " characters)"
	? "Right password    : " + (hashPassword(cPassword,oSalt) = cHash)
	? "Wrong password    : " + (hashPassword("wrong",oSalt) = cHash)

	# HMAC: a hash with a secret key proves that a message was not changed
	oHmac = dnNew("HMACSHA256",[ :key = "secret key" ])
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

# PBKDF2: many rounds make guessing slow
func hashPassword cPassword, cSalt
	oDerive = dnNew("Rfc2898DeriveBytes",[ :password = cPassword, :salt = cSalt, :iterations = 10000, :hashAlgorithm = new HashAlgorithmName().SHA256 ])
	return lower(new Convert().ToHexString(oDerive.GetBytes(32)))
