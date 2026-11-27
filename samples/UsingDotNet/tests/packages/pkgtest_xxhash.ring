# Standart.Hash.xxHash: the xxHash hash functions (32, 64 and 128 bit) of a text and of bytes, with known values and a seed
load "pkg.ring"
pkgUse("xxhash",[["Standart.Hash.xxHash","4.0.5"]],[["Standart.Hash.xxHash.dll",["Standart.Hash.xxHash"]]])
pkgImport("xxhash","Standart.Hash.xxHash.dll","Standart.Hash.xxHash")

oHash32 = new xxHash32()
# known values of xxHash32 with seed 0
dnAssert("xxHash32 of an empty text",oHash32.ComputeHash([ :str = "", :seed = 0 ]),46947589)
dnAssert("the same text, the same hash",oHash32.ComputeHash([ :str = "hello", :seed = 0 ]),oHash32.ComputeHash([ :str = "hello", :seed = 0 ]))
dnAssert("a seed changes the hash",oHash32.ComputeHash([ :data = "hello", :length = 5, :seed = 1 ]) != 4211111929,1)
dnAssert("another text, another hash",oHash32.ComputeHash([ :data = "hellp", :length = 5, :seed = 0 ]) != 4211111929,1)

# the hash of bytes: a Ring text is a list of bytes
dnAssert("xxHash32 of the bytes of hello (the known value)",oHash32.ComputeHash([ :data = "hello", :length = 5, :seed = 0 ]),4211111929)
# the text overload hashes the characters as .NET holds them (two bytes each)
cWide = "h" + char(0) + "e" + char(0) + "l" + char(0) + "l" + char(0) + "o" + char(0)
dnAssert("the text overload hashes UTF-16",oHash32.ComputeHash([ :str = "hello", :seed = 0 ]),oHash32.ComputeHash([ :data = cWide, :length = 10, :seed = 0 ]))

# the 64 bit hash: the numbers go over what Ring can count exactly, so the test compares hashes with each other
oHash64 = new xxHash64()
nHello = oHash64.ComputeHash([ :str = "hello", :seed = 0 ])
dnAssert("xxHash64 is stable",oHash64.ComputeHash([ :str = "hello", :seed = 0 ]),nHello)
dnAssert("xxHash64 differs with the text",oHash64.ComputeHash([ :str = "world", :seed = 0 ]) != nHello,1)
dnAssert("xxHash64 differs with the seed",oHash64.ComputeHash([ :str = "hello", :seed = 7 ]) != nHello,1)

dnTestSummary()
