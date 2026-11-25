# Nanoid (NanoidDotNet): short unique ids; the alphabet and the size can be chosen, and the ids are made from the random source of the system
load "pkg.ring"
pkgUse("nanoid",[["Nanoid","3.1.0"]],[["Nanoid.dll",["NanoidDotNet"]]])
pkgImport("nanoid","Nanoid.dll","NanoidDotNet")

cId = dnStatic("NanoidDotNet.Nanoid","Generate",[])
dnAssert("the default id has 21 characters",len(cId),21)
dnAssert("two ids are not the same",cId != dnStatic("NanoidDotNet.Nanoid","Generate",[]),1)
cDigits = dnStatic("NanoidDotNet.Nanoid","Generate",["0123456789",12])
dnAssert("an id with an alphabet and a size",len(cDigits),12)
lOnlyDigits = 1
for x = 1 to len(cDigits)
	if not isdigit(cDigits[x])
		lOnlyDigits = 0
	ok
next
dnAssert("only the letters of the alphabet are used",lOnlyDigits,1)
dnAssert("a size alone",len(dnStatic("NanoidDotNet.Nanoid","Generate",["abc",5])),5)

# many ids have no repeats
aSeen = []
lRepeat = 0
for x = 1 to 300
	cNew = dnStatic("NanoidDotNet.Nanoid","Generate",[])
	if find(aSeen,cNew) > 0
		lRepeat = 1
	ok
	aSeen + cNew
next
dnAssert("300 ids have no repeat",lRepeat,0)

# the alphabet of an id must have at least one letter, and the size must be above zero
cError = ""
try
	dnStatic("NanoidDotNet.Nanoid","Generate",["",5])
catch
	cError = cCatchError
done
dnAssert("an empty alphabet is an error",len(cError) > 0,1)
cError = ""
try
	dnStatic("NanoidDotNet.Nanoid","Generate",["abc",0])
catch
	cError = cCatchError
done
dnAssert("a size of zero is an error",len(cError) > 0,1)
dnTestSummary()
