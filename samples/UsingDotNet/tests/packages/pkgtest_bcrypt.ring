# BCrypt.Net: password hashes with a salt and a cost, and the check of a password
load "pkg.ring"
pkgUse("bcrypt",[["BCrypt.Net-Next","4.2.1"]],[["BCrypt-Net-Next.dll",["BCrypt.Net"]]])
pkgImport("bcrypt","BCrypt-Net-Next.dll","BCrypt.Net")

cHash = dnStatic("BCrypt.Net.BCrypt","HashPassword",["correct horse"])
dnAssert("a hash is 60 characters",len(cHash),60)
dnAssert("a hash starts with the version",left(cHash,4),"$2a$")
dnAssert("the right password verifies",dnStatic("BCrypt.Net.BCrypt","Verify",["correct horse",cHash]),1)
dnAssert("a wrong password does not",dnStatic("BCrypt.Net.BCrypt","Verify",["battery staple",cHash]),0)

# the salt makes two hashes of one password different, and both verify
cHash2 = dnStatic("BCrypt.Net.BCrypt","HashPassword",["correct horse"])
dnAssert("two hashes of one password differ",cHash != cHash2,1)
dnAssert("and both verify",dnStatic("BCrypt.Net.BCrypt","Verify",["correct horse",cHash2]),1)

# the cost is in the hash (the work factor): named arguments
cCost = dnStatic("BCrypt.Net.BCrypt","HashPassword",["correct horse",4])
dnAssert("the work factor is in the hash",substr(cCost,"$04$") > 0,1)

# the enhanced hash (SHA-384 before bcrypt) has its own check
cEnhanced = dnStatic("BCrypt.Net.BCrypt","EnhancedHashPassword",["a password that is longer than seventy two characters will not be cut by bcrypt: " + copy("x",40)])
dnAssert("the enhanced hash verifies",dnStatic("BCrypt.Net.BCrypt","EnhancedVerify",["a password that is longer than seventy two characters will not be cut by bcrypt: " + copy("x",40),cEnhanced]),1)

# a salt by itself
cSalt = dnStatic("BCrypt.Net.BCrypt","GenerateSalt",[])
dnAssert("a salt has 29 characters",len(cSalt),29)
dnAssert("a hash with a given salt",left(dnStatic("BCrypt.Net.BCrypt","HashPassword",["pw",cSalt]),29),cSalt)

dnTestSummary()
