# Mapster: object mapping; generic static methods with two type arguments, collections to collections
load "pkg.ring"
pkgUse("mapster",[["Mapster","7.4.0"]],[["Mapster.dll",["Mapster"]],["Mapster.Core.dll",[]]])
pkgImport("mapster","Mapster.dll","Mapster")
dnImport("System.Collections.Generic")

oList = dnNew("System.Collections.Generic.List`1[[System.Int32]]",[])
oList.Add(3)
oList.Add(1)
oList.Add(2)

oArray = dnType("Mapster.TypeAdapter").callGeneric("Adapt",["System.Collections.Generic.List`1[[System.Int32]]","System.Int32[]"],[oList])
dnAssert("a list adapted to an array",len(oArray.toList()),3)
dnAssert("in the same order",oArray.toList()[1],3)

oStrings = dnType("Mapster.TypeAdapter").callGeneric("Adapt",["System.Collections.Generic.List`1[[System.Int32]]","System.Collections.Generic.List`1[[System.String]]"],[oList])
dnAssert("numbers adapted to texts",oStrings.Item(2),"2")

dnAssert("a number to a text",dnType("Mapster.TypeAdapter").callGeneric("Adapt",["System.Int32","System.String"],[42]),"42")
dnAssert("a text to a number",dnType("Mapster.TypeAdapter").callGeneric("Adapt",["System.String","System.Int32"],["17"]),17)

oDictionary = dnNew("System.Collections.Generic.Dictionary`2[[System.String],[System.Int32]]",[])
oDictionary.SetItem("a",1)
oCopy = dnType("Mapster.TypeAdapter").callGeneric("Adapt",["System.Collections.Generic.Dictionary`2[[System.String],[System.Int32]]","System.Collections.Generic.Dictionary`2[[System.String],[System.Int32]]"],[oDictionary])
dnAssert("a dictionary copied",oCopy.Item("a"),1)
oCopy.SetItem("a",5)
dnAssert("and the original is not changed",oDictionary.Item("a"),1)

dnTestSummary()
