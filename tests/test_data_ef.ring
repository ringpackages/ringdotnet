# Entity Framework Core with SQLite from Ring
load "../libraries/dotnetlib/dotnetlib.ring"
dnUseData()
dnImport("System")
dnImport("System.IO")

func main
	aSchema = [
		["Customers",[["Id","int",1],["Name","string",0],["Age","int",0],["City","string",0],["Balance","double",0],["Active","bool",0],["Joined","datetime",0]]],
		["Orders",[["Id","long",1],["CustomerId","int",0],["Total","decimal",0]]]
	]
	oDb = new RingDatabase("Data Source=:memory:",aSchema)
	nAnn = oDb.insert("Customers",[["Name","Ann"],["Age",31],["City","Cairo"],["Balance",10.5],["Active",1],["Joined","2024-03-05"]])
	nBob = oDb.insert("Customers",[["Name","Bob"],["Age",17],["City","Oslo"],["Balance",0],["Active",0]])
	nCy = oDb.insert("Customers",[["Name","Cy"],["Age",45],["City","Cairo"],["Balance",99.99],["Active",1]])
	dnAssert("generated keys",string(nAnn) + string(nBob) + string(nCy),"123")
	dnAssert("count",oDb.count("Customers"),3)

	aRow = oDb.byKey("Customers",nAnn)
	dnAssert("row by key",dbValue(aRow,"Name"),"Ann")
	dnAssert("double column",dbValue(aRow,"Balance"),10.5)
	dnAssert("bool column",dbValue(aRow,"Active"),1)
	dnAssert("datetime column",dbValue(aRow,"Joined"),"2024-03-05 00:00:00")
	dnAssert("missing row",oDb.byKey("Customers",99),"")

	dnAssert("all rows",len(oDb.all("Customers")),3)
	aAdults = oDb.where("Customers","Age >= {0} AND City = {1}",[18,"Cairo"])
	dnAssert("where with parameters",len(aAdults),2)
	dnAssert("where result",dbValue(aAdults[2],"Name"),"Cy")
	dnAssert("a quote in the data is not an injection",len(oDb.where("Customers","Name = {0}",["x' OR '1'='1"])),0)

	dnAssert("update",oDb.update("Customers",nBob,[["Age",18],["City","Bergen"]]),1)
	dnAssert("updated value",dbValue(oDb.byKey("Customers",nBob),"City"),"Bergen")
	dnAssert("update of a missing row",oDb.update("Customers",99,[["Age",1]]),0)

	dnAssert("delete",oDb.remove("Customers",nCy),1)
	dnAssert("count after delete",oDb.count("Customers"),2)

	# a second table with a long key and a decimal
	nOrder = oDb.insert("Orders",[["CustomerId",nAnn],["Total",19.99]])
	dnAssert("long key",nOrder,1)
	dnAssert("decimal column",dbValue(oDb.byKey("Orders",nOrder),"Total"),19.99)

	# SQL
	dnAssert("execute",oDb.execute("UPDATE Customers SET Age = Age + {0}",[1]),2)
	dnAssert("scalar",oDb.scalar("SELECT SUM(Age) FROM Customers"),51)

	oContext = oDb.context()
	dnAssert("the provider",oContext.Database.ProviderName,"Microsoft.EntityFrameworkCore.Sqlite")
	dnAssert("the provider",oDb.context().Database.ProviderName,"Microsoft.EntityFrameworkCore.Sqlite")
	oDb.close()

	# a database file survives the context
	cFile = new Path().Combine(new Path().GetTempPath(),"ringdotnet_ef_test.db")
	if new File().Exists(cFile)
		new File().Delete(cFile)
	ok
	oFile = new RingDatabase("Data Source=" + cFile,aSchema)
	oFile.insert("Customers",[["Name","Zed"],["Age",50]])
	oFile.close()
	oAgain = new RingDatabase("Data Source=" + cFile,aSchema)
	dnAssert("data in the file",dbValue(oAgain.all("Customers")[1],"Name"),"Zed")
	oAgain.close()
	new File().Delete(cFile)
	dnTestSummary()
