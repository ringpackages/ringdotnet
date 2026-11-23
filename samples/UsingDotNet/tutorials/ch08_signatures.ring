# digital signatures - ECDsa keys, signing a message, verifying it, and what happens when the message or the key changes
load "dotnet.ring"

using {
	"System"
	"System.Security.Cryptography"
	"System.Text"
}

func main

	oUtf8 = new UTF8Encoding()

	# A digital signature proves two things about a message: who sent it (only the owner of the PRIVATE key can make the signature) and
	# that it was not changed (the signature fits only this exact message). Everybody with the PUBLIC key can check it.
	# ECDsa uses elliptic curves: small keys and fast signatures. (the tutorial "Protecting and signing messages" used RSA and hashes)
	oCurve = new ECCurve().CreateFromFriendlyName("nistP256")          # a named curve
	oKey = new ECDsa().Create(oCurve)
	? "1. a key pair was made on the curve nistP256, key size " + oKey.KeySize + " bits"

	# 2. Sign a message: the data is hashed (SHA-256) and the hash is signed. The signature of ECDsa has 64 bytes for this curve.
	cMessage = oUtf8.GetBytes("Pay 100 to Bob")
	oSha = new HashAlgorithmName().SHA256
	cSignature = oKey.SignData([ :data = cMessage, :hashAlgorithm = oSha ])
	? nl + "2. the signature has " + len(cSignature) + " bytes"
	? "   it is different every time you sign (a random number is part of it), so the program does not print it"

	# 3. Verify: true only for the same message and the same signature
	? nl + "3. the original message:       " + oKey.VerifyData([ :data = cMessage, :signature = cSignature, :hashAlgorithm = oSha ])
	cChanged = oUtf8.GetBytes("Pay 900 to Bob")
	? "   the message changed (100 to 900): " + oKey.VerifyData([ :data = cChanged, :signature = cSignature, :hashAlgorithm = oSha ])
	cOther = oKey.SignData([ :data = cMessage, :hashAlgorithm = oSha ])
	? "   a second signature of the same message is also valid: " + oKey.VerifyData([ :data = cMessage, :signature = cOther, :hashAlgorithm = oSha ]) + ", but different from the first: " + (cOther != cSignature)

	# 4. A signature of one key is not valid for another key: somebody else can not sign in your name
	oOtherKey = new ECDsa().Create(oCurve)
	? nl + "4. verified with another key: " + oOtherKey.VerifyData([ :data = cMessage, :signature = cSignature, :hashAlgorithm = oSha ])

	# 5. Share only the PUBLIC part of the key: ExportSubjectPublicKeyInfo() gives its bytes (a Ring text, in a standard format that every system reads),
	#    without the private number. The receiver imports the bytes into a new key object and can only VERIFY, never sign in your name.
	cPublic = oKey.ExportSubjectPublicKeyInfo()
	oReceiver = new ECDsa().Create(oCurve)
	oReceiver.ImportSubjectPublicKeyInfo(cPublic)
	? nl + "5. the public key is " + len(cPublic) + " bytes; the receiver has only that and can verify the message: " + oReceiver.VerifyData([ :data = cMessage, :signature = cSignature, :hashAlgorithm = oSha ])
	lCanSign = True
	try
		oReceiver.SignData([ :data = cMessage, :hashAlgorithm = oSha ])
	catch
		lCanSign = False
	done
	? "   the receiver can sign with it: " + lCanSign + "   (there is no private key)"

	# 6. A signature is not encryption: the message itself is not hidden. If the message must be secret too, encrypt it (the tutorial "Protecting and signing messages").
	oKey.Dispose()
	oOtherKey.Dispose()
	oReceiver.Dispose()
