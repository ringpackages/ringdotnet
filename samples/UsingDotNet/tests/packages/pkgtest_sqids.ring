# Sqids: short unique ids from numbers (a generic encoder with an options object), the same ids back to numbers, an alphabet and a minimum length
load "pkg.ring"
pkgUse("sqids",[["Sqids","3.2.1"]],[["Sqids.dll",["Sqids"]]])
pkgImport("sqids","Sqids.dll","Sqids")

# the encoder works with numbers: its generic definition is made with the type of the numbers
oSqids = dnNew("Sqids.SqidsEncoder`1[[System.Int32]]",[])
cId = oSqids.callMethod("Encode",[ [1,2,3] ])
dnAssert("an id is a text",isstring(cId) and len(cId) > 0,1)
aBack = oSqids.callMethod("Decode",[cId]).toList()
dnAssert("the id decodes to the numbers",len(aBack),3)
dnAssert("the order is kept",aBack[3],3)
dnAssert("the same numbers, the same id",oSqids.callMethod("Encode",[ [1,2,3] ]),cId)
dnAssert("other numbers, another id",oSqids.callMethod("Encode",[ [3,2,1] ]) != cId,1)

# one number
cOne = oSqids.callMethod("Encode",[ [12345] ])
dnAssert("one number back",oSqids.callMethod("Decode",[cOne]).toList()[1],12345)

# a minimum length and another alphabet: the options object
oOptions = new SqidsOptions()
oOptions.MinLength = 10
cAlphabet = "k3G7QAe51FCsPW92uEOyq4Bi6HTjRxhMwdUDXrKVN0LvYIgfbtJlnoaZmcSz8p"
oOptions.Alphabet = cAlphabet
oLong = dnNew("Sqids.SqidsEncoder`1[[System.Int32]]",[oOptions])
cLong = oLong.callMethod("Encode",[ [7] ])
dnAssert("a minimum length",len(cLong) >= 10,1)
lAlphabet = 1
for i = 1 to len(cLong)
	if substr(cAlphabet,cLong[i]) = 0
		lAlphabet = 0
	ok
next
dnAssert("the id has only letters of the alphabet",lAlphabet,1)
dnAssert("a long id decodes",oLong.callMethod("Decode",[cLong]).toList()[1],7)

# an id that is not valid for this alphabet decodes to nothing
dnAssert("a foreign id decodes to an empty list",len(oSqids.callMethod("Decode",["!!!"]).toList()),0)

dnTestSummary()
