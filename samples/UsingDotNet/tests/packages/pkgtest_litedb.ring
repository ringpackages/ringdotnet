# LiteDB: a document database in memory (a MemoryStream is the file): documents, ids, queries in the LiteDB language, updates, deletes, indexes, and a query with Where
load "pkg.ring"
pkgUse("litedb",[["LiteDB","5.0.21"]],[["LiteDB.dll",["LiteDB"]]])
pkgImport("litedb","LiteDB.dll","LiteDB")
dnImport("System.IO")

oStream = new MemoryStream()
oDb = dnNew("LiteDB.LiteDatabase",[oStream])
oPeople = oDb.GetCollection([ :name = "people" ])
dnAssert("an empty collection",oPeople.callMethod("Count",[]),0)

# insert documents: each has a generated id
for aPerson in [ ["Ann",31,"Cairo"], ["Bo",25,"Giza"], ["Cy",40,"Cairo"], ["Di",19,"Luxor"] ]
	oDocument = new BsonDocument()
	oDocument.Add([ :key = "name", :value = aPerson[1] ])
	oDocument.Add([ :key = "age", :value = aPerson[2] ])
	oDocument.Add([ :key = "city", :value = aPerson[3] ])
	oPeople.callMethod("Insert",[oDocument])
next
dnAssert("four documents",oPeople.callMethod("Count",[]),4)

# a query in the language of LiteDB
oOlder = oPeople.callMethod("Find",[ new BsonExpression().Create("$.age >= 30") ])
aOlder = oOlder.toList()
dnAssert("two people are 30 or more",len(aOlder),2)
aNames = []
for oRow in aOlder
	add(aNames,oRow.Item("name").AsString)
next
dnAssert("their names",find(aNames,"Ann") > 0 and find(aNames,"Cy") > 0,1)

# the same query with the city
dnAssert("people of Cairo",len(oPeople.callMethod("Find",[ new BsonExpression().Create("$.city = 'Cairo'") ]).toList()),2)

# find one by an id (the generated id is a number of the database)
oFirst = oPeople.callMethod("FindOne",[ new BsonExpression().Create("$.name = 'Bo'") ])
dnAssert("a field of a document",oFirst.Item("age").AsInt32,25)
oId = oFirst.Item("_id")
oById = oPeople.callMethod("FindById",[oId])
dnAssert("a document by its id",oById.Item("name").AsString,"Bo")

# update and delete
oFirst.SetItem("age",26)
oPeople.callMethod("Update",[oFirst])
dnAssert("an updated field",oPeople.callMethod("FindById",[oId]).Item("age").AsInt32,26)
nDeleted = oPeople.callMethod("DeleteMany",[ new BsonExpression().Create("$.age < 20") ])
dnAssert("a document was deleted",nDeleted,1)
dnAssert("three documents are left",oPeople.callMethod("Count",[]),3)

# an index and a count by a query
oPeople.callMethod("EnsureIndex",[ "city" ])
dnAssert("an indexed collection counts the same",oPeople.callMethod("Count",[ new BsonExpression().Create("$.city = 'Cairo'") ]),2)
dnAssert("the collection exists in the database",oDb.CollectionExists("people"),1)
dnAssert("and a collection that is not there does not",oDb.CollectionExists("nothing"),0)

oDb.Dispose()
dnTestSummary()
