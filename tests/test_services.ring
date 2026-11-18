# Batch: System.Globalization, System.Security.Cryptography, System.Diagnostics
load "dotnetlib.ring"
dnImport("System")
dnImport("System.IO")
dnImport("System.Text")
dnImport("System.Globalization")
dnImport("System.Security.Cryptography")
dnImport("System.Diagnostics")
dnImport("System.Threading")

# Globalization
oFrench = new CultureInfo("fr-FR")
dnAssert("CultureInfo.Name",oFrench.Name,"fr-FR")
dnAssert("CultureInfo.EnglishName",oFrench.EnglishName,"French (France)")
dnAssert("NumberFormat decimal separator",oFrench.NumberFormat.NumberDecimalSeparator,",")
dnAssert("ToTitleCase",new CultureInfo("en-US").TextInfo.ToTitleCase("hello ring world"),"Hello Ring World")
dnAssert("Culture date format",new DateTime(2024,3,9).ToString_2("D",new CultureInfo("en-US")),"Saturday, March 9, 2024")
dnAssert("CultureInfo.Invariant",new CultureInfo("en-US").InvariantCulture.Name,"")
dnAssert("RegionInfo",new RegionInfo("US").ISOCurrencySymbol,"USD")
dnAssert("Calendar",new GregorianCalendar().GetDaysInMonth(2024,2),29)
dnAssert("CompareInfo",new CultureInfo("en-US").CompareInfo.Compare("a","B") < 0,1)

# Cryptography: hashes of known values
oConvert = new Convert()
dnAssert("SHA256",lower(oConvert.ToHexString(new SHA256().HashData("abc"))),"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
dnAssert("MD5",lower(oConvert.ToHexString(new MD5().HashData("abc"))),"900150983cd24fb0d6963f7d28e17f72")
dnAssert("SHA1",lower(oConvert.ToHexString(new SHA1().HashData("abc"))),"a9993e364706816aba3e25717850c26c9cd0d89d")
oHmac = new HMACSHA256().New_1("key")
dnAssert("HMACSHA256",lower(oConvert.ToHexString(oHmac.ComputeHash("The quick brown fox jumps over the lazy dog"))),"f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8")
dnAssert("RandomNumberGenerator",len(new RandomNumberGenerator().GetBytes(16)),16)

# AES round trip
oAes = new Aes().Create(NULL)
oAes.GenerateKey()
oAes.GenerateIV()
cPlain = "secret message for AES"
cCipher = oAes.CreateEncryptor(NULL).TransformFinalBlock(cPlain,0,len(cPlain))
dnAssert("AES encrypts",cCipher != cPlain,1)
cBack = oAes.CreateDecryptor(NULL).TransformFinalBlock(cCipher,0,len(cCipher))
dnAssert("AES round trip",cBack,cPlain)

# Diagnostics
oInfo = new ProcessStartInfo()
if iswindows()
	oInfo.FileName = "cmd"
	oInfo.Arguments = "/c echo hello from a process"
else
	oInfo.FileName = "sh"
	oInfo.Arguments = "-c 'echo hello from a process'"
ok
oInfo.RedirectStandardOutput = 1
oInfo.UseShellExecute = 0
oInfo.CreateNoWindow = 1
oProcess = new Process().Start_1(oInfo)
cOut = oProcess.StandardOutput.ReadToEnd()
oProcess.WaitForExit(NULL)
dnAssert("Process output",left(cOut,22),"hello from a process" + left(windowsnl(),2))
dnAssert("Process exit code",oProcess.ExitCode,0)
dnAssert("Process.GetCurrentProcess",new Process().GetCurrentProcess().Id > 0,1)
oWatch = new Stopwatch()
oWatch.Start()
new Thread().Sleep(15)
oWatch.Stop()
dnAssert("Stopwatch",oWatch.ElapsedMilliseconds >= 10,1)
dnAssert("Stopwatch.StartNew",new Stopwatch().StartNew().IsRunning,1)

nFail = dnTestSummary()
