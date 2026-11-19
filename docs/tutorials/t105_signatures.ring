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
	oCurve = dnStatic("System.Security.Cryptography.ECCurve","CreateFromFriendlyName",["nistP256"])          # a named curve
	oKey = dnStatic("System.Security.Cryptography.ECDsa","Create",[oCurve])
	? "1. a key pair was made on the curve nistP256, key size " + oKey.getProp("KeySize") + " bits"

	# 2. Sign a message: the data is hashed (SHA-256) and the hash is signed. The signature of ECDsa has 64 bytes for this curve.
	aMessage = oUtf8.GetBytes("Pay 100 to Bob")
	oSha = dnStatic("System.Security.Cryptography.HashAlgorithmName","get_SHA256",[])
	aSignature = oKey.callMethod("SignData",[aMessage,oSha])
	? nl + "2. the signature has " + len(aSignature) + " bytes"
	? "   it is different every time you sign (a random number is part of it), so the program does not print it"

	# 3. Verify: true only for the same message and the same signature
	? nl + "3. the original message:       " + oKey.callMethod("VerifyData",[aMessage,aSignature,oSha])
	aChanged = oUtf8.GetBytes("Pay 900 to Bob")
	? "   the message changed (100 to 900): " + oKey.callMethod("VerifyData",[aChanged,aSignature,oSha])
	aOther = oKey.callMethod("SignData",[aMessage,oSha])
	? "   a second signature of the same message is also valid: " + oKey.callMethod("VerifyData",[aMessage,aOther,oSha]) + ", but different from the first: " + (aOther != aSignature)

	# 4. A signature of one key is not valid for another key: somebody else can not sign in your name
	oOtherKey = dnStatic("System.Security.Cryptography.ECDsa","Create",[oCurve])
	? nl + "4. verified with another key: " + oOtherKey.callMethod("VerifyData",[aMessage,aSignature,oSha])

	# 5. Share only the PUBLIC part of the key: ExportParameters(False) gives the curve and the public point, without the private number.
	#    The receiver imports it into a new key object and can only VERIFY, never sign in your name.
	oPublic = oKey.callMethod("ExportParameters",[False])
	oReceiver = dnStatic("System.Security.Cryptography.ECDsa","Create",[oCurve])
	oReceiver.callMethod("ImportParameters",[oPublic])
	? nl + "5. the receiver has only the public key and can verify the message: " + oReceiver.callMethod("VerifyData",[aMessage,aSignature,oSha])
	lCanSign = True
	try
		oReceiver.callMethod("SignData",[aMessage,oSha])
	catch
		lCanSign = False
	done
	? "   the receiver can sign with it: " + lCanSign + "   (there is no private key)"

	# 6. A signature is not encryption: the message itself is not hidden. If the message must be secret too, encrypt it (the tutorial "Protecting and signing messages").
	oKey.callMethod("Dispose",[])
	oOtherKey.callMethod("Dispose",[])
	oReceiver.callMethod("Dispose",[])
