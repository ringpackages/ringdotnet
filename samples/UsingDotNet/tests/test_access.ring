# Microsoft Access through ODBC: a new .accdb file is made with ADOX (COM), then System.Data.Odbc is used for tables, rows with parameters,
# transactions, NULL and Unicode text. It needs Windows with the Microsoft Access Database Engine (ODBC driver and OLEDB provider, 64-bit):
# where they are not installed, the test says SKIPPED and passes.
load "dotnet.ring"

func main

	using {
		"System"
		"System.IO"
	}
	if not iswindows()
		? "SKIPPED: Microsoft Access needs Windows"
		return
	ok
	cDriver = "Microsoft Access Driver (*.mdb, *.accdb)"
	if not driverInstalled(cDriver)
		? "SKIPPED: the ODBC driver '" + cDriver + "' is not installed (install the 64-bit Microsoft Access Database Engine)"
		return
	ok
	dnLoad(dnRequest("bridgefolder",[]) + "/System.Data.Odbc.dll")          # System.Data.Odbc is a NuGet package, not part of the runtime

	cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet_test_access.accdb"])
	if new File().Exists(cFile)
		new File().Delete(cFile)
	ok
	if not createDatabase(cFile)
		? "SKIPPED: the ADOX component or the ACE OLEDB provider is not available, so a new Access file can not be made"
		return
	ok
	dnAssert("the .accdb file was created",new File().Exists(cFile),True)

	cConnection = "Driver={" + cDriver + "};Dbq=" + cFile + ";"
	oConnection = dnNew("System.Data.Odbc.OdbcConnection",[cConnection])
	oConnection.callMethod("Open",[])
	dnAssert("the connection is open",oConnection.getProp("State"),"Open")

	# table with several column types
	runSql(oConnection,"CREATE TABLE People (Id AUTOINCREMENT PRIMARY KEY, Name TEXT(50), Age INTEGER, Joined DATETIME, Active YESNO, Salary CURRENCY)",[])
	oJoined = new DateTime(2024,3,15)
	dnAssert("insert with parameters",runSql(oConnection,"INSERT INTO People (Name, Age, Joined, Active, Salary) VALUES (?, ?, ?, ?, ?)",["Ann",31,oJoined,True,1250.5]),1)
	dnAssert("insert with an apostrophe in the text",runSql(oConnection,"INSERT INTO People (Name, Age) VALUES (?, ?)",["O'Brien",45]),1)
	dnAssert("insert Unicode text (Arabic and accents)",runSql(oConnection,"INSERT INTO People (Name, Age) VALUES (?, ?)",[unicodeName(),28]),1)
	dnAssert("three rows",scalar(oConnection,"SELECT COUNT(*) FROM People",[]),3)

	# reading with a reader
	aRows = query(oConnection,"SELECT Id, Name, Age FROM People ORDER BY Id",[])
	dnAssert("first row name",aRows[1][2],"Ann")
	dnAssert("second row has the apostrophe",aRows[2][2],"O'Brien")
	dnAssert("third row has the Unicode text",aRows[3][2],unicodeName())
	dnAssert("AUTOINCREMENT numbers the rows one after the other",aRows[2][1] - aRows[1][1],1)
	dnAssert("a typed column: age as a number",aRows[2][3],45)
	dnAssert("filter with parameters",scalar(oConnection,"SELECT Name FROM People WHERE Age > ? AND Age < ?",[30,40]),"Ann")
	dnAssert("a currency column",scalar(oConnection,"SELECT Salary FROM People WHERE Name = ?",["Ann"]),1250.5)
	dnAssert("a yes/no column",scalar(oConnection,"SELECT Active FROM People WHERE Name = ?",["Ann"]),True)

	# NULL
	dnAssert("a column that was not given is NULL",scalarIsNull(oConnection,"SELECT Joined FROM People WHERE Name = ?",["O'Brien"]),True)
	dnAssert("a value is not NULL",scalarIsNull(oConnection,"SELECT Joined FROM People WHERE Name = ?",["Ann"]),False)
	dnAssert("COUNT(column) does not count NULL",scalar(oConnection,"SELECT COUNT(Joined) FROM People",[]),1)

	# update and delete
	dnAssert("update affects one row",runSql(oConnection,"UPDATE People SET Age = Age + 1 WHERE Name = ?",["Ann"]),1)
	dnAssert("the age changed",scalar(oConnection,"SELECT Age FROM People WHERE Name = ?",["Ann"]),32)
	dnAssert("delete affects one row",runSql(oConnection,"DELETE FROM People WHERE Name = ?",["O'Brien"]),1)
	dnAssert("two rows are left",scalar(oConnection,"SELECT COUNT(*) FROM People",[]),2)

	# a text that looks like an attack is only data when it is a parameter
	cAttack = "x'; DROP TABLE People; --"
	runSql(oConnection,"INSERT INTO People (Name, Age) VALUES (?, ?)",[cAttack,1])
	dnAssert("the attack text was stored as text",scalar(oConnection,"SELECT Name FROM People WHERE Age = ?",[1]),cAttack)
	dnAssert("the table is still there",scalar(oConnection,"SELECT COUNT(*) FROM People",[]),3)

	# a transaction: rolled back and committed
	oTransaction = oConnection.callMethod("BeginTransaction",[])
	runSqlIn(oConnection,oTransaction,"INSERT INTO People (Name, Age) VALUES (?, ?)",["Temporary",99])
	dnAssert("inside the transaction the row is visible",scalarIn(oConnection,oTransaction,"SELECT COUNT(*) FROM People",[]),4)
	oTransaction.callMethod("Rollback",[])
	dnAssert("after Rollback the row is gone",scalar(oConnection,"SELECT COUNT(*) FROM People",[]),3)
	oTransaction = oConnection.callMethod("BeginTransaction",[])
	runSqlIn(oConnection,oTransaction,"INSERT INTO People (Name, Age) VALUES (?, ?)",["Kept",77])
	oTransaction.callMethod("Commit",[])
	dnAssert("after Commit the row stays",scalar(oConnection,"SELECT COUNT(*) FROM People",[]),4)

	# an error is raised as a Ring error: a table that does not exist
	lError = False
	try
		runSql(oConnection,"SELECT * FROM NoSuchTable",[])
	catch
		lError = (substr(cCatchError,"NoSuchTable") > 0)
	done
	dnAssert("a missing table raises an error that names it",lError,True)

	# the data is in the file: close, open again, read
	oConnection.callMethod("Close",[])
	oConnection.callMethod("Dispose",[])
	oAgain = dnNew("System.Data.Odbc.OdbcConnection",[cConnection])
	oAgain.callMethod("Open",[])
	dnAssert("after reopening the file the rows are there",scalar(oAgain,"SELECT COUNT(*) FROM People",[]),4)
	dnAssert("the Unicode name survived the file",scalar(oAgain,"SELECT Name FROM People WHERE Age = ?",[28]),unicodeName())
	oAgain.callMethod("Close",[])
	oAgain.callMethod("Dispose",[])
	dnStatic("System.Data.Odbc.OdbcConnection","ReleaseObjectPool",[])          # let go of the connections that ODBC keeps for reuse
	# The Access engine keeps the file open until the program ends (it does not let go when the connections are closed), so the file can
	# not be deleted here. The next run deletes the old file first; the file in the temp folder is about 300 KB.
	dnTestSummary()

# ---------------------------------------------------------------- helpers

# an Arabic name and an accent, as UTF-8 bytes (a Ring text is a text of bytes)
func unicodeName

	return char(216) + char(163) + char(216) + char(173) + char(217) + char(133) + char(216) + char(175) + " Zo" + char(195) + char(171)

# is the ODBC driver registered? (the list of ODBC drivers is in the registry)
func driverInstalled cDriver

	try
		oMachine = dnType("Microsoft.Win32.Registry").getProp("LocalMachine")
		oKey = oMachine.callMethod("OpenSubKey",["SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers"])
		if oKey.isNull()
			return false
		ok
		xValue = oKey.callMethod("GetValue",[cDriver])
		if isObject(xValue)
			return not xValue.isNull()
		ok
		return true
	catch
		return false
	done

# a new Access file made with ADOX (a COM component of Windows); false when it is not available
func createDatabase cFile

	try
		oType = dnStatic("System.Type","GetTypeFromProgID",["ADOX.Catalog"])
		if oType.isNull()
			return false
		ok
		oCatalog = dnStatic("System.Activator","CreateInstance",[oType])
		oType.callMethod("InvokeMember",["Create","InvokeMethod",dnNull(),oCatalog,["Provider=Microsoft.ACE.OLEDB.16.0;Data Source=" + cFile]])
		return new File().Exists(cFile)
	catch
		return false
	done

func makeCommand oConnection,cSql,aValues

	oCommand = oConnection.callMethod("CreateCommand",[])
	oCommand.setProp("CommandText",cSql)
	oParameters = oCommand.getProp("Parameters")
	nNumber = 0
	for xValue in aValues
		nNumber++
		oParameters.callMethod("AddWithValue",["p" + nNumber,xValue])
	next
	return oCommand

func runSql oConnection,cSql,aValues

	return makeCommand(oConnection,cSql,aValues).callMethod("ExecuteNonQuery",[])

func scalar oConnection,cSql,aValues

	return makeCommand(oConnection,cSql,aValues).callMethod("ExecuteScalar",[])

# True when the answer is NULL (a column without a value comes back as System.DBNull)
func scalarIsNull oConnection,cSql,aValues

	xValue = makeCommand(oConnection,cSql,aValues).callMethod("ExecuteScalar",[])
	if isObject(xValue)
		return xValue.isNull() or (xValue.typeName() = "System.DBNull")
	ok
	return false

func runSqlIn oConnection,oTransaction,cSql,aValues

	oCommand = makeCommand(oConnection,cSql,aValues)
	oCommand.setProp("Transaction",oTransaction)
	return oCommand.callMethod("ExecuteNonQuery",[])

func scalarIn oConnection,oTransaction,cSql,aValues

	oCommand = makeCommand(oConnection,cSql,aValues)
	oCommand.setProp("Transaction",oTransaction)
	return oCommand.callMethod("ExecuteScalar",[])

# all the rows as a list of lists (id, text, number)
func query oConnection,cSql,aValues

	aRows = []
	oReader = makeCommand(oConnection,cSql,aValues).callMethod("ExecuteReader",[])
	while oReader.callMethod("Read",[])
		aRows + [ oReader.callMethod("GetInt32",[0]), oReader.callMethod("GetString",[1]), oReader.callMethod("GetInt32",[2]) ]
	end
	oReader.callMethod("Dispose",[])
	return aRows
