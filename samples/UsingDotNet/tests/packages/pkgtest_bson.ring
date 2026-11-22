# Newtonsoft.Json.Bson: a JSON writer that makes BSON bytes into a memory stream, and a reader that reads them back
load "pkg.ring"
pkgUse("bson",[["Newtonsoft.Json.Bson","1.0.3"],["Newtonsoft.Json","13.0.4"]],[["Newtonsoft.Json.dll",["Newtonsoft.Json"]],["Newtonsoft.Json.Bson.dll",["Newtonsoft.Json.Bson"]]])
pkgImport("bson","Newtonsoft.Json.dll","Newtonsoft.Json")
pkgImport("bson","Newtonsoft.Json.Bson.dll","Newtonsoft.Json.Bson")

oStream = dnNew("System.IO.MemoryStream",[])
oWriter = new BsonDataWriter(oStream)
oSerializer = new JsonJsonSerializer()
oData = dnNew("System.Collections.Generic.Dictionary`2[[System.String],[System.Object]]",[])
oData.SetItem("name","Ann")
oData.SetItem("age",30)
oSerializer.Serialize([ :jsonWriter = oWriter, :value = oData ])
oWriter.Flush()
cBytes = oStream.ToArray()
dnAssert("the bytes of a document",len(cBytes) > 20,1)
dnAssert("a BSON document starts with its length",ascii(cBytes[1]),len(cBytes))

oRead = dnNew("System.IO.MemoryStream",[cBytes])
oReader = new BsonDataReader(oRead)
oBack = oSerializer.callGeneric("Deserialize",["System.Collections.Generic.Dictionary`2[[System.String],[System.Object]]"],[oReader])
dnAssert("a text is read back",oBack.Item("name"),"Ann")
dnAssert("a number is read back",oBack.Item("age"),30)

dnTestSummary()
