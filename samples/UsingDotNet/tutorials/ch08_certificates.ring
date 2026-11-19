# certificates - a self-signed X.509 certificate, what it contains, export with and without the private key, and signing with it
load "dotnet.ring"
using {
	"System"
	"System.Text"
	"System.Security.Cryptography"
	"System.Security.Cryptography.X509Certificates"
}

func main
	cCrypto = "System.Security.Cryptography."
	oUtf8 = new UTF8Encoding()

	# A certificate is a public key together with a name (the SUBJECT), a time of validity, and a signature of whoever vouches for it (the
	# ISSUER). Web sites use certificates for HTTPS, programs use them to sign code and documents, and services use them to prove who they
	# are. Here we make a SELF-SIGNED certificate: the subject and the issuer are the same, so nobody but us vouches for it. That is good
	# for tests and for talking between your own programs, but a browser or another computer does not trust it.

	# 1. A key pair (RSA, 2048 bits), then a request that says who the certificate is for
	oRsa = dnStatic(cCrypto + "RSA","Create",[2048])
	oName = new X500DistinguishedName("CN=Demo Server, O=RingDotNet, C=EG")
	oSha = dnStatic(cCrypto + "HashAlgorithmName","get_SHA256",[])
	oPadding = dnStatic(cCrypto + "RSASignaturePadding","get_Pkcs1",[])
	oRequest = dnNew("CertificateRequest",[ :subjectName = oName, :key = oRsa, :hashAlgorithm = oSha, :padding = oPadding ])

	# 2. Extensions say what the certificate may be used for. This one is a plain server certificate (not a CA that signs others).
	oBasic = new X509BasicConstraintsExtension().New_([ :certificateAuthority = False, :hasPathLengthConstraint = False, :pathLengthConstraint = 0, :critical = True ])
	oRequest.CertificateExtensions.callMethod("Add",[oBasic])

	# 3. Create it: valid from yesterday (a margin for computers whose clocks differ) until a year from today
	oNow = dnStatic("System.DateTimeOffset","get_UtcNow",[])
	oCertificate = oRequest.CreateSelfSigned(oNow.AddDays(-1),oNow.AddDays(365))
	? "1. subject:     " + oCertificate.Subject
	? "   issuer:      " + oCertificate.Issuer + "   (the same: self-signed)"
	? "   thumbprint:  " + len(oCertificate.Thumbprint) + " hex characters (the SHA-1 of the certificate: it identifies it)"
	? "   has a private key: " + oCertificate.HasPrivateKey
	? "   valid for " + floor(oCertificate.NotAfter.Subtract(oCertificate.NotBefore).TotalDays + 0.5) + " days, and it is valid now: " + isValidNow(oCertificate)

	# 4. Export WITH the private key as PFX (a file with a password), and load it again. A PFX is the secret: protect it like a password.
	aPfx = oCertificate.callMethod("Export",["Pfx","correct horse battery"])
	oLoaded = new X509Certificate2().New_([ :rawData = aPfx, :password = "correct horse battery" ])
	? nl + "2. the PFX is bigger than 1000 bytes: " + (len(aPfx) > 1000) + "; loaded again it has the same thumbprint: " + (oLoaded.Thumbprint = oCertificate.Thumbprint) + " and a private key: " + oLoaded.HasPrivateKey
	lWrong = False
	try
		new X509Certificate2().New_([ :rawData = aPfx, :password = "wrong password" ])
	catch
		lWrong = True
	done
	? "   a wrong password is refused: " + lWrong

	# 5. Export the PUBLIC part only (a .cer or PEM file): this is what you give to others. It has no private key.
	cPem = oCertificate.ExportCertificatePem()
	? nl + "3. the public certificate as PEM starts with: " + left(substr(cPem,char(13),""),27)
	aCer = oCertificate.Export("Cert")
	oPublic = new X509Certificate2().New_([ :rawData = aCer ])
	? "   loaded from the public export: same thumbprint " + (oPublic.Thumbprint = oCertificate.Thumbprint) + ", private key: " + oPublic.HasPrivateKey

	# 6. Signing: the owner signs with the private key, anybody with the public certificate verifies
	aMessage = oUtf8.GetBytes("Invoice 2024-001: 1250.00")
	oPrivateKey = new RSACertificateExtensions().GetRSAPrivateKey(oCertificate)
	aSignature = oPrivateKey.callMethod("SignData",[aMessage,oSha,oPadding])
	oPublicKey = new RSACertificateExtensions().GetRSAPublicKey(oPublic)
	aChanged = oUtf8.GetBytes("Invoice 2024-001: 9250.00")
	? nl + "4. signature of " + len(aSignature) + " bytes (2048-bit key); verified with the public certificate: " + oPublicKey.callMethod("VerifyData",[aMessage,aSignature,oSha,oPadding])
	? "   the message changed: " + oPublicKey.callMethod("VerifyData",[aChanged,aSignature,oSha,oPadding])
	? "   the public certificate can not sign: " + canSign(oPublic)

	# 7. Is it trusted? A chain check asks whether the issuer is one that this computer trusts. For a self-signed certificate it is not.
	oChain = new X509Chain()
	oChain.ChainPolicy.setProp("RevocationMode","NoCheck")
	? nl + "5. the system trusts this self-signed certificate: " + oChain.Build(oPublic) + "   (nobody else vouches for it)"

	oRsa.Dispose()

func isValidNow oCertificate
	oNow = dnStatic("System.DateTime","get_Now",[])
	return oNow.CompareTo(oCertificate.NotBefore) >= 0 and oNow.CompareTo(oCertificate.NotAfter) <= 0

func canSign oPublic
	try
		new RSACertificateExtensions().GetRSAPrivateKey(oPublic).SignData(new UTF8Encoding().GetBytes("x"),new HashAlgorithmName().get_SHA256(),new RSASignaturePadding().get_Pkcs1())
		return True
	catch
		return False
	done
