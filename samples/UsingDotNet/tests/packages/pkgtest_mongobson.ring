# MongoDB.Bson: documents parsed from JSON and built in code, values, arrays, object identifiers and JSON text (no database is used)
load "pkg.ring"
pkgUse("mongobson",[["MongoDB.Bson","3.1.0"]],[["MongoDB.Bson.dll",["MongoDB.Bson","MongoDB.Bson.IO","MongoDB.Bson.Serialization"]]])
pkgImport("mongobson","MongoDB.Bson.dll","MongoDB.Bson")
pkgImport("mongobson","MongoDB.Bson.dll","MongoDB.Bson.IO")
pkgImport("mongobson","MongoDB.Bson.dll","MongoDB.Bson.Serialization")

oDoc = (new BsonDocument).Parse('{ "name": "Ring", "year": 2016, "pi": 3.5, "ok": true, "tags": ["a","b","c"], "inner": { "x": 1 } }')
dnAssert("the number of elements",oDoc.ElementCount,6)
dnAssert("a text value",oDoc.GetValue("name").AsString,"Ring")
dnAssert("a whole number",oDoc.GetValue("year").AsInt32,2016)
dnAssert("a double",oDoc.GetValue("pi").AsDouble,3.5)
dnAssert("a boolean",oDoc.GetValue("ok").AsBoolean,True)
dnAssert("a name that is there",oDoc.Contains("tags"),True)
dnAssert("a name that is not there",oDoc.Contains("nothing"),False)

oTags = oDoc.GetValue("tags").AsBsonArray
dnAssert("an array: the count",oTags.Count,3)
dnAssert("an array: an item",oTags.Values.toList()[2].AsString,"b")
oInner = oDoc.GetValue("inner").AsBsonDocument
dnAssert("a nested document",oInner.GetValue("x").AsInt32,1)

# a document built in code
oNew = new BsonDocument()
oNew.Set("city","Cairo")
oNew.Set("people",(new BsonValue).Create(20))
dnAssert("a built document: a text",oNew.GetValue("city").AsString,"Cairo")
dnAssert("a built document: a number",oNew.GetValue("people").AsInt32,20)
dnAssert("a built document: the count",oNew.ElementCount,2)
cJson = oNew.ToString()
dnAssert("the JSON text has the name",substr(cJson,"city") > 0,True)
oBack = (new BsonDocument).Parse(cJson)
dnAssert("the JSON text is parsed back",oBack.GetValue("city").AsString,"Cairo")

# object identifiers: 24 hexadecimal characters, made from the time, a random value and a counter
oId = dnStatic("MongoDB.Bson.ObjectId","GenerateNewId",[])
cId = oId.ToString()
dnAssert("an object id has 24 characters",len(cId),24)
oSame = (new ObjectId).Parse(cId)
dnAssert("parse gives the same id",oSame.ToString(),cId)
dnAssert("two ids are different",dnStatic("MongoDB.Bson.ObjectId","GenerateNewId",[]).ToString() != cId,True)
dnAssert("the time of an id is this year",oId.CreationTime.Year >= 2024,True)
dnAssert("a fixed id",(new ObjectId).Parse("507f1f77bcf86cd799439011").Timestamp,1350508407)

# a missing name is an error
lError = 0
try
	oDoc.GetValue("missing")
catch
	lError = 1
done
dnAssert("a missing element raises an error",lError,1)

dnTestSummary()
