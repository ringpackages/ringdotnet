# ClosedXML: an Excel workbook in memory; cell values, a formula, a saved file that is read again
load "pkg.ring"
pkgUse("closedxml",[["ClosedXML","0.104.2"]],[["ClosedXML.dll",["ClosedXML.Excel"]]])
pkgImport("closedxml","ClosedXML.dll","ClosedXML.Excel")
dnImport("System.IO")

cFile = cPkgCache + "closedxml/test.xlsx"
oBook = new XLWorkbook()
oSheet = oBook.Worksheets.Add("Data")
oSheet.Cell("A1").Value = 10
oSheet.Cell("A2").Value = 20
oSheet.Cell("A3").Value = 12.5
oSheet.Cell("B1").Value = "ring"
oSheet.Cell("C1").FormulaA1 = "SUM(A1:A3)"
dnAssert("a sheet name",oSheet.Name,"Data")
dnAssert("a formula is calculated",oSheet.Cell("C1").Value.GetNumber(),42.5)
dnAssert("a text cell",oSheet.Cell("B1").Value.GetText(),"ring")
dnAssert("the last used row",oSheet.LastRowUsed(NULL).RowNumber(),3)
oBook.SaveAs(cFile)
oBook.Dispose()

oRead = new XLWorkbook().@New(cFile)
dnAssert("the file is read again",oRead.Worksheet("Data").Cell("A2").Value.GetNumber(),20)
dnAssert("the text is kept",oRead.Worksheet("Data").Cell("B1").Value.GetText(),"ring")
oRead.Dispose()

dnTestSummary()
