# ExcelDataReader: reads an xlsx file row by row through a data reader (Read, GetValue); the file is written by ClosedXML in the same test
load "pkg.ring"
pkgUse("exceldatareader",[["ExcelDataReader","3.9.0"],["ClosedXML","0.104.2"]],[["ExcelDataReader.dll",["ExcelDataReader"]],["ClosedXML.dll",["ClosedXML.Excel"]]])
pkgImport("exceldatareader","ExcelDataReader.dll","ExcelDataReader")
pkgImport("exceldatareader","ClosedXML.dll","ClosedXML.Excel")

cFile = cPkgCache + "exceldatareader/data.xlsx"
oBook = new XLWorkbook()
oSheet = oBook.Worksheets.Add("People")
oSheet.Cell("A1").Value = "Name"
oSheet.Cell("B1").Value = "Age"
oSheet.Cell("A2").Value = "Ann"
oSheet.Cell("B2").Value = 30
oSheet.Cell("A3").Value = "مرحبا"
oSheet.Cell("B3").Value = 25.5
oBook.SaveAs(cFile)
oBook.Dispose()

# ExcelDataReader reads legacy encodings: the code pages provider is registered first
dnType("System.Text.Encoding").callMethod("RegisterProvider",[dnStatic("System.Text.CodePagesEncodingProvider, System.Text.Encoding.CodePages","Instance",[])])

oStream = dnNew("System.IO.FileStream",[cFile,dnStatic("System.IO.FileMode","Open",[])])
oReader = dnStatic("ExcelDataReader.ExcelReaderFactory","CreateReader",[oStream])
dnAssert("the sheet name",oReader.Name,"People")
dnAssert("three rows",oReader.RowCount,3)
dnAssert("two fields",oReader.FieldCount,2)

aRows = []
while oReader.Read()
	aRows + [ oReader.GetValue(0), oReader.GetValue(1) ]
end
dnAssert("the rows read",len(aRows),3)
dnAssert("the header",aRows[1][1],"Name")
dnAssert("a text cell",aRows[2][1],"Ann")
dnAssert("a whole number cell",aRows[2][2],30)
dnAssert("an Arabic cell",aRows[3][1],"مرحبا")
dnAssert("a fraction cell",aRows[3][2],25.5)
oReader.Close()
oStream.Dispose()

dnTestSummary()
