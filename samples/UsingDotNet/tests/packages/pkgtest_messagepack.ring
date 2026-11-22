# MessagePack: a class with attributes ([MessagePackObject], [Key]: a helper project) serialized to bytes (a Ring byte string) and back, with the type argument, and the bytes as JSON
load "pkg.ring"
pkgUseProject("messagepack","helpers/AttributeHelpers",[["MessagePack.dll",["MessagePack"]],["AttributeHelpers.dll",["AttributeHelpers"]]])
pkgImport("messagepack","MessagePack.dll","MessagePack")
pkgImport("messagepack","AttributeHelpers.dll","AttributeHelpers")

oAnn = new Person()
oAnn.Name = "Ann"
oAnn.Age = 31
oAnn.Tags.Add("a")
oAnn.Tags.Add("b")

oSerializer = dnType("MessagePack.MessagePackSerializer")
cBytes = oSerializer.callGeneric("Serialize",["AttributeHelpers.Person"],[oAnn])
dnAssert("the bytes of an object",len(cBytes) > 5,1)
dnAssert("a compact encoding (an array of three)",ascii(cBytes[1]),147)          # 0x93: a fixarray with three items

oBack = oSerializer.callGeneric("Deserialize",["AttributeHelpers.Person"],[cBytes])
dnAssert("the name read back",oBack.Name,"Ann")
dnAssert("the age read back",oBack.Age,31)
dnAssert("the list read back",oBack.Tags.Count,2)
dnAssert("an item of the list",oBack.Tags.Item(1),"b")

# the bytes as JSON
dnAssert("the bytes as JSON",oSerializer.callMethod("ConvertToJson",[cBytes]),'["Ann",31,["a","b"]]')

# a list of objects
oList = dnNewGeneric("System.Collections.Generic.List",["AttributeHelpers.Person"],[])
oList.callMethod("Add",[oAnn])
oBo = new Person()
oBo.Name = "Bo"
oBo.Age = 25
oList.callMethod("Add",[oBo])
cMany = oSerializer.callGeneric("Serialize",["System.Collections.Generic.List`1[[AttributeHelpers.Person, AttributeHelpers]]"],[oList])
oManyBack = oSerializer.callGeneric("Deserialize",["System.Collections.Generic.List`1[[AttributeHelpers.Person, AttributeHelpers]]"],[cMany])
dnAssert("a list of objects read back",oManyBack.Count,2)
dnAssert("the second object",oManyBack.Item(1).Name,"Bo")

# simple values
dnAssert("a number as bytes",len(oSerializer.callGeneric("Serialize",["System.Int32"],[300])),3)
dnAssert("a text read back",oSerializer.callGeneric("Deserialize",["System.String"],[oSerializer.callGeneric("Serialize",["System.String"],["héllo"])]),"héllo")

# a whole number of Ring is an Int32 where an object is expected (the MessagePack code of an int32 and 4 bytes: 5), not a Double (the code and 8 bytes: 9)
dnAssert("an object that holds a whole number",len(oSerializer.callGeneric("Serialize",["System.Object"],[5])),5)
dnAssert("an object that holds a number with a fraction",len(oSerializer.callGeneric("Serialize",["System.Object"],[2.5])),9)
dnAssert("a Double made exact by dnBox",len(oSerializer.callGeneric("Serialize",["System.Object"],[dnBox("System.Double",5)])),9)

# bytes that are not MessagePack are an error
try
	oSerializer.callGeneric("Deserialize",["AttributeHelpers.Person"],[char(255) + char(255)])
	dnAssert("bad bytes are an error",1,0)
catch
	dnAssert("bad bytes are an error",substr(cCatchError,"MessagePack") > 0,1)
done

dnTestSummary()
