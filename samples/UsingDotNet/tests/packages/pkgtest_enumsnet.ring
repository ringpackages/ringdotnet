# Enums.NET: fast helpers for enums; every method is generic over the enum type, so the type is given with callGeneric (the framework enums DayOfWeek
# and FileAttributes are used: a plain enum and a flags enum)
load "pkg.ring"
pkgUse("enumsnet",[["Enums.NET","5.0.0"]],[["Enums.NET.dll",["EnumsNET"]]])
pkgImport("enumsnet","Enums.NET.dll","EnumsNET")

oEnums = dnType("EnumsNET.Enums")
aNames = oEnums.callGeneric("GetNames",["System.DayOfWeek"],[]).toList()
dnAssert("the names of an enum",len(aNames),7)
dnAssert("the first name",aNames[1],"Sunday")
dnAssert("the count of members",oEnums.callGeneric("GetMemberCount",["System.DayOfWeek"],[]),7)
dnAssert("a name is a member",oEnums.callGeneric("IsValid",["System.DayOfWeek"],["Friday"]),1)
dnAssert("a number that is no member is not valid",oEnums.callGeneric("IsValid",["System.DayOfWeek"],[9]),0)
cError = ""
try
	oEnums.callGeneric("IsValid",["System.DayOfWeek"],["Someday"])
catch
	cError = cCatchError
done
dnAssert("a text that is not a name can not be converted to the enum",len(cError) > 0,1)
dnAssert("the name of a value",oEnums.callGeneric("GetName",["System.DayOfWeek"],[3]),"Wednesday")
dnAssert("Parse reads a name",oEnums.callGeneric("Parse",["System.DayOfWeek"],["Friday"]),"Friday")
dnAssert("Parse reads a number as a text",oEnums.callGeneric("Parse",["System.DayOfWeek"],["2"]),"Tuesday")
dnAssert("a name with other letter cases",oEnums.callGeneric("Parse",["System.DayOfWeek"],["friday",1]),"Friday")

# a flags enum: the helpers for flags are in the class FlagEnums
oFlags = dnType("EnumsNET.FlagEnums")
dnAssert("the flags of a combination",oFlags.callGeneric("GetFlags",["System.IO.FileAttributes"],["ReadOnly, Hidden"]).toList()[2],"Hidden")
dnAssert("the number of flags set",oFlags.callGeneric("GetFlagCount",["System.IO.FileAttributes"],["ReadOnly, Hidden"]),2)
dnAssert("a flag is set",oFlags.callGeneric("HasAllFlags",["System.IO.FileAttributes"],["ReadOnly, Hidden","Hidden"]),1)
dnAssert("a flag that is not set",oFlags.callGeneric("HasAnyFlags",["System.IO.FileAttributes"],["ReadOnly, Hidden","Archive"]),0)
dnAssert("a flag is removed",oFlags.callGeneric("RemoveFlags",["System.IO.FileAttributes"],["ReadOnly, Hidden","Hidden"]),"ReadOnly")
dnTestSummary()
