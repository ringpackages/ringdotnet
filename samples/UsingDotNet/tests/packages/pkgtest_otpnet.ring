# Otp.NET: HOTP and TOTP; the RFC 4226 and RFC 6238 test vectors (the secret is 20 ASCII bytes)
load "pkg.ring"
pkgUse("otpnet",[["Otp.NET","1.4.0"]],[["Otp.NET.dll",["OtpNet"]]])
pkgImport("otpnet","Otp.NET.dll","OtpNet")

cSecret = "12345678901234567890"
oHotp = new Hotp(cSecret)
dnAssert("HOTP counter 0",oHotp.ComputeHOTP(0),"755224")
dnAssert("HOTP counter 1",oHotp.ComputeHOTP(1),"287082")
dnAssert("HOTP counter 2",oHotp.ComputeHOTP(2),"359152")
dnAssert("HOTP counter 9",oHotp.ComputeHOTP(9),"520489")

# TOTP at 59 seconds with 8 digits is 94287082 (RFC 6238)
oTotp = dnNew("OtpNet.Totp",[ :secretKey = cSecret, :step = 30, :totpSize = 8 ])
oTime = dnNew("System.DateTime",[ :year = 1970, :month = 1, :day = 1, :hour = 0, :minute = 0, :second = 59, :kind = "Utc" ])
dnAssert("TOTP at 59 seconds",oTotp.ComputeTotp(oTime),"94287082")

# a Base32 secret
cText = dnStatic("OtpNet.Base32Encoding","ToString",[cSecret])
dnAssert("the secret in Base32",cText,"GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ")
dnAssert("and back",dnStatic("OtpNet.Base32Encoding","ToBytes",[cText]),cSecret)

dnTestSummary()
