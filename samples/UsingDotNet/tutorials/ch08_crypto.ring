# protecting and signing messages - AES, HMAC (encrypt-then-MAC), a password-derived key and RSA signatures
load "dotnet.ring"
using {
	"System"
	"System.Text"
	"System.Security.Cryptography"
}

func main
	oRandom = new RandomNumberGenerator()

	# 1. A key from a password: PBKDF2 stretches it (many rounds, a random salt) into as many bytes as we ask for.
	#    64 bytes: the first 32 are the AES key, the last 32 the HMAC key (never use one key for two jobs).
	cSalt = oRandom.GetBytes(16)
	cKeys = deriveKeys("correct horse battery staple",cSalt)
	cEncryptionKey = left(cKeys,32)
	cMacKey = right(cKeys,32)
	? "1. keys derived from the password: " + len(cEncryptionKey) + " + " + len(cMacKey) + " bytes"

	# 2. Encrypt: a fresh random IV for every message, AES in CBC mode, then an HMAC over IV + ciphertext (encrypt-then-MAC)
	cMessage = "Transfer 100 to account 4521"
	cPackage = protect(cMessage,cEncryptionKey,cMacKey)
	? nl + "2. the message has " + len(cMessage) + " bytes, the protected package " + len(cPackage) + " bytes (16 IV + padded ciphertext + 32 tag)"
	? "   the plain text is not in the package: " + yesNo(substr(cPackage,"Transfer") = 0)

	# 3. Open it: check the tag FIRST; only a package that passes is decrypted
	aResult = unprotect(cPackage,cEncryptionKey,cMacKey)
	? nl + "3. opened: " + aResult[1] + " -> " + aResult[2]

	# 4. Tampering: change one byte of the package. The tag no longer fits and the package is refused, nothing is decrypted.
	cBad = left(cPackage,20) + char((ascii(cPackage[21]) + 1) % 256) + right(cPackage,len(cPackage) - 21)
	aBad = unprotect(cBad,cEncryptionKey,cMacKey)
	? nl + "4. one changed byte: " + aBad[1] + " (" + aBad[2] + ")"

	# 5. The same message twice gives different packages: the IV is random, so an observer cannot see that a message repeats
	? nl + "5. two protections of one message are equal: " + yesNo(protect(cMessage,cEncryptionKey,cMacKey) = cPackage)

	# 6. A digital signature: RSA. The PRIVATE key signs; the PUBLIC key (which anyone may have) verifies who wrote it and that it is unchanged.
	oSigner = new RSA().Create(2048)
	cPublicKey = oSigner.ToXmlString(False)                  # False: the public part only
	oHash = new HashAlgorithmName().SHA256
	oPadding = new RSASignaturePadding().Pkcs1
	cOrder = "Pay 100 to Ann"
	cSignature = oSigner.SignData([ :data = cOrder, :hashAlgorithm = oHash, :padding = oPadding ])
	oVerifier = new RSA().Create(NULL)
	oVerifier.FromXmlString(cPublicKey)
	? nl + "6. the signature has " + len(cSignature) + " bytes (a 2048-bit key)"
	? "   verified with the public key: " + yesNo(oVerifier.VerifyData([ :data = cOrder, :signature = cSignature, :hashAlgorithm = oHash, :padding = oPadding ]))
	? "   the order was changed to 'Pay 900 to Ann': " + yesNo(oVerifier.VerifyData([ :data = "Pay 900 to Ann", :signature = cSignature, :hashAlgorithm = oHash, :padding = oPadding ]))

# the keys of a password: PBKDF2 with SHA-256, 100000 rounds, nBytes long
func deriveKeys cPassword, cSalt
	oDerive = dnNew("Rfc2898DeriveBytes",[ :password = cPassword, :salt = cSalt, :iterations = 100000, :hashAlgorithm = new HashAlgorithmName().SHA256 ])
	cKeys = oDerive.GetBytes(64)
	oDerive.Dispose()
	return cKeys

# IV + AES-CBC(message) + HMAC-SHA256(IV + ciphertext)
func protect cMessage, cEncryptionKey, cMacKey
	oAes = new Aes().Create(NULL)
	oAes.Key = cEncryptionKey
	cIv = new RandomNumberGenerator().GetBytes(16)
	oAes.IV = cIv
	oEncryptor = oAes.CreateEncryptor(NULL)
	cCipher = oEncryptor.TransformFinalBlock(cMessage,0,len(cMessage))
	oEncryptor.Dispose()
	oAes.Dispose()
	cBody = cIv + cCipher
	return cBody + tagOf(cBody,cMacKey)

# returns [status, text]: "ok" and the message, or "refused" and the reason
func unprotect cPackage, cEncryptionKey, cMacKey
	if len(cPackage) < 16 + 16 + 32
		return ["refused","too short"]
	ok
	cBody = left(cPackage,len(cPackage) - 32)
	cTag = right(cPackage,32)
	if not sameBytes(cTag,tagOf(cBody,cMacKey))
		return ["refused","the tag does not match: changed or wrong key"]
	ok
	oAes = new Aes().Create(NULL)
	oAes.Key = cEncryptionKey
	oAes.IV = left(cBody,16)
	oDecryptor = oAes.CreateDecryptor(NULL)
	cCipher = right(cBody,len(cBody) - 16)
	cPlain = oDecryptor.TransformFinalBlock(cCipher,0,len(cCipher))
	oDecryptor.Dispose()
	oAes.Dispose()
	return ["ok",cPlain]

func tagOf cBody, cMacKey
	oHmac = new HMACSHA256().@New([ :key = cMacKey ])
	cTag = oHmac.ComputeHash(cBody)
	oHmac.Dispose()
	return cTag

# compare without stopping at the first difference (the time must not tell how many bytes were equal)
func sameBytes cA, cB
	if len(cA) != len(cB)
		return False
	ok
	nDifference = 0
	for nIndex = 1 to len(cA)
		nDifference = nDifference | (ascii(cA[nIndex]) ^ ascii(cB[nIndex]))
	next
	return nDifference = 0

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
