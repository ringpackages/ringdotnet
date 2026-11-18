# Entity Framework Core: migrations (schema evolution of an existing database)
load "dotnetlib.ring"
dnUseData()
dnImport("System.IO")

func main
	cFile = new Path().Combine(new Path().GetTempPath(),"ringdotnet_migrate_test.db")
	if new File().Exists(cFile)
		new File().Delete(cFile)
	ok
	cConnection = "Data Source=" + cFile

	# version 1
	oDb = new RingDatabase(cConnection,[
		["Users",[["Id","int",1],["Name","string",0]]]
	])
	oDb.insert("Users",[["Name","Ann"]])
	oDb.insert("Users",[["Name","Bob"]])
	dnAssert("nothing to migrate",len(oDb.migrate()),0)
	oDb.close()

	# version 2: a new column, a column with a default, a new table, an index
	oDb = new RingDatabase(cConnection,[
		["Users",[["Id","int",1],["Name","string",0,[["index",1]]],["Email","string",0],["Level","int",0,[["default",3]]],["Age","int",0,[["nullable",1]]]]],
		["Notes",[["Id","int",1],["Text","string",0],["UserId","int",0,[["references","Users"]]]]]
	])
	aChanges = oDb.migrate()
	dnAssert("number of changes",len(aChanges),6)
	dnAssert("first change",aChanges[1],"add column Users.Email")
	dnAssert("a new table",aChanges[4],"create table Notes")
	dnAssert("existing rows are kept",oDb.count("Users"),2)
	aRow = oDb.byKey("Users",1)
	dnAssert("old column",dbValue(aRow,"Name"),"Ann")
	dnAssert("new text column",dbValue(aRow,"Email"),"")
	dnAssert("new column with a default",dbValue(aRow,"Level"),3)
	dnAssert("new nullable column",dbValue(aRow,"Age"),"")
	oDb.update("Users",1,[["Email","ann@x.com"],["Age",30]])
	dnAssert("the new column works",dbValue(oDb.byKey("Users",1),"Email"),"ann@x.com")
	oDb.insert("Notes",[["Text","hello"],["UserId",1]])
	dnAssert("the new table works",oDb.count("Notes"),1)
	dnAssert("the new table has its foreign key",len(oDb.children("Users",1,"Notes")),1)
	dnAssert("migrating again changes nothing",len(oDb.migrate()),0)

	# named changes are applied once
	dnAssert("apply",oDb.apply("001-level","UPDATE Users SET Level = 9"),1)
	dnAssert("the change was made",dbValue(oDb.byKey("Users",2),"Level"),9)
	dnAssert("apply again",oDb.apply("001-level","UPDATE Users SET Level = 1"),0)
	dnAssert("not applied twice",dbValue(oDb.byKey("Users",2),"Level"),9)
	lFailed = false
	try
		oDb.apply("002-broken","UPDATE Nothing SET X = 1")
	catch
		lFailed = true
	done
	dnAssert("a broken change fails",lFailed,1)
	dnAssert("a broken change is not recorded",len(oDb.applied()),1)
	oDb.close()
	new File().Delete(cFile)
	dnTestSummary()
