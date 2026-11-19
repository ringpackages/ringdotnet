# reports with SQL - JOIN, GROUP BY, HAVING, LEFT JOIN, sub-queries and parameters
load "dotnet.ring"
using { "RingDotNet.Data" }

func main
	aSchema = [
		["Customers",[["Id","int",1],["Name","string",0],["City","string",0]]],
		["Orders",[["Id","int",1],["CustomerId","int",0,[["references","Customers"]]],["Product","string",0],["Amount","int",0],["Month","string",0]]]
	]
	oDb = new RingDatabase("Data Source=:memory:",aSchema)
	nAnn = oDb.insert("Customers",[["Name","Ann"],["City","Cairo"]])
	nBob = oDb.insert("Customers",[["Name","Bob"],["City","Oslo"]])
	nCy = oDb.insert("Customers",[["Name","Cy"],["City","Cairo"]])
	nDee = oDb.insert("Customers",[["Name","Dee"],["City","Tokyo"]])
	for aOrder in [[nAnn,"Laptop",900,"Jan"],[nAnn,"Mouse",20,"Jan"],[nAnn,"Monitor",250,"Feb"],[nBob,"Laptop",950,"Jan"],[nBob,"Keyboard",60,"Mar"],[nCy,"Mouse",25,"Feb"],[nCy,"Mouse",25,"Mar"]]
		oDb.insert("Orders",[["CustomerId",aOrder[1]],["Product",aOrder[2]],["Amount",aOrder[3]],["Month",aOrder[4]]])
	next
	? "4 customers and " + oDb.count("Orders") + " orders are in the database (Dee has no orders)"

	# 1. JOIN: put the rows of two tables together where the keys are equal. Each order shows the name of its customer.
	? nl + "1. who bought what:"
	show(oDb.sqlRows("SELECT c.Name, o.Product, o.Amount FROM Orders o JOIN Customers c ON c.Id = o.CustomerId ORDER BY o.Id",[]),["Name","Product","Amount"])

	# 2. GROUP BY: one row per group, with an aggregate (SUM, COUNT, AVG, MIN, MAX) over each group
	? nl + "2. the total of each customer, the biggest first:"
	show(oDb.sqlRows("SELECT c.Name, COUNT(o.Id) AS Orders, SUM(o.Amount) AS Total FROM Customers c JOIN Orders o ON o.CustomerId = c.Id GROUP BY c.Name ORDER BY Total DESC",[]),["Name","Orders","Total"])

	# 3. WHERE filters the rows before they are grouped; HAVING filters the groups after
	? nl + "3. customers who spent more than 300 (HAVING):"
	show(oDb.sqlRows("SELECT c.Name, SUM(o.Amount) AS Total FROM Customers c JOIN Orders o ON o.CustomerId = c.Id GROUP BY c.Name HAVING SUM(o.Amount) > {0}",[300]),["Name","Total"])
	? "   the same for January only (WHERE first):"
	show(oDb.sqlRows("SELECT c.Name, SUM(o.Amount) AS Total FROM Customers c JOIN Orders o ON o.CustomerId = c.Id WHERE o.Month = {0} GROUP BY c.Name",["Jan"]),["Name","Total"])

	# 4. An inner JOIN drops customers without orders. LEFT JOIN keeps every row of the left table (the missing values are empty).
	? nl + "4. every customer with the number of orders (LEFT JOIN keeps Dee):"
	show(oDb.sqlRows("SELECT c.Name, COUNT(o.Id) AS Orders FROM Customers c LEFT JOIN Orders o ON o.CustomerId = c.Id GROUP BY c.Name ORDER BY c.Name",[]),["Name","Orders"])

	# 5. Group by a column of the other table: the total per city
	? nl + "5. the total per city:"
	show(oDb.sqlRows("SELECT c.City, SUM(o.Amount) AS Total FROM Customers c JOIN Orders o ON o.CustomerId = c.Id GROUP BY c.City ORDER BY Total DESC",[]),["City","Total"])

	# 6. A sub-query: the orders that are bigger than the average order
	? nl + "6. orders above the average (a sub-query calculates the average):"
	show(oDb.sqlRows("SELECT Product, Amount FROM Orders WHERE Amount > (SELECT AVG(Amount) FROM Orders) ORDER BY Amount DESC",[]),["Product","Amount"])

	# 7. A single value: scalar() returns the first column of the first row
	? nl + "7. the number of different products: " + oDb.scalar("SELECT COUNT(DISTINCT Product) FROM Orders")
	oDb.close()

# print rows as a small table: cColumns are the names of the columns to show
func show aRows, aColumns
	for aRow in aRows
		cLine = "   "
		for cColumn in aColumns
			cLine += padRight("" + dbValue(aRow,cColumn),10)
		next
		? cLine
	next
	if len(aRows) = 0
		? "   (no rows)"
	ok

func padRight cText, nWidth
	while len(cText) < nWidth
		cText += " "
	end
	return cText
