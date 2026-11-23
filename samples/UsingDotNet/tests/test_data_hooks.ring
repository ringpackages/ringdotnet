# Entity Framework Core: hooks (saving, saved, log), global query filters, value converters
load "dotnet.ring"
dnUseData()

aSeen = []
nSaved = 0
aSql = []

func main

	oDb = new RingDatabase("Data Source=:memory:",[
		["Notes",[["Id","int",1],["Text","string",0],["Deleted","int",0]],[["filter",["Deleted","=",0]]]],
		["Users",[["Id","int",1],["Name","string",0,[["convert","upper"]]],["Secret","string",0,[["convert",[dnCallback("hide"),dnCallback("reveal")]]]]]]
	])

	# global query filter
	oDb.insert("Notes",[["Text","keep"],["Deleted",0]])
	oDb.insert("Notes",[["Text","hidden"],["Deleted",1]])
	dnAssert("filter on all",len(oDb.all("Notes")),1)
	dnAssert("filter on count",oDb.count("Notes"),1)
	dnAssert("filter on query",len(oDb.query("Notes",[ ["where",["Text","contains","e"]] ])),1)
	dnAssert("a key lookup is not filtered (EF Find)",dbValue(oDb.byKey("Notes",2),"Text"),"hidden")
	dnAssert("filter ignored on request",len(oDb.query("Notes",[ ["ignorefilters",1] ])),2)

	# converters: upper is applied when saving; the Ring pair stores the text reversed
	nUser = oDb.insert("Users",[["Name","ann"],["Secret","abc"]])
	dnAssert("upper converter",dbValue(oDb.all("Users")[1],"Name"),"ANN")
	dnAssert("Ring converter (read back)",dbValue(oDb.all("Users")[1],"Secret"),"abc")
	dnAssert("stored form",dbValue(oDb.sqlRows("SELECT Secret FROM Users",[])[1],"Secret"),"cba")
	dnAssert("query with a converted column",len(oDb.query("Users",[ ["where",["Name","=","ann"]] ])),1)

	# hooks
	oDb.onSaving(dnCallback("beforeSave"))
	oDb.onSaved(dnCallback("afterSave"))
	oDb.onLog(dnCallback("logSql"))
	oDb.insert("Users",[["Name","bob"],["Secret","x"]])
	dnAssert("saving hook saw one change",len(aSeen),1)
	dnAssert("the table",aSeen[1][1],"Users")
	dnAssert("the state",aSeen[1][2],"Added")
	dnAssert("the row",dbValue(aSeen[1][3],"Name"),"bob")
	dnAssert("saved hook",nSaved,1)
	dnAssert("log hook saw SQL",len(aSql) > 0,1)
	dnAssert("the SQL is an INSERT",substr(aSql[1],"INSERT") > 0,1)

	# a hook can cancel the save
	lFailed = false
	try
		oDb.insert("Users",[["Name","forbidden"],["Secret","x"]])
	catch
		lFailed = true
	done
	dnAssert("the save was canceled",lFailed,1)
	dnAssert("nothing was stored",oDb.count("Users"),2)

	# pending changes with manual saving
	oDb.autoSave(false)
	oDb.insert("Users",[["Name","cy"],["Secret","y"]])
	oDb.update("Users",nUser,[["Name","annie"]])
	aPending = oDb.pendingChanges()
	dnAssert("pending changes",len(aPending),2)
	dnAssert("pending states",aPending[1][2] + aPending[2][2],"AddedModified")
	oDb.save()
	dnAssert("saved",oDb.count("Users"),3)
	oDb.close()
	dnTestSummary()

func hide aArgs

	return reverse(aArgs[1])

func reveal aArgs

	return reverse(aArgs[1])

func beforeSave aArgs

	aSeen = aArgs[1]
	if len(aSeen) > 0 and dbValue(aSeen[1][3],"Name") = "forbidden"
		return "forbidden user"
	ok
	return ""

func afterSave aArgs

	nSaved += aArgs[1]

func logSql aArgs

	aSql + aArgs[1]
