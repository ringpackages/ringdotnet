# Sylvan.Data.Csv: a CSV text as an ADO.NET data reader (Read, GetString, GetInt32, field names), quoted fields and Arabic text
load "pkg.ring"
pkgUse("sylvancsv",[["Sylvan.Data.Csv","1.4.1"]],[["Sylvan.Data.Csv.dll",["Sylvan.Data.Csv"]]])
pkgImport("sylvancsv","Sylvan.Data.Csv.dll","Sylvan.Data.Csv")

cCsv = "name,age,city" + nl + "Ann,30,Cairo" + nl + '"Smith, Jo",41,"New York"' + nl + "مرحبا,25,القاهرة" + nl
oReader = dnStatic("Sylvan.Data.Csv.CsvDataReader","Create",[dnNew("System.IO.StringReader",[cCsv])])
dnAssert("three fields",oReader.FieldCount,3)
dnAssert("the name of a field",oReader.GetName(1),"age")

aRows = []
while oReader.Read()
	aRows + [ oReader.GetString(0), oReader.GetInt32(1), oReader.GetString(2) ]
end
dnAssert("three rows",len(aRows),3)
dnAssert("a text",aRows[1][1],"Ann")
dnAssert("a number",aRows[1][2],30)
dnAssert("a quoted field keeps its comma",aRows[2][1],"Smith, Jo")
dnAssert("a quoted field with a space",aRows[2][3],"New York")
dnAssert("Arabic text",aRows[3][1],"مرحبا")
dnAssert("Arabic text in another field",aRows[3][3],"القاهرة")
oReader.Dispose()

dnTestSummary()
