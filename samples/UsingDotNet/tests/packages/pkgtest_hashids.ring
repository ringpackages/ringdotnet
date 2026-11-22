# Hashids: short ids from numbers and back (a params array, an array result), with a salt and a minimum length
load "pkg.ring"
pkgUse("hashids",[["Hashids.net","1.7.0"]],[["Hashids.net.dll",["HashidsNet"]]])
pkgImport("hashids","Hashids.net.dll","HashidsNet")

oHashids = dnNew("HashidsNet.Hashids",[ :salt = "ring salt" ])
cId = oHashids.Encode([12345])
dnAssert("an id is a text",len(cId) > 0 and isstring(cId),1)
aBack = oHashids.Decode(cId).toList()          # an array is an object: toList() makes a Ring list
dnAssert("the id decodes to the number",aBack[1],12345)

cMany = oHashids.Encode([1,2,3])
dnAssert("several numbers in one id",len(oHashids.Decode(cMany).toList()),3)
dnAssert("the order is kept",oHashids.Decode(cMany).toList()[3],3)

# the same salt gives the same id, another salt another id
oSame = dnNew("HashidsNet.Hashids",[ :salt = "ring salt" ])
dnAssert("the same salt, the same id",oSame.Encode([12345]),cId)
oOther = dnNew("HashidsNet.Hashids",[ :salt = "other salt" ])
dnAssert("another salt, another id",oOther.Encode([12345]) != cId,1)

# a minimum length
oLong = dnNew("HashidsNet.Hashids",[ :salt = "ring salt", :minHashLength = 12 ])
dnAssert("a minimum length",len(oLong.Encode([7])) >= 12,1)

# an id that was not made by this salt does not decode
dnAssert("a foreign id decodes to nothing",len(oOther.Decode(cId).toList()) <= 1,1)

dnTestSummary()
