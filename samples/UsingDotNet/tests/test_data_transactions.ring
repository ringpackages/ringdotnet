# Entity Framework Core: transactions and async calls
load "dotnet.ring"
dnUseData()

func main

	oDb = new RingDatabase("Data Source=:memory:",[
		["Accounts",[["Id","int",1],["Owner","string",0],["Balance","double",0]]]
	])
	nA = oDb.insert("Accounts",[["Owner","A"],["Balance",100]])
	nB = oDb.insert("Accounts",[["Owner","B"],["Balance",50]])

	# a transfer that is committed
	oDb.begin()
	dnAssert("in a transaction",oDb.inTransaction(),1)
	oDb.update("Accounts",nA,[["Balance",70]])
	oDb.update("Accounts",nB,[["Balance",80]])
	oDb.commit()
	dnAssert("not in a transaction",oDb.inTransaction(),0)
	dnAssert("committed A",dbValue(oDb.byKey("Accounts",nA),"Balance"),70)
	dnAssert("committed B",dbValue(oDb.byKey("Accounts",nB),"Balance"),80)

	# a transfer that is rolled back
	oDb.begin()
	oDb.update("Accounts",nA,[["Balance",0]])
	oDb.insert("Accounts",[["Owner","C"],["Balance",1]])
	oDb.rollback()
	dnAssert("rolled back A",dbValue(oDb.byKey("Accounts",nA),"Balance"),70)
	dnAssert("rolled back insert",oDb.count("Accounts"),2)

	# an error inside the transaction
	oDb.begin()
	try
		oDb.update("Accounts",nA,[["Balance",1]])
		oDb.update("Accounts",nB,[["Nope",1]])
	catch
		oDb.rollback()
	done
	dnAssert("error: rolled back",dbValue(oDb.byKey("Accounts",nA),"Balance"),70)
	lFailed = false
	try
		oDb.commit()
	catch
		lFailed = true
	done
	dnAssert("commit without a transaction",lFailed,1)

	# manual saving: nothing is written before save
	oDb.autoSave(false)
	oDb.insert("Accounts",[["Owner","D"],["Balance",5]])
	oDb.insert("Accounts",[["Owner","E"],["Balance",6]])
	oDb.save()
	dnAssert("saved together",oDb.count("Accounts"),4)
	oDb.autoSave(true)

	# async
	oTask = oDb.insertAsync("Accounts",[["Owner","F"],["Balance",7]])
	dnAssert("async insert returns the key",dbWait(oTask),5)
	aRows = dbWait(oDb.allAsync("Accounts"))
	dnAssert("async all",len(aRows),5)
	dnAssert("async where",len(dbWait(oDb.whereAsync("Accounts","Balance > {0}",[60]))),2)
	dnAssert("async count",dbWait(oDb.countAsync("Accounts")),5)
	oDb.close()
	dnTestSummary()
