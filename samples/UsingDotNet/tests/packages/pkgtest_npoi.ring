# NPOI: Excel workbooks (.xlsx) made and read in memory: sheets, rows, cells of texts, numbers and yes/nos, a formula that is calculated, and the file read back
load "pkg.ring"
pkgUse("npoi",[["NPOI","2.7.6"]],[["NPOI.Core.dll",["NPOI.SS.UserModel"]],["NPOI.OOXML.dll",["NPOI.XSSF.UserModel"]],["NPOI.OpenXml4Net.dll",[]],["NPOI.OpenXmlFormats.dll",[]]])
pkgImport("npoi","NPOI.Core.dll","NPOI.SS.UserModel")
pkgImport("npoi","NPOI.OOXML.dll","NPOI.XSSF.UserModel")
using { "System.IO" }

oBook = new XSSFWorkbook()
oSheet = oBook.CreateSheet("People")
dnAssert("the name of the sheet",oSheet.SheetName,"People")
oHeader = oSheet.CreateRow(0)
oHeader.CreateCell(0).SetCellValue("Name")
oHeader.CreateCell(1).SetCellValue("Age")
oHeader.CreateCell(2).SetCellValue("Member")
aPeople = [ ["Ann",31,1], ["Bob",25,0], ["Cy",40.5,1] ]
nRow = 1
for aPerson in aPeople
	oRow = oSheet.CreateRow(nRow)
	oRow.CreateCell(0).SetCellValue(aPerson[1])
	oRow.CreateCell(1).SetCellValue(aPerson[2])
	oRow.CreateCell(2).SetCellValue(dnBox("System.Boolean",aPerson[3]))          # a Ring number is a Double: a yes/no cell needs a Boolean object
	nRow++
next
# a formula, calculated by the evaluator
oSum = oSheet.CreateRow(4)
oSum.CreateCell(1).SetCellFormula("SUM(B2:B4)")
oEvaluator = oBook.GetCreationHelper().CreateFormulaEvaluator()
oEvaluator.EvaluateAll()
dnAssert("the formula is calculated",oSheet.GetRow(4).GetCell(1).NumericCellValue,96.5)
dnAssert("the last row",oSheet.LastRowNum,4)
dnAssert("the number of sheets",oBook.NumberOfSheets,1)

# written to memory and read back
oStream = new MemoryStream()
oBook.callMethod("Write",[oStream,1])
dnAssert("the file has bytes",oStream.Length > 1000,1)
oStream.Position = 0
oRead = dnNew("NPOI.XSSF.UserModel.XSSFWorkbook",[oStream])
oReadSheet = oRead.GetSheet("People")
dnAssert("the sheet is found by its name",oReadSheet.SheetName,"People")
dnAssert("a text cell",oReadSheet.GetRow(1).GetCell(0).StringCellValue,"Ann")
dnAssert("a number cell",oReadSheet.GetRow(3).GetCell(1).NumericCellValue,40.5)
dnAssert("a yes/no cell",oReadSheet.GetRow(2).GetCell(2).BooleanCellValue,0)
dnAssert("a formula cell keeps its text",oReadSheet.GetRow(4).GetCell(1).CellFormula,"SUM(B2:B4)")
dnAssert("the type of a cell",oReadSheet.GetRow(1).GetCell(1).CellType,"Numeric")
dnAssert("a cell that was never made is null",dnIsNull(oReadSheet.GetRow(1).GetCell(5)),1)
dnAssert("a row that was never made is null",dnIsNull(oReadSheet.GetRow(9)),1)

# a second sheet, found by its index and by its name
oBook.CreateSheet("Other")
dnAssert("the second sheet by its index",oBook.GetSheetAt(1).SheetName,"Other")
dnAssert("the index of a sheet by its name",oBook.GetSheetIndex("Other"),1)
cError = ""
try
	oBook.CreateSheet("People")
catch
	cError = cCatchError
done
dnAssert("a second sheet with the same name is an error",substr(cError,"ArgumentException") > 0,1)

dnTestSummary()
