# ConsoleTables: a text table from column names and rows (params object[] of texts and numbers), in several formats
load "pkg.ring"
pkgUse("consoletables",[["ConsoleTables","2.7.0"]],[["ConsoleTables.dll",["ConsoleTables"]]])
pkgImport("consoletables","ConsoleTables.dll","ConsoleTables")

oTable = new ConsoleTable(["Name","Age"])
oTable.AddRow(["Ann",30])
oTable.AddRow(["Bob",25])
cText = oTable.ToString()
dnAssert("the names of the columns",substr(cText,"Name") > 0,1)
dnAssert("a row",substr(cText,"Ann") > 0,1)
dnAssert("a number in a row",substr(cText,"25") > 0,1)

cMarkdown = oTable.ToMarkDownString()
dnAssert("a Markdown table",substr(cMarkdown,"| Name") > 0,1)
dnAssert("with a separator row",substr(cMarkdown,"--") > 0,1)

dnAssert("the number of rows",oTable.Rows.Count,2)

oArabic = new ConsoleTable(["اسم"])
oArabic.AddRow(["مرحبا"])
dnAssert("Arabic text in a table",substr(oArabic.ToString(),"مرحبا") > 0,1)

dnTestSummary()
