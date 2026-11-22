# Spectre.Console: widgets (markup, tables, a panel, a rule) drawn on a test console that keeps the text instead of printing it
load "pkg.ring"
pkgUse("spectre",[["Spectre.Console","0.57.2"],["Spectre.Console.Testing","0.57.2"]],[["Spectre.Console.dll",["Spectre.Console","Spectre.Console.Rendering"]],["Spectre.Console.Testing.dll",["Spectre.Console.Testing"]]])
pkgImport("spectre","Spectre.Console.dll","Spectre.Console")
pkgImport("spectre","Spectre.Console.dll","Spectre.Console.Rendering")
pkgImport("spectre","Spectre.Console.Testing.dll","Spectre.Console.Testing")

oConsole = new TestConsole()
oConsole.Write(new Markup("[bold]Hello[/] [red]Ring[/]" + nl))
cText = oConsole.Output
dnAssert("markup is drawn without the tags",substr(cText,"Hello Ring") > 0 and substr(cText,"[bold]") = 0,1)

# a table: columns and rows (the columns and rows are added by extension methods)
oTable = new Table()
oTable.AddColumn("Name")
oTable.AddColumn("Age")
oTable.AddRow(["Ann","31"])
oTable.AddRow(["Bo","25"])
dnAssert("the table has two columns",oTable.Columns.Count,2)
dnAssert("the table has two rows",oTable.Rows.Count,2)
oConsole2 = new TestConsole()
oConsole2.Write(oTable)
cTable = oConsole2.Output
dnAssert("the header is drawn",substr(cTable,"Name") > 0 and substr(cTable,"Age") > 0,1)
dnAssert("the rows are drawn",substr(cTable,"Ann") > 0 and substr(cTable,"Bo") > 0,1)
dnAssert("the table has a border",substr(cTable,"─") > 0 or substr(cTable,"-") > 0 or substr(cTable,"│") > 0,1)

# a panel and a rule
oConsole3 = new TestConsole()
oConsole3.Write(new Panel(new Markup("inside")))
dnAssert("a panel draws its content",substr(oConsole3.Output,"inside") > 0,1)
oConsole4 = new TestConsole()
oConsole4.Write(new Rule().@New("Section"))
dnAssert("a rule draws its title",substr(oConsole4.Output,"Section") > 0,1)

# the markup text of a value is escaped
dnAssert("a text is escaped for markup",dnStatic("Spectre.Console.Markup","Escape",["[not a tag]"]),"[[not a tag]]")
dnAssert("the width of the test console",oConsole.Profile.Width,80)

dnTestSummary()
