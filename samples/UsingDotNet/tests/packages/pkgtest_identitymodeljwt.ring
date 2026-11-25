# System.IdentityModel.Tokens.Jwt: signed JWT tokens (the ASP.NET Core flavour): a token made from claims and a signing key, written to its text, read
# back, and validated against the rules of TokenValidationParameters (issuer, audience, signature, lifetime)
load "pkg.ring"
pkgUse("identitymodeljwt",[["System.IdentityModel.Tokens.Jwt","8.23.0"]],[["System.IdentityModel.Tokens.Jwt.dll",["System.IdentityModel.Tokens.Jwt"]],["Microsoft.IdentityModel.Tokens.dll",["Microsoft.IdentityModel.Tokens"]],["Microsoft.IdentityModel.Logging.dll",[]],["Microsoft.IdentityModel.JsonWebTokens.dll",[]]])
pkgImport("identitymodeljwt","System.IdentityModel.Tokens.Jwt.dll","System.IdentityModel.Tokens.Jwt")
pkgImport("identitymodeljwt","Microsoft.IdentityModel.Tokens.dll","Microsoft.IdentityModel.Tokens")

cSecret = "this is a secret key of at least 32 bytes!!"
oKey = new SymmetricSecurityKey(dnBuffer(cSecret))
dnAssert("the key has 344 bits",oKey.KeySize,344)
oCredentials = dnNew("Microsoft.IdentityModel.Tokens.SigningCredentials",[oKey,"HS256"])
dnAssert("the algorithm of the credentials",oCredentials.Algorithm,"HS256")

# a token with an issuer, an audience, two claims and a lifetime
oSystemDate = dnStatic("System.DateTime","get_UtcNow",[])
oExpires = oSystemDate.AddHours(1)
aClaims = [ dnNew("System.Security.Claims.Claim",["sub","ann"]), dnNew("System.Security.Claims.Claim",["role","admin"]) ]
oToken = dnNew("System.IdentityModel.Tokens.Jwt.JwtSecurityToken",[ :issuer = "ringdotnet", :audience = "tests", :claims = aClaims, :expires = oExpires, :signingCredentials = oCredentials ])
oHandler = new JwtSecurityTokenHandler()
oHandler.MapInboundClaims = 0          # keep the claim names of the token ("sub", "role") instead of the long names of System.Security.Claims
cToken = oHandler.WriteToken(oToken)
aParts = str2list(substr(cToken,".",nl))
dnAssert("a token has three parts",len(aParts),3)
dnAssert("the header starts with the encoded algorithm",left(cToken,2),"ey")
dnAssert("the token is readable",oHandler.CanReadToken(cToken),1)

# read it back without validating
oRead = oHandler.ReadJwtToken(cToken)
dnAssert("the issuer",oRead.Issuer,"ringdotnet")
dnAssert("the audience",oRead.Audiences.toList()[1],"tests")
dnAssert("the algorithm",oRead.SignatureAlgorithm,"HS256")
dnAssert("the subject claim",oRead.Subject,"ann")
nRoles = 0
for oClaim in oRead.Claims.toList()
	if oClaim.Type = "role" and oClaim.Value = "admin"
		nRoles++
	ok
next
dnAssert("the role claim",nRoles,1)

# validate it: the rules are the properties of TokenValidationParameters; the answer of ValidateToken is [the principal, the token that was read]
oRules = new TokenValidationParameters()
oRules.ValidateIssuer = 1
oRules.ValidIssuer = "ringdotnet"
oRules.ValidateAudience = 1
oRules.ValidAudience = "tests"
oRules.ValidateIssuerSigningKey = 1
oRules.IssuerSigningKey = oKey
oRules.ValidateLifetime = 1
aValid = oHandler.callMethod("ValidateToken",[cToken,oRules])
oPrincipal = aValid[1]
dnAssert("a valid token gives its principal",oPrincipal.Identity.IsAuthenticated,1)
dnAssert("the claim of the principal",oPrincipal.FindFirst("sub").Value,"ann")
dnAssert("the principal has the role claim",oPrincipal.callMethod("HasClaim",["role","admin"]),1)

# a wrong key, a wrong audience and a token that is already over are errors
oOther = new SymmetricSecurityKey(dnBuffer("another secret key of at least 32 bytes!"))
oBad = new TokenValidationParameters()
oBad.ValidateIssuer = 0
oBad.ValidateAudience = 0
oBad.IssuerSigningKey = oOther
dnAssert("a wrong key is rejected",substr(tryValidate(oHandler,cToken,oBad),"SecurityTokenSignatureKeyNotFoundException") + substr(tryValidate(oHandler,cToken,oBad),"SecurityTokenInvalidSignatureException") > 0,1)
oRules.ValidAudience = "someone else"
dnAssert("a wrong audience is rejected",substr(tryValidate(oHandler,cToken,oRules),"SecurityTokenInvalidAudienceException") > 0,1)
oRules.ValidAudience = "tests"
oPast = dnNew("System.IdentityModel.Tokens.Jwt.JwtSecurityToken",[ :issuer = "ringdotnet", :audience = "tests", :notBefore = oSystemDate.AddHours(-3), :expires = oSystemDate.AddHours(-2), :signingCredentials = oCredentials ])
cOld = oHandler.WriteToken(oPast)
dnAssert("an expired token is rejected",substr(tryValidate(oHandler,cOld,oRules),"SecurityTokenExpiredException") > 0,1)
dnAssert("a changed payload is rejected",len(tryValidate(oHandler,aParts[1] + "." + aParts[2] + "x." + aParts[3],oRules)) > 0,1)
dnAssert("a text that is not a token can not be read",oHandler.CanReadToken("not a token"),0)

dnTestSummary()

# the text of the error that ValidateToken raises ("" when the token is valid)
func tryValidate oHandler, cToken, oRules

	cError = ""
	try
		oHandler.callMethod("ValidateToken",[cToken,oRules])
	catch
		cError = cCatchError
	done
	return cError

