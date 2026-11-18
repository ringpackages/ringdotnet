# Entity Framework Core: providers (sqlite, inmemory, and a provider whose package is missing)
load "dotnetlib.ring"
dnUseData()

func main
	aSchema = [
		["Items",[["Id","int",1],["Name","string",0],["Price","double",0]]]
	]
	oDb = new RingDatabase("inmemory:shop",aSchema)
	dnAssert("the provider",oDb.context().Database.ProviderName,"Microsoft.EntityFrameworkCore.InMemory")
	nId = oDb.insert("Items",[["Name","pen"],["Price",1.5]])
	oDb.insert("Items",[["Name","book"],["Price",12]])
	dnAssert("insert",nId,1)
	dnAssert("count",oDb.count("Items"),2)
	dnAssert("by key",dbValue(oDb.byKey("Items",2),"Name"),"book")
	oDb.update("Items",nId,[["Price",2]])
	dnAssert("update",dbValue(oDb.byKey("Items",nId),"Price"),2)
	dnAssert("all",len(oDb.all("Items")),2)
	oDb.remove("Items",nId)
	dnAssert("remove",oDb.count("Items"),1)

	# the same name is the same in-memory database; another name is another one
	oSame = new RingDatabase("inmemory:shop",aSchema)
	dnAssert("the same in-memory database",oSame.count("Items"),1)
	oOther = new RingDatabase("inmemory:other",aSchema)
	dnAssert("another in-memory database",oOther.count("Items"),0)

	# what an in-memory database cannot do is an error, not a wrong answer
	lFailed = false
	try
		oDb.where("Items","Price > {0}",[1])
	catch
		lFailed = true
	done
	dnAssert("SQL is not available in memory",lFailed,1)
	lFailed = false
	try
		oDb.migrate()
	catch
		lFailed = true
	done
	dnAssert("migrate is for sqlite",lFailed,1)

	# a provider whose package is not installed
	cMessage = ""
	try
		oSql = new RingDatabase("sqlserver:Server=.;Database=x",aSchema)
	catch
		cMessage = cCatchError
	done
	dnAssert("a missing package is explained",substr(cMessage,"Microsoft.EntityFrameworkCore.SqlServer") > 0,1)
	lFailed = false
	try
		oX = new RingDatabase("nosuch:x",aSchema)
	catch
		lFailed = true
	done
	dnAssert("an invalid connection",lFailed,1)

	# sqlite is the default
	oLite = new RingDatabase("Data Source=:memory:",aSchema)
	dnAssert("default provider",oLite.context().Database.ProviderName,"Microsoft.EntityFrameworkCore.Sqlite")
	oLite.close()
	oDb.close()
	dnTestSummary()
