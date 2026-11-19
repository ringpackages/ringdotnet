# protecting data - the Data Protection API: purposes, tampering, keys on disk, and values that expire
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"RingDotNet.Web"                  # the Data Protection API is part of the ASP.NET Core runtime: this line starts it
}

func main
	cExt = "Microsoft.AspNetCore.DataProtection.DataProtectionCommonExtensions"
	cProviderType = "Microsoft.AspNetCore.DataProtection.DataProtectionProvider"

	# The Data Protection API encrypts and signs small pieces of data (a cookie, a token, a "remember me" value, a link in an e-mail)
	# without you handling keys, algorithms or initialisation vectors. It makes keys, keeps them in a folder, renews them,
	# and encrypts with AES and signs with HMAC. ASP.NET Core uses it for its cookies and tokens.
	cKeys = new Path().Combine([new Path().GetTempPath(),"ringdotnet_tutorial113_keys"])
	if new Directory().Exists(cKeys)
		new Directory().Delete([ :path = cKeys, :recursive = True ])
	ok
	new Directory().CreateDirectory(cKeys)
	oProvider = dnStatic(cProviderType,"Create",[dnNew("DirectoryInfo",[ :path = cKeys ])])

	# 1. A protector is made for a PURPOSE (a text that names what the data is for). Protect turns a text into an unreadable token
	#    and Unprotect gives the text back.
	oProtector = oProvider.callMethod("CreateProtector",["tutorial.cookies"])
	cToken = dnStatic(cExt,"Protect",[oProtector,"user=ann;role=admin"])
	? "1. the protected text starts with CfDJ8 (every token of this API does): " + (left(cToken,5) = "CfDJ8")
	? "   it does not show the data: " + (substr(cToken,"ann") = 0) + ", and it is longer than the data: " + (len(cToken) > 40)
	? "   Unprotect gives back: " + dnStatic(cExt,"Unprotect",[oProtector,cToken])

	# 2. The same data protected twice gives different tokens (a random value is part of each one), but both unprotect to the same text
	cToken2 = dnStatic(cExt,"Protect",[oProtector,"user=ann;role=admin"])
	? nl + "2. two tokens of the same text are different: " + (cToken != cToken2) + "; the second also gives: " + dnStatic(cExt,"Unprotect",[oProtector,cToken2])

	# 3. Purposes keep uses apart: a token made for "tutorial.cookies" cannot be opened with the protector of "tutorial.password-reset".
	#    So a stolen cookie value does not work as a reset link, even though the same keys are used.
	oOther = oProvider.callMethod("CreateProtector",["tutorial.password-reset"])
	? nl + "3. unprotect with another purpose: " + tryUnprotect(cExt,oOther,cToken)

	# 4. Tampering: change one character of the token and the check fails. The data can not be modified, only replaced by a valid token.
	cTampered = left(cToken,20) + changeChar(substr(cToken,21,1)) + substr(cToken,22)
	? nl + "4. unprotect a token with one changed character: " + tryUnprotect(cExt,oProtector,cTampered)

	# 5. The keys are on disk, so a NEW provider on the same folder opens the old tokens (after a restart of the program, or in another
	#    copy of it). Without the key folder the tokens can not be opened: it is as secret as a password.
	aFiles = new Directory().GetFiles(cKeys)
	oProvider2 = dnStatic(cProviderType,"Create",[dnNew("DirectoryInfo",[ :path = cKeys ])])
	oProtector2 = oProvider2.callMethod("CreateProtector",["tutorial.cookies"])
	? nl + "5. key files in the folder: " + len(aFiles.toList()) + ", a second provider on the same folder opens the token: " + dnStatic(cExt,"Unprotect",[oProtector2,cToken])
	cOtherFolder = cKeys + "_other"
	new Directory().CreateDirectory(cOtherFolder)
	oStranger = dnStatic(cProviderType,"Create",[dnNew("DirectoryInfo",[ :path = cOtherFolder ])]).callMethod("CreateProtector",["tutorial.cookies"])
	? "   a provider with other keys: " + tryUnprotect(cExt,oStranger,cToken)

	# 6. Time limits: a token that is valid for a short time only (a link in an e-mail, a one-time code)
	cAdvanced = "Microsoft.AspNetCore.DataProtection.DataProtectionAdvancedExtensions"          # (in the Extensions assembly of the API)
	oLimited = dnStatic(cAdvanced,"ToTimeLimitedDataProtector",[oProtector])
	cShort = dnStatic(cAdvanced,"Protect",[oLimited,"reset:42",dnStatic("System.TimeSpan","FromMilliseconds",[1200])])
	? nl + "6. a token that is valid for 1.2 seconds: now " + tryUnprotectLimited(cAdvanced,oLimited,cShort)
	dnStatic("System.Threading.Thread","Sleep",[2000])
	? "   after 2 seconds: " + tryUnprotectLimited(cAdvanced,oLimited,cShort)

	new Directory().Delete([ :path = cKeys, :recursive = True ])
	new Directory().Delete([ :path = cOtherFolder, :recursive = True ])

func tryUnprotect cExt,oProtector,cToken
	try
		return "valid, it gives '" + dnStatic(cExt,"Unprotect",[oProtector,cToken]) + "'"
	catch
		return "refused (a cryptographic error)"
	done

func changeChar cChar
	if cChar = "A"
		return "B"
	ok
	return "A"

# the time-limited protector also gives the time when the token expires (an out value: the answer is a list)
func tryUnprotectLimited cAdvanced,oLimited,cToken
	try
		aResult = dnStatic(cAdvanced,"Unprotect",[oLimited,cToken])
		if islist(aResult)
			return "valid, it gives '" + aResult[1] + "'"
		ok
		return "valid, it gives '" + aResult + "'"
	catch
		return "refused (it expired or it is not valid)"
	done
