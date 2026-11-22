# CsvHelper (the classic API of version 33): read a CSV text row by row, with a header, typed fields (a generic method), and write one back
load "pkg.ring"
pkgUse("csvhelper",[["CsvHelper","33.0.1"]],[["CsvHelper.dll",["CsvHelper"]]])
pkgImport("csvhelper","CsvHelper.dll","CsvHelper")
dnImport("System.IO")
dnImport("System.Globalization")

cCsv = "name,age,city" + nl + "Ann,31,Cairo" + nl + "Bo,25,Giza" + nl + '"Cy, Jr",40,"Port Said"' + nl
oCulture = dnType("System.Globalization.CultureInfo").getProp("InvariantCulture")
oReader = dnNew("System.IO.StringReader",[cCsv])
oCsv = dnNew("CsvHelper.CsvReader",[oReader,oCulture])
dnAssert("the first row is read",oCsv.Read(),1)
dnAssert("the header is read",oCsv.ReadHeader(),1)
dnAssert("the header has three columns",len(oCsv.HeaderRecord.toList()),3)
aNames = []
aAges = []
while oCsv.Read()
	add(aNames,oCsv.GetField("name"))
	add(aAges,oCsv.callGeneric("GetField",["System.Int32"],["age"]))
end
dnAssert("three rows",len(aNames),3)
dnAssert("a text field",aNames[1],"Ann")
dnAssert("a quoted field with a comma",aNames[3],"Cy, Jr")
dnAssert("typed fields (GetField<int>)",aAges[1] + aAges[2] + aAges[3],96)
dnAssert("the row index",oCsv.Parser.Row,5)
oCsv.Dispose()

# a second pass: the records as dynamic objects, read as dictionaries
oReader2 = dnNew("System.IO.StringReader",[cCsv])
oCsv2 = dnNew("CsvHelper.CsvReader",[oReader2,oCulture])
aRecords = oCsv2.callGeneric("GetRecords",["System.Object"],[]).toList()
dnAssert("GetRecords<object> gives a record per row",len(aRecords),3)
oCsv2.Dispose()

# writing: fields, a new record, the text
oWriterText = new StringWriter()
oWriter = dnNew("CsvHelper.CsvWriter",[oWriterText,oCulture])
oWriter.WriteField("id")
oWriter.WriteField("note")
oWriter.NextRecord()
oWriter.WriteField(1)
oWriter.WriteField("has, a comma")
oWriter.NextRecord()
oWriter.Flush()
cWritten = oWriterText.ToString()
dnAssert("the header is written",substr(cWritten,"id,note") > 0,1)
dnAssert("a field with a comma is quoted",substr(cWritten,'"has, a comma"') > 0,1)
oWriter.Dispose()

dnTestSummary()
