# Entity Framework Core: queries as expression trees, aggregates, any-shape SQL, dates and bytes
load "dotnet.ring"
dnUseData()

func main

	aSchema = [
		["People",[["Id","int",1],["Name","string",0],["Age","int",0],["City","string",0],["Score","double",0],["Joined","datetime",0],["Boss","int",0,[["nullable",1]]],["Photo","bytes",0,[["nullable",1]]]]]
	]
	for cProvider in ["Data Source=:memory:","inmemory:q"]
		oDb = new RingDatabase(cProvider,aSchema)
		oDb.insert("People",[["Name","Ann"],["Age",31],["City","Cairo"],["Score",8.5],["Joined","2020-01-15 10:30:00"]])
		oDb.insert("People",[["Name","Bob"],["Age",17],["City","Oslo"],["Score",6],["Joined","2021-06-01"],["Boss",1]])
		oDb.insert("People",[["Name","Cy"],["Age",45],["City","Cairo"],["Score",9],["Joined","2019-03-09"],["Boss",1]])
		oDb.insert("People",[["Name","Dee"],["Age",28],["City","Giza"],["Score",7.5],["Joined","2022-12-31"]])
		cKind = cProvider

		aRows = oDb.query("People",[ ["where",["Age",">=",28]] ])
		dnAssert(cKind + " >=",len(aRows),3)
		aRows = oDb.query("People",[ ["where",["and",["Age",">",20],["City","=","Cairo"]]] ])
		dnAssert(cKind + " and",len(aRows),2)
		aRows = oDb.query("People",[ ["where",["or",["City","=","Oslo"],["Name","=","Dee"]]] ])
		dnAssert(cKind + " or",len(aRows),2)
		aRows = oDb.query("People",[ ["where",["not",["City","=","Cairo"]]] ])
		dnAssert(cKind + " not",len(aRows),2)
		aRows = oDb.query("People",[ ["where",["City","in",["Oslo","Giza"]]] ])
		dnAssert(cKind + " in",len(aRows),2)
		aRows = oDb.query("People",[ ["where",["Name","startswith","C"]] ])
		dnAssert(cKind + " startswith",dbValue(aRows[1],"Name"),"Cy")
		aRows = oDb.query("People",[ ["where",["Name","contains","e"]] ])
		dnAssert(cKind + " contains",len(aRows),1)
		aRows = oDb.query("People",[ ["where",["Boss","isnull"]] ])
		dnAssert(cKind + " isnull",len(aRows),2)
		aRows = oDb.query("People",[ ["where",["Boss","notnull"]] ])
		dnAssert(cKind + " notnull",len(aRows),2)
		aRows = oDb.query("People",[ ["where",["Boss","=",1]] ])
		dnAssert(cKind + " nullable =",len(aRows),2)
		aRows = oDb.query("People",[ ["where",["Joined",">","2020-06-01"]] ])
		dnAssert(cKind + " datetime",len(aRows),2)

		aRows = oDb.query("People",[ ["orderby",[["Age","desc"]]] ])
		dnAssert(cKind + " order desc",dbValue(aRows[1],"Name"),"Cy")
		aRows = oDb.query("People",[ ["orderby",[["City","asc"],["Age","desc"]]] ])
		dnAssert(cKind + " order by two",dbValue(aRows[1],"Name"),"Cy")
		aRows = oDb.query("People",[ ["orderby",[["Age","asc"]]], ["skip",1], ["take",2] ])
		dnAssert(cKind + " skip take",dbValue(aRows[1],"Name") + dbValue(aRows[2],"Name"),"DeeAnn")
		aRows = oDb.query("People",[ ["where",["City","=","Cairo"]], ["select",["Name","Age"]] ])
		dnAssert(cKind + " select",len(aRows[1]),2)
		dnAssert(cKind + " select value",dbValue(aRows[1],"Age"),31)

		dnAssert(cKind + " count",oDb.countWhere("People",["City","=","Cairo"]),2)
		dnAssert(cKind + " count all",oDb.countWhere("People",[]),4)
		dnAssert(cKind + " sum int",oDb.sum("People","Age",[]),121)
		dnAssert(cKind + " sum double",oDb.sum("People","Score",["City","=","Cairo"]),17.5)
		dnAssert(cKind + " min",oDb.min("People","Age",[]),17)
		dnAssert(cKind + " max",oDb.max("People","Score",[]),9)
		dnAssert(cKind + " average",oDb.average("People","Age",["City","=","Cairo"]),38)
		dnAssert(cKind + " max date",oDb.max("People","Joined",[]),"2022-12-31 00:00:00")
		aGroups = oDb.groupCount("People","City",[])
		dnAssert(cKind + " group count",aGroups[1][1] + aGroups[1][2],"Cairo2")
		dnAssert(cKind + " groups",len(aGroups),3)

		# datetime and bytes round trip
		dnAssert(cKind + " datetime",dbValue(oDb.byKey("People",1),"Joined"),"2020-01-15 10:30:00")
		oDb.update("People",1,[["Photo",str2hex("AB" + char(0) + "CD" + char(255))]])
		cPhoto = hex2str(dbValue(oDb.byKey("People",1),"Photo"))
		dnAssert(cKind + " bytes length",len(cPhoto),6)
		dnAssert(cKind + " bytes",ascii(cPhoto[3]) + ascii(cPhoto[6]),255)
		oDb.close()
	next

	# SQL with any result shape
	oDb = new RingDatabase("Data Source=:memory:",aSchema)
	oDb.insert("People",[["Name","Ann"],["Age",31],["City","Cairo"],["Score",8.5],["Joined","2020-01-15"]])
	oDb.insert("People",[["Name","Cy"],["Age",45],["City","Cairo"],["Score",9],["Joined","2019-03-09"]])
	oDb.insert("People",[["Name","Dee"],["Age",28],["City","Giza"],["Score",7.5],["Joined","2022-12-31"]])
	aRows = oDb.sqlRows("SELECT City, COUNT(*) AS N, AVG(Age) AS A FROM People WHERE Age > {0} GROUP BY City ORDER BY City",[20])
	dnAssert("sqlRows groups",len(aRows),2)
	dnAssert("sqlRows city",dbValue(aRows[1],"City"),"Cairo")
	dnAssert("sqlRows count",dbValue(aRows[1],"N"),2)
	dnAssert("sqlRows average",dbValue(aRows[1],"A"),38)
	dnAssert("sqlRows a string parameter",len(oDb.sqlRows("SELECT Name FROM People WHERE City = {0}",["Giza"])),1)
	oDb.close()
	dnTestSummary()
