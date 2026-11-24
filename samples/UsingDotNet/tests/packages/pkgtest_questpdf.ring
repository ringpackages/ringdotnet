# QuestPDF: a PDF made from a description in code (a document, pages, text, columns, rows and a table); the pieces are Ring functions that .NET
# calls while the document is made, and PdfPig reads the file back to check what is in it.
# QuestPDF needs a license choice before it makes a document: the Community license is set below, as the owner of this package decided (the terms are in
# the QuestPDF repository: https://github.com/QuestPDF/QuestPDF).
load "pkg.ring"
pkgUse("questpdf",[["QuestPDF","2026.9.2"],["PdfPig","0.1.9"]],[["QuestPDF.dll",["QuestPDF.Fluent","QuestPDF.Infrastructure","QuestPDF.Helpers","QuestPDF"]],["UglyToad.PdfPig.dll",["UglyToad.PdfPig","UglyToad.PdfPig.Content"]],["UglyToad.PdfPig.Core.dll",[]],["UglyToad.PdfPig.Fonts.dll",[]],["UglyToad.PdfPig.Tokenization.dll",[]],["UglyToad.PdfPig.Tokens.dll",[]]])
pkgImport("questpdf","QuestPDF.dll","QuestPDF.Fluent")
pkgImport("questpdf","QuestPDF.dll","QuestPDF.Infrastructure")
pkgImport("questpdf","QuestPDF.dll","QuestPDF.Helpers")
pkgImport("questpdf","QuestPDF.dll","QuestPDF")
pkgImport("questpdf","UglyToad.PdfPig.dll","UglyToad.PdfPig")
pkgImport("questpdf","UglyToad.PdfPig.dll","UglyToad.PdfPig.Content")

dnType("QuestPDF.Settings").setProp("License","Community")

nLines = 60          # the lines of the long document: enough for two pages
cFile = cPkgCache + "questpdf/hello.pdf"

# a one page document
oDocument = dnStatic("QuestPDF.Fluent.Document","Create",[dnCallback("qpBuildHello")])
oDocument.GeneratePdf(cFile)
dnAssert("the file was made",fexists(cFile),1)
dnAssert("it is a PDF",left(read(cFile),5),"%PDF-")
oPdf = dnStatic("UglyToad.PdfPig.PdfDocument","Open",[cFile])
dnAssert("one page",oPdf.NumberOfPages,1)
oPage = oPdf.GetPage(1)
cText = oPage.Text
dnAssert("the title is in the page",substr(cText,"Hello from Ring") > 0,1)
dnAssert("the text of the footer",substr(cText,"Page 1") > 0,1)
oPdf.Dispose()

# a document in memory (the bytes of the file are a Ring text)
cBytes = oDocument.GeneratePdf(NULL)
dnAssert("the bytes of a PDF",left(cBytes,5),"%PDF-")

# a longer one: columns, a row and a table, over two pages
cLong = cPkgCache + "questpdf/long.pdf"
dnStatic("QuestPDF.Fluent.Document","Create",[dnCallback("qpBuildLong")]).GeneratePdf(cLong)
oPdf = dnStatic("UglyToad.PdfPig.PdfDocument","Open",[cLong])
dnAssert("two pages",oPdf.NumberOfPages,2)
oPage = oPdf.GetPage(1)
cFirst = oPage.Text
oPage = oPdf.GetPage(2)
cSecond = oPage.Text
dnAssert("the first line is on the first page",substr(cFirst,"Line 1") > 0,1)
dnAssert("the last line is on the second page",substr(cSecond,"Line " + nLines) > 0,1)
dnAssert("the numbers of the pages",substr(cSecond,"Page 2 of 2") > 0,1)
dnAssert("a cell of the table",substr(cFirst,"Ring") > 0,1)
dnAssert("the left and the right of the row",substr(cFirst,"left") > 0 and substr(cFirst,"right") > 0,1)
oPdf.Dispose()

dnTestSummary()

func qpBuildHello aArgs

	aArgs[1].Page(dnCallback("qpHelloPage"))

func qpHelloPage aArgs

	oPage = aArgs[1]
	oPage.Size(dnType("QuestPDF.Helpers.PageSizes").getProp("A4"))
	oPage.Margin(2)
	oPage.Content().Text("Hello from Ring")
	oPage.Footer().AlignCenter().Text(dnCallback("qpFooter"))

func qpFooter aArgs

	oText = aArgs[1]
	oText.Span("Page ")
	oText.CurrentPageNumber()

func qpBuildLong aArgs

	aArgs[1].Page(dnCallback("qpLongPage"))

func qpLongPage aArgs

	oPage = aArgs[1]
	oPage.Size(dnType("QuestPDF.Helpers.PageSizes").getProp("A4"))
	oPage.Margin(2)
	oPage.Content().Column(dnCallback("qpColumn"))
	oPage.Footer().AlignCenter().Text(dnCallback("qpFooterOf"))

func qpColumn aArgs

	oColumn = aArgs[1]
	oColumn.Item().Row(dnCallback("qpRow"))
	oColumn.Item().Table(dnCallback("qpTable"))
	for i = 1 to nLines
		oColumn.Item().Text("Line " + i)
	next

func qpRow aArgs

	oRow = aArgs[1]
	oRow.RelativeItem(NULL).Text("left")
	oRow.RelativeItem(NULL).AlignRight().Text("right")

func qpTable aArgs

	oTable = aArgs[1]
	oTable.ColumnsDefinition(dnCallback("qpColumns"))
	oTable.Cell().Text("Name")
	oTable.Cell().Text("Language")
	oTable.Cell().Text("RingDotNet")
	oTable.Cell().Text("Ring")

func qpColumns aArgs

	oColumns = aArgs[1]
	oColumns.RelativeColumn(NULL)
	oColumns.RelativeColumn(NULL)

func qpFooterOf aArgs

	oText = aArgs[1]
	oText.Span("Page ")
	oText.CurrentPageNumber()
	oText.Span(" of ")
	oText.TotalPages()
