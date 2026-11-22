# Isopoh.Cryptography.Argon2: a password hash in the standard encoded text, and its check
load "pkg.ring"
pkgUse("argon2",[["Isopoh.Cryptography.Argon2","2.0.0"]],[["Isopoh.Cryptography.Argon2.dll",["Isopoh.Cryptography.Argon2"]],["Isopoh.Cryptography.Blake2b.dll",[]],["Isopoh.Cryptography.SecureArray.dll",[]]])
pkgImport("argon2","Isopoh.Cryptography.Argon2.dll","Isopoh.Cryptography.Argon2")

cHash = dnStatic("Isopoh.Cryptography.Argon2.Argon2","Hash",["correct horse"])
dnAssert("the encoded form",left(cHash,9),"$argon2id")
dnAssert("the right password",dnStatic("Isopoh.Cryptography.Argon2.Argon2","Verify",[cHash,"correct horse"]),1)
dnAssert("the wrong password",dnStatic("Isopoh.Cryptography.Argon2.Argon2","Verify",[cHash,"battery staple"]),0)

# a salt makes a different hash each time
cOther = dnStatic("Isopoh.Cryptography.Argon2.Argon2","Hash",["correct horse"])
dnAssert("two hashes of one password differ",cHash != cOther,1)
dnAssert("and both are valid",dnStatic("Isopoh.Cryptography.Argon2.Argon2","Verify",[cOther,"correct horse"]),1)

# a password that is not English
cArabic = dnStatic("Isopoh.Cryptography.Argon2.Argon2","Hash",["كلمة السر 💍"])
dnAssert("an Arabic password with an emoji",dnStatic("Isopoh.Cryptography.Argon2.Argon2","Verify",[cArabic,"كلمة السر 💍"]),1)

dnTestSummary()
