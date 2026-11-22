# jose-jwt: signed tokens (HS256) from a JSON payload and a binary key; decoded again, checked with a wrong key
load "pkg.ring"
pkgUse("josejwt",[["jose-jwt","5.3.0"]],[["jose-jwt.dll",["Jose"]]])
pkgImport("josejwt","jose-jwt.dll","Jose")

cKeyText = "a secret key that is long enough for HS256!"
cKey = dnBuffer(cKeyText)
cPayload = '{"sub":"ann","role":"admin","n":5}'
cToken = dnStatic("Jose.JWT","Encode",[cPayload,cKey,dnStatic("Jose.JwsAlgorithm","HS256",[])])
aParts = str2list(substr(cToken,".",nl))
dnAssert("a token has three parts",len(aParts),3)

cBack = dnStatic("Jose.JWT","Decode",[cToken,cKey])
dnAssert("the payload is read back",compact(cBack),cPayload)
dnAssert("the header names the algorithm",dnStatic("Jose.JWT","Headers",[cToken]).Item("alg"),"HS256")

cError = ""
try
	dnStatic("Jose.JWT","Decode",[cToken,dnBuffer("another key that is long enough for HS256")])
catch
	cError = cCatchError
done
dnAssert("a wrong key raises an error",len(cError) > 0,1)

# a changed payload does not verify
cChanged = aParts[1] + "." + dnStatic("Jose.Base64Url","Encode",['{"sub":"bob"}']) + "." + aParts[3]
cError = ""
try
	dnStatic("Jose.JWT","Decode",[cChanged,cKey])
catch
	cError = cCatchError
done
dnAssert("a changed payload raises an error",len(cError) > 0,1)

# a payload that is not English
cArabic = dnStatic("Jose.JWT","Encode",['{"name":"مرحبا"}',cKey,dnStatic("Jose.JwsAlgorithm","HS256",[])])
dnAssert("Arabic text in a token",substr(dnStatic("Jose.JWT","Decode",[cArabic,cKey]),"مرحبا") > 0,1)

dnTestSummary()

func compact cText
	return substr(substr(substr(cText,char(13),""),char(10),"")," ","")
