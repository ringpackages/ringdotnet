# an Excel file with a NuGet package - ClosedXML writes and reads .xlsx files without Excel on the computer
#   (the project is in the folder Excel: Excel.csproj names ClosedXML, and Empty.cs is the one source file a project needs)
load "dotnet.ring"
using { "System.IO" }

cHere = currentdir()
cDll = cHere + "/Excel/libs/ClosedXML.dll"
cClasses = cHere + "/Excel/classes"

# STEP 1. Get the package and the packages it needs (nuget.org the first time) with dotnet publish
if not fexists(cDll)
	? "getting the package..."
	system("dotnet publish Excel -c Release -o Excel/libs -nologo -v q > nul")
ok
if not fexists(cDll)
	? "The package could not be restored. It is downloaded from nuget.org the first time, so the computer needs the internet once."
	bye
ok

# STEP 2. Make Ring classes for the namespace ClosedXML.Excel of the DLL (the other DLLs in the folder are used by ClosedXML itself)
chdir("../../../tools/dotnettools")
system(exefilename() + " wrapassembly.ring " + cDll + " " + cClasses + " ClosedXML.Excel > nul")
chdir(cHere)

# STEP 3. Load the assembly and the classes
dnLoad(cDll)
dnImportFrom(cClasses + "/","ClosedXML.Excel")

func main
	cFile = new Path().Combine([new Path().GetTempPath(),"tutorial-sales.xlsx"])

	# 1. A workbook is the file; a worksheet is one of its sheets; a cell is found by its address ("B2") like in Excel
	oBook = new XLWorkbook()
	oSheet = oBook.AddWorksheet("Sales")
	aHeader = ["Product","Price","Quantity","Total"]
	for nColumn = 1 to len(aHeader)
		oSheet.Cell(char(64 + nColumn) + "1").Value = aHeader[nColumn]
	next
	oSheet.Range("A1:D1").Style.Font.Bold = true

	# 2. The rows come from a Ring list. A text is a text cell, a number is a number cell, and a formula starts with =
	aProducts = [ ["Tea",12.5,4], ["Coffee",20,3], ["Cake",8.25,2] ]
	for nRow = 1 to len(aProducts)
		nLine = nRow + 1
		oSheet.Cell("A" + nLine).Value = aProducts[nRow][1]
		oSheet.Cell("B" + nLine).Value = aProducts[nRow][2]
		oSheet.Cell("C" + nLine).Value = aProducts[nRow][3]
		oSheet.Cell("D" + nLine).FormulaA1 = "=B" + nLine + "*C" + nLine
	next
	oSheet.Cell("A5").Value = "All"
	oSheet.Cell("D5").FormulaA1 = "=SUM(D2:D4)"
	oBook.SaveAs(cFile)
	oBook.Dispose()
	? "1. written: " + new File().Exists(cFile)

	# 3. Read it back. The formulas were worked out when the cells were read.
	oRead = new XLWorkbook().New_([ :file = cFile ])
	oSales = oRead.Worksheet("Sales")
	nLast = oSales.LastRowUsed(NULL).RowNumber()
	? "2. the sheet has " + nLast + " rows:"
	for nLine = 1 to nLast
		cText = oSales.Cell("A" + nLine).Value.ToString()
		if nLine = 1
			? "   " + cText + " | Price | Quantity | Total"
		else
			? "   " + cText + " | " + oSales.Cell("B" + nLine).Value.ToString() + " | " + oSales.Cell("C" + nLine).Value.ToString() + " | " + oSales.Cell("D" + nLine).Value.ToString()
		ok
	next
	? "3. the total is " + oSales.Cell("D5").Value.GetNumber()
	? "   the header is bold: " + oSales.Cell("A1").Style.Font.Bold
	oRead.Dispose()
	new File().Delete(cFile)
