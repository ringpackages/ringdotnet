# UUIDNext: UUIDs of the newer versions (v4 random, v5 name based, v7 sequential): Guid values made by static methods, and a known name based value
load "pkg.ring"
pkgUse("uuidnext",[["UUIDNext","4.2.4"]],[["UUIDNext.dll",["UUIDNext"]]])
pkgImport("uuidnext","UUIDNext.dll","UUIDNext")

oUuid = new Uuid()
oRandom = oUuid.NewRandom()
cRandom = oRandom.ToString()
dnAssert("a Guid as text has 36 characters",len(cRandom),36)
dnAssert("a random UUID is version 4",cRandom[15],"4")
dnAssert("two random UUIDs differ",oUuid.NewRandom().ToString() != cRandom,1)

# a sequential UUID is version 7 and its time part grows: the first 12 hex digits are a millisecond time
cFirst = oUuid.NewSequential().ToString()
dnAssert("a sequential UUID is version 7",cFirst[15],"7")
cNext = ""
for nTry = 1 to 5
	cNext = oUuid.NewSequential().ToString()
next
dnAssert("the time part never goes back",strcmp(left(cNext,8),left(cFirst,8)) >= 0,1)

# a name based UUID (version 5) is the same for the same name and has a known value for a known name
oNamespaces = new UuidNamespace()
oDns = oNamespaces.DNS
cName = oUuid.NewNameBased(oDns,"www.example.com").ToString()
dnAssert("a name based UUID has a known value",cName,"2ed6657d-e927-568b-95e1-2665a8aea6a2")
dnAssert("the same name, the same UUID",oUuid.NewNameBased(oDns,"www.example.com").ToString(),cName)
dnAssert("another name, another UUID",oUuid.NewNameBased(oDns,"example.org").ToString() != cName,1)

dnTestSummary()
