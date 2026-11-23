# a project with three packages - CsvHelper reads a CSV text, LiteDB stores the rows and finds some of them, ClosedXML writes an Excel report
#   (the project is in the folder Report: Report.csproj names the three packages, and Empty.cs is the one source file a project needs)
load "dotnet.ring"

using { "System.IO" "System.Globalization" }

cHere = currentdir()
cLibs = cHere + "/Report/libs/"
cClasses = cHere + "/Report/classes/"

# STEP 1. Get the packages (nuget.org the first time) with dotnet publish: one folder with the three DLLs and the DLLs they need
if not fexists(cLibs + "CsvHelper.dll")
	? "getting the packages..."
	system("dotnet publish Report -c Release -o Report/libs -nologo -v q > nul")
ok
if not fexists(cLibs + "CsvHelper.dll")
	? "The packages could not be restored. They are downloaded from nuget.org the first time, so the computer needs the internet once."
	bye
ok

# STEP 2. Make Ring classes: one folder for each DLL (the namespaces that the program uses)
chdir("../../../tools/dotnettools")
system(exefilename() + " wrapassembly.ring " + cLibs + "CsvHelper.dll " + cClasses + "CsvHelper CsvHelper > nul")
system(exefilename() + " wrapassembly.ring " + cLibs + "LiteDB.dll " + cClasses + "LiteDB LiteDB > nul")
system(exefilename() + " wrapassembly.ring " + cLibs + "ClosedXML.dll " + cClasses + "ClosedXML ClosedXML.Excel > nul")
chdir(cHere)

# STEP 3. Load the three assemblies and their classes
dnLoad(cLibs + "CsvHelper.dll")
dnImportFrom(cClasses + "CsvHelper/","CsvHelper")
dnLoad(cLibs + "LiteDB.dll")
dnImportFrom(cClasses + "LiteDB/","LiteDB")
dnLoad(cLibs + "ClosedXML.dll")
dnImportFrom(cClasses + "ClosedXML/","ClosedXML.Excel")

func main

	cTemp = new Path().GetTempPath()
	cDbFile = new Path().Combine([cTemp,"ringdotnet-sales.db"])
	cXlsx = new Path().Combine([cTemp,"ringdotnet-sales-report.xlsx"])
	if new File().Exists(cDbFile) new File().Delete(cDbFile) ok

	# 1. The data: a CSV text (a program would read a file: new StreamReader for a path)
	cCsv  = "date,region,product,units,price" + nl
	cCsv += "2024-03-01,North,Tea,10,2.5" + nl
	cCsv += "2024-03-01,North,Cake,4,8" + nl
	cCsv += "2024-03-02,South,Tea,7,2.5" + nl
	cCsv += "2024-03-02,South,Coffee,12,3" + nl
	cCsv += "2024-03-03,East,Cake,6,8" + nl
	cCsv += "2024-03-03,East,Tea,3,2.5" + nl
	cCsv += "2024-03-04,North,Coffee,9,3" + nl
	cCsv += "2024-03-04,South,Cake,2,8" + nl

	# 2. CsvHelper reads it: ReadHeader takes the first line, and Read goes to the next row. A field is read by the name of its column.
	oText = dnNew("System.IO.StringReader",[ :s = cCsv ])
	oCulture = dnNew("System.Globalization.CultureInfo",[ :name = "en-US" ])
	oCsv = dnNew("CsvHelper.CsvReader",[ :reader = oText, :culture = oCulture ])
	oCsv.Read()
	oCsv.ReadHeader()

	# 3. LiteDB keeps each row as a document. The database is a file, the collection is like a table.
	oDb = dnNew("LiteDB.LiteDatabase",[ :connectionString = cDbFile ])
	oSales = oDb.GetCollection([ :name = "sales" ])
	nRows = 0
	while oCsv.Read()
		oDoc = new BsonDocument()
		oDoc.Add([ :key = "date", :value = oCsv.GetField("date") ])
		oDoc.Add([ :key = "region", :value = oCsv.GetField("region") ])
		oDoc.Add([ :key = "product", :value = oCsv.GetField("product") ])
		oDoc.Add([ :key = "units", :value = number(oCsv.GetField("units")) ])
		oDoc.Add([ :key = "price", :value = number(oCsv.GetField("price")) ])
		oSales.callMethod("Insert",[ oDoc ])
		nRows++
	end
	oText.Dispose()
	? "1. rows read from the CSV and stored: " + nRows + ", in the database: " + oSales.callMethod("Count",[])

	# 4. A query: the rows with 9 units or more. The condition is a text in the query language of LiteDB.
	oBig = oSales.callMethod("Find",[ new BsonExpression().Create("$.units >= 9") ])
	aBig = []
	for oRow in oBig.toList()
		aBig + [oRow.Item("region").AsString,oRow.Item("product").AsString,oRow.Item("units").AsInt32]
	next
	aBig = sort(aBig,1)
	? "2. rows with 9 units or more:"
	for aRow in aBig
		? "   " + aRow[1] + " " + aRow[2] + " " + aRow[3]
	next

	# 5. Totals by region: the rows come out of the database as documents and Ring adds them up
	aTotals = []          # [region, amount]
	aAll = []
	for oRow in oSales.callMethod("FindAll",[]).toList()
		cRegion = oRow.Item("region").AsString
		nAmount = oRow.Item("units").AsInt32 * oRow.Item("price").AsDouble
		nPos = find(aTotals,cRegion,1)
		if nPos = 0
			aTotals + [cRegion,0]
			nPos = len(aTotals)
		ok
		aTotals[nPos][2] += nAmount
		aAll + [oRow.Item("date").AsString,cRegion,oRow.Item("product").AsString,oRow.Item("units").AsInt32,oRow.Item("price").AsDouble]
	next
	aTotals = sort(aTotals,1)
	aAll = sort(aAll,1)
	? "3. total by region:"
	for aTotal in aTotals
		? "   " + aTotal[1] + " " + aTotal[2]
	next
	oDb.Dispose()

	# 6. ClosedXML writes the report: a sheet with all the rows (the amount is a formula) and a sheet with the totals
	oBook = new XLWorkbook()
	oSheet = oBook.AddWorksheet("Sales")
	aHeader = ["Date","Region","Product","Units","Price","Amount"]
	for nColumn = 1 to len(aHeader)
		oSheet.Cell(char(64 + nColumn) + "1").Value = aHeader[nColumn]
	next
	oSheet.Range("A1:F1").Style.Font.Bold = true
	for nLine = 1 to len(aAll)
		nRow = nLine + 1
		for nColumn = 1 to 5
			oSheet.Cell(char(64 + nColumn) + nRow).Value = aAll[nLine][nColumn]
		next
		oSheet.Cell("F" + nRow).FormulaA1 = "=D" + nRow + "*E" + nRow
	next
	nLast = len(aAll) + 1
	oSheet.Cell("E" + (nLast + 1)).Value = "Total"
	oSheet.Cell("F" + (nLast + 1)).FormulaA1 = "=SUM(F2:F" + nLast + ")"
	oBy = oBook.AddWorksheet("By region")
	oBy.Cell("A1").Value = "Region"
	oBy.Cell("B1").Value = "Amount"
	oBy.Range("A1:B1").Style.Font.Bold = true
	for nLine = 1 to len(aTotals)
		oBy.Cell("A" + (nLine + 1)).Value = aTotals[nLine][1]
		oBy.Cell("B" + (nLine + 1)).Value = aTotals[nLine][2]
	next
	oBook.SaveAs(cXlsx)
	oBook.Dispose()

	# 7. Read the report back: the formulas are worked out when the cells are read
	oRead = new XLWorkbook().@New([ :file = cXlsx ])
	oBack = oRead.Worksheet("Sales")
	? nl + "4. the report has the sheets Sales and By region, and " + (oBack.LastRowUsed(NULL).RowNumber() - 2) + " rows of sales and a total row"
	? "   the total of the sheet Sales (a formula): " + oBack.Cell("F" + (nLast + 1)).Value.GetNumber()
	oRead.Dispose()
	new File().Delete(cXlsx)
	if new File().Exists(cDbFile) new File().Delete(cDbFile) ok
