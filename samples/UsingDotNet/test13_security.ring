load "../../libraries/dotnetlib/dotnetlib.ring"
using {
	"System"
	"System.Globalization"
	"System.Security.Cryptography"
	"System.Diagnostics"
}

# Hashes and HMAC
oConvert = new Convert()
? "SHA256(abc)    : " + lower(oConvert.ToHexString(new SHA256().HashData("abc")))
? "MD5(abc)       : " + lower(oConvert.ToHexString(new MD5().HashData("abc")))
oHmac = new HMACSHA256().New_1("secret key")
? "HMAC           : " + left(lower(oConvert.ToHexString(oHmac.ComputeHash("message"))),32) + "..."

# AES encryption round trip
oAes = new Aes().Create()
oAes.GenerateKey()
oAes.GenerateIV()
cText = "Ring talks to .NET crypto"
cCipher = oAes.CreateEncryptor().TransformFinalBlock(cText,0,len(cText))
? "AES            : " + len(cText) + " bytes -> " + len(cCipher) + " bytes encrypted"
? "Decrypted      : " + oAes.CreateDecryptor().TransformFinalBlock(cCipher,0,len(cCipher))

# Cultures
oUS = new CultureInfo("en-US")
oDate = new DateTime(2024,7,4)
? "US date        : " + oDate.ToString_2("D",oUS)
? "German date    : " + oDate.ToString_2("D",new CultureInfo("de-DE"))
? "Title case     : " + oUS.TextInfo.ToTitleCase("ring meets dot net")

# Start a process and read its output
oInfo = new ProcessStartInfo()
if iswindows()
	oInfo.FileName = "cmd"
	oInfo.Arguments = "/c ver"
else
	oInfo.FileName = "uname"
ok
oInfo.RedirectStandardOutput = 1
oInfo.UseShellExecute = 0
oInfo.CreateNoWindow = 1
oProcess = new Process().Start_1(oInfo)
? "Process says   : " + trim(oProcess.StandardOutput.ReadToEnd())
oProcess.WaitForExit()
