# Microsoft Access databases - an .accdb file through ODBC: tables, parameters, joins, totals, dates, transactions
# (Windows only: it needs the Microsoft Access Database Engine; anywhere else the program says why it stops)
load "dotnet.ring"
using {
	"System"
	"System.IO"
}

func main
	# 0. What the program needs. Without it, it stops with a message and no error.
	cDriver = "Microsoft Access Driver (*.mdb, *.accdb)"
	if not iswindows()
		? "This tutorial needs Windows: the Microsoft Access drivers exist only there."
		return
	ok
	if not driverInstalled(cDriver)
		? "The ODBC driver '" + cDriver + "' is not installed."
		? "Install the Microsoft Access Database Engine (64-bit, like Ring and .NET) and run the program again."
		return
	ok
	dnLoad(dnRequest("bridgefolder",[]) + "/System.Data.Odbc.dll")          # System.Data.Odbc is a NuGet package, it is not part of the runtime

	# 1. A new Access file. The ODBC driver opens files but can not create one, so ADOX (a COM component that comes with Access) does it.
	cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet_tutorial115.accdb"])
	if new File().Exists(cFile)
		new File().Delete(cFile)
	ok
	if not createDatabase(cFile)
		? "A new Access file could not be made (the ADOX component or the ACE OLEDB provider is missing)."
		return
	ok
	? "1. the database file was created: " + new File().Exists(cFile)

	# 2. The connection string names the driver and the file (Dbq). The ODBC classes have no generated Ring classes: dnNew makes the
	#    objects and callMethod / getProp use them.
	oConnection = dnNew("System.Data.Odbc.OdbcConnection",["Driver={" + cDriver + "};Dbq=" + cFile + ";"])
	oConnection.Open()
	? "   the connection is: " + oConnection.State

	# 3. Tables. Access has its own names for the column types: AUTOINCREMENT (a number that counts by itself), TEXT(n), LONG (a whole
	#    number), CURRENCY (money with 4 decimals, exact), DATETIME, YESNO.
	runSql(oConnection,"CREATE TABLE Customers (Id AUTOINCREMENT PRIMARY KEY, Name TEXT(40), City TEXT(30), Vip YESNO)",[])
	runSql(oConnection,"CREATE TABLE Orders (Id AUTOINCREMENT PRIMARY KEY, CustomerId LONG, Total CURRENCY, Ordered DATETIME)",[])
	? nl + "2. tables: " + joinList(tableNames(oConnection))
	? "   columns of Orders: " + joinList(columnNames(oConnection,"Orders"))

	# 4. Rows go in with PARAMETERS: a ? in the statement and the values in a list. Never join values into the text of the statement:
	#    a name with an apostrophe would break it, and a bad text could change what the statement does.
	aCustomers = [ ["Ann","Cairo",True], ["Bob O'Neil","Alexandria",False], [arabicName(),"Cairo",True], ["Dina","Giza",False] ]
	for aCustomer in aCustomers
		runSql(oConnection,"INSERT INTO Customers (Name, City, Vip) VALUES (?, ?, ?)",aCustomer)
	next
	aOrders = [ [1,120.5,2024,1,15], [1,80,2024,2,3], [2,45.25,2024,2,10], [3,300,2024,3,1], [3,19.99,2024,3,20], [1,60,2024,4,2] ]
	for aOrder in aOrders
		runSql(oConnection,"INSERT INTO Orders (CustomerId, Total, Ordered) VALUES (?, ?, ?)",[aOrder[1],aOrder[2],new DateTime(aOrder[3],aOrder[4],aOrder[5])])
	next
	? nl + "3. rows: " + scalar(oConnection,"SELECT COUNT(*) FROM Customers",[]) + " customers, " + scalar(oConnection,"SELECT COUNT(*) FROM Orders",[]) + " orders"

	# 5. A query gives rows. Reading goes through a reader: Read() moves to the next row and GetValue(n) reads a column (0 is the first).
	? nl + "4. the customers in Cairo, by name:"
	for aRow in rows(oConnection,"SELECT Id, Name, City FROM Customers WHERE City = ? ORDER BY Name",["Cairo"])
		? "   " + aRow[1] + ": " + aRow[2] + " (" + aRow[3] + ")"
	next
	? "   the apostrophe and the Arabic name came back as they went in: " + (scalar(oConnection,"SELECT Name FROM Customers WHERE Id = ?",[2]) = "Bob O'Neil") + ", " + (scalar(oConnection,"SELECT Name FROM Customers WHERE Id = ?",[3]) = arabicName())

	# 6. A join puts the data of two tables side by side
	? nl + "5. each order with its customer (INNER JOIN):"
	for aRow in rows(oConnection,"SELECT c.Name, o.Total, o.Ordered FROM Customers AS c INNER JOIN Orders AS o ON c.Id = o.CustomerId ORDER BY o.Ordered",[])
		? "   " + padRight(shortName(aRow[1]),12) + padLeft(money(aRow[2]),8) + "   " + aRow[3]
	next

	# 7. Totals: GROUP BY makes one row for each customer, with SUM, COUNT and AVG. HAVING filters the groups.
	? nl + "6. orders for each customer (customers with 2 orders or more):"
	for aRow in rows(oConnection,"SELECT c.Name, COUNT(*) AS Orders, SUM(o.Total) AS Total, AVG(o.Total) AS Average FROM Customers AS c INNER JOIN Orders AS o ON c.Id = o.CustomerId GROUP BY c.Name HAVING COUNT(*) >= ? ORDER BY SUM(o.Total) DESC",[2])
		? "   " + padRight(shortName(aRow[1]),12) + aRow[2] + " orders, total " + money(aRow[3]) + ", average " + money(aRow[4])
	next

	# 8. TOP n is Access's way to say "the first n rows" (there is no LIMIT). LIKE searches with % for any characters (ODBC style).
	? nl + "7. the 2 biggest orders: " + joinList(columnOf(rows(oConnection,"SELECT TOP 2 Total FROM Orders ORDER BY Total DESC",[]),1,"money"))
	? "   the customers whose name starts with B: " + joinList(columnOf(rows(oConnection,"SELECT Name FROM Customers WHERE Name LIKE ?",["B%"]),1,""))

	# 9. Dates. A DateTime object goes in as a parameter and comes back as a DateTime. Access has date functions: Year, Month, Format.
	? nl + "8. the total of each month (Month function):"
	for aRow in rows(oConnection,"SELECT Month(Ordered) AS M, SUM(Total) FROM Orders GROUP BY Month(Ordered) ORDER BY Month(Ordered)",[])
		? "   month " + aRow[1] + ": " + money(aRow[2])
	next
	? "   orders after 15 February: " + scalar(oConnection,"SELECT COUNT(*) FROM Orders WHERE Ordered > ?",[new DateTime(2024,2,15)])

	# 10. Change and delete rows. The statement answers how many rows it changed.
	? nl + "9. the orders of Ann under 100 are raised by 10%: " + runSql(oConnection,"UPDATE Orders SET Total = Total * 1.1 WHERE CustomerId = ? AND Total < ?",[1,100]) + " rows"
	? "   Dina has no orders and is deleted: " + runSql(oConnection,"DELETE FROM Customers WHERE Id = ?",[4]) + " row"

	# 11. A transaction makes several statements ONE change: all of them happen or none. Here the second statement fails (a table that
	#     does not exist), so the first one is undone.
	oTransaction = oConnection.callMethod("BeginTransaction",[])
	lFailed = False
	try
		runSqlIn(oConnection,oTransaction,"UPDATE Customers SET City = ? WHERE Id = ?",["Luxor",1])
		runSqlIn(oConnection,oTransaction,"UPDATE NoSuchTable SET x = 1",[])
		oTransaction.Commit()
	catch
		lFailed = True
		oTransaction.callMethod("Rollback",[])
	done
	? nl + "10. the second statement failed: " + lFailed + "; the city of Ann is still " + scalar(oConnection,"SELECT City FROM Customers WHERE Id = ?",[1])

	# 12. Close the connection. The pool of ODBC keeps connections for reuse, so it is emptied too. The Access engine keeps the FILE open
	#     until the program ends, so the program does not delete it here.
	oConnection.Close()
	oConnection.Dispose()
	dnStatic("System.Data.Odbc.OdbcConnection","ReleaseObjectPool",[])
	? nl + "11. the connection is closed; the file stays on the disk until the next run of the program deletes it"

# ---------------------------------------------------------------- the database

# is the ODBC driver registered? (the list of ODBC drivers is in the registry)
func driverInstalled cDriver
	try
		oMachine = dnType("Microsoft.Win32.Registry").getProp("LocalMachine")
		oKey = oMachine.OpenSubKey("SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers")
		if oKey.isNull()
			return false
		ok
		xValue = oKey.GetValue(cDriver)          # the text "Installed", or null when the driver is not registered
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
		oType = new Type().GetTypeFromProgID("ADOX.Catalog")
		if oType.isNull()
			return false
		ok
		oCatalog = new Activator().CreateInstance(oType)
		oType.callMethod("InvokeMember",["Create","InvokeMethod",dnNull(),oCatalog,["Provider=Microsoft.ACE.OLEDB.16.0;Data Source=" + cFile]])
		return new File().Exists(cFile)
	catch
		return false
	done

# a command with its parameters (the driver uses them in the order of the ? marks)
func makeCommand oConnection,cSql,aValues
	oCommand = oConnection.CreateCommand()
	oCommand.setProp("CommandText",cSql)
	oParameters = oCommand.Parameters
	nNumber = 0
	for xValue in aValues
		nNumber++
		oParameters.callMethod("AddWithValue",["p" + nNumber,xValue])
	next
	return oCommand

# a statement that changes data: answers the number of rows
func runSql oConnection,cSql,aValues
	return makeCommand(oConnection,cSql,aValues).ExecuteNonQuery()

func runSqlIn oConnection,oTransaction,cSql,aValues
	oCommand = makeCommand(oConnection,cSql,aValues)
	oCommand.setProp("Transaction",oTransaction)
	return oCommand.ExecuteNonQuery()

# one value: the first column of the first row
func scalar oConnection,cSql,aValues
	return makeCommand(oConnection,cSql,aValues).ExecuteScalar()

# all the rows as a list of lists. A date comes back as a text "yyyy-MM-dd", the other values as Ring numbers and texts.
func rows oConnection,cSql,aValues
	aRows = []
	oReader = makeCommand(oConnection,cSql,aValues).callMethod("ExecuteReader",[])
	nColumns = oReader.FieldCount
	while oReader.Read()
		aRow = []
		for nColumn = 0 to nColumns - 1
			xValue = oReader.GetValue(nColumn)
			if isObject(xValue)
				if xValue.typeName() = "System.DateTime"
					xValue = xValue.Format("yyyy-MM-dd")
				else
					xValue = xValue.toString()
				ok
			ok
			aRow + xValue
		next
		aRows + aRow
	end
	oReader.Dispose()
	return aRows

# the user tables (the schema also lists the system tables of Access)
func tableNames oConnection
	aNames = []
	for oRow in oConnection.GetSchema("Tables").Rows.toList()
		if oRow.callMethod("get_Item",["TABLE_TYPE"]) = "TABLE"
			aNames + oRow.callMethod("get_Item",["TABLE_NAME"])
		ok
	next
	return sort(aNames)

# the column names and types of a table: an empty query (WHERE 1 = 0) describes the columns without reading rows
func columnNames oConnection,cTable
	aNames = []
	oReader = makeCommand(oConnection,"SELECT * FROM " + cTable + " WHERE 1 = 0",[]).callMethod("ExecuteReader",[])
	for nColumn = 0 to oReader.FieldCount - 1
		aNames + (oReader.GetName(nColumn) + " (" + lower(oReader.GetDataTypeName(nColumn)) + ")")
	next
	oReader.Dispose()
	return aNames

# ---------------------------------------------------------------- small helpers

# an Arabic name as UTF-8 bytes (a Ring text is a text of bytes)
func arabicName
	return char(216) + char(163) + char(216) + char(173) + char(217) + char(133) + char(216) + char(175)

# the first word, so that the Arabic name does not disturb the columns
func shortName cName
	cShort = cName
	if cName = arabicName()
		cShort = "(Arabic)"
	ok
	return cShort

func money nValue
	nRounded = floor(nValue * 100 + 0.5)
	nUnits = floor(nRounded / 100)
	nCents = nRounded - nUnits * 100
	cCents = "" + nCents
	if nCents < 10
		cCents = "0" + cCents
	ok
	return "" + nUnits + "." + cCents

func columnOf aRows,nColumn,cFormat
	aValues = []
	for aRow in aRows
		if cFormat = "money"
			aValues + money(aRow[nColumn])
		else
			aValues + shortName(aRow[nColumn])
		ok
	next
	return aValues

func joinList aList
	cText = ""
	for item in aList
		if cText != ""
			cText += ", "
		ok
		cText += "" + item
	next
	return cText

func padRight cText,nWidth
	return cText + copy(" ",nWidth - len(cText))

func padLeft cText,nWidth
	return copy(" ",nWidth - len(cText)) + cText
