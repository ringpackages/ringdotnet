# Entity Framework Core: column options (required, nullable, unique, index, maxlength, default) and composite keys
load "dotnetlib.ring"
dnUseData()

func main
	aSchema = [
		["Users",[
			["Id","int",1],
			["Email","string",0,[["required",1],["unique",1],["maxlength",40]]],
			["Name","string",0,[["index",1],["default","anonymous"]]],
			["Age","int",0,[["nullable",1]]],
			["Level","int",0,[["default",5]]]
		]],
		["Enrollments",[
			["StudentId","int",1],
			["CourseId","int",1],
			["Grade","double",0,[["nullable",1]]]
		]]
	]
	oDb = new RingDatabase("Data Source=:memory:",aSchema)
	nId = oDb.insert("Users",[["Email","a@x.com"]])
	aRow = oDb.byKey("Users",nId)
	dnAssert("default text",dbValue(aRow,"Name"),"anonymous")
	dnAssert("default number",dbValue(aRow,"Level"),5)
	dnAssert("nullable column is empty",dbValue(aRow,"Age"),"")
	oDb.update("Users",nId,[["Age",30]])
	dnAssert("nullable column set",dbValue(oDb.byKey("Users",nId),"Age"),30)
	oDb.update("Users",nId,[["Age",dnNull()]])
	dnAssert("nullable column cleared",dbValue(oDb.byKey("Users",nId),"Age"),"")

	# unique
	lFailed = false
	try
		oDb.insert("Users",[["Email","a@x.com"]])
	catch
		lFailed = true
	done
	dnAssert("unique index rejects a duplicate",lFailed,1)
	dnAssert("the failed row is not stored",oDb.count("Users"),1)
	oDb.discard()

	# required
	lFailed = false
	try
		oDb.insert("Users",[["Name","no email"]])
	catch
		lFailed = true
	done
	dnAssert("required column",lFailed,1)
	oDb.discard()

	# max length is part of the model
	dnAssert("max length",dbValue(oDb.columnInfo("Users","Email"),"maxlength"),40)

	# composite key
	oDb.insert("Enrollments",[["StudentId",1],["CourseId",10],["Grade",3.5]])
	oDb.insert("Enrollments",[["StudentId",1],["CourseId",11]])
	oDb.insert("Enrollments",[["StudentId",2],["CourseId",10],["Grade",4]])
	dnAssert("composite key row",dbValue(oDb.byKey("Enrollments",[1,10]),"Grade"),3.5)
	dnAssert("composite key missing",oDb.byKey("Enrollments",[9,9]),"")
	oDb.update("Enrollments",[1,11],[["Grade",2]])
	dnAssert("composite key update",dbValue(oDb.byKey("Enrollments",[1,11]),"Grade"),2)
	dnAssert("composite key delete",oDb.remove("Enrollments",[2,10]),1)
	dnAssert("composite key count",oDb.count("Enrollments"),2)
	lFailed = false
	try
		oDb.insert("Enrollments",[["StudentId",1],["CourseId",10]])
	catch
		lFailed = true
	done
	dnAssert("composite key is unique",lFailed,1)
	oDb.discard()
	oDb.close()
	dnTestSummary()
