# DocumentFormat.OpenXml: a Word document built as objects (Document, Body, Paragraph, Run, Text), saved to a stream and opened again
load "pkg.ring"
pkgUse("openxml",[["DocumentFormat.OpenXml","3.2.0"]],[["DocumentFormat.OpenXml.dll",["DocumentFormat.OpenXml.Packaging","DocumentFormat.OpenXml.Wordprocessing"]],["DocumentFormat.OpenXml.Framework.dll",[]]])
pkgImport("openxml","DocumentFormat.OpenXml.dll","DocumentFormat.OpenXml.Packaging")
pkgImport("openxml","DocumentFormat.OpenXml.dll","DocumentFormat.OpenXml.Wordprocessing")

oStream = dnNew("System.IO.MemoryStream",[])
oDocument = dnStatic("DocumentFormat.OpenXml.Packaging.WordprocessingDocument","Create",[oStream,dnStatic("DocumentFormat.OpenXml.WordprocessingDocumentType","Document",[])])
oMain = oDocument.AddMainDocumentPart()
oMain.Document = new Document()
oBody = new Body()
oMain.Document.AppendChild(oBody)

for cLine in ["First paragraph","مرحبا بالعالم","Third paragraph"]
	oParagraph = new WordprocessingParagraph()
	oRun = new WordprocessingRun()
	oText = new WordprocessingText().@New(cLine)
	oRun.AppendChild(oText)
	oParagraph.AppendChild(oRun)
	oBody.AppendChild(oParagraph)
next
oMain.Document.Save(NULL)
oDocument.Dispose()

cBytes = oStream.ToArray()
dnAssert("a docx is a zip",left(cBytes,2),"PK")

oRead = dnStatic("DocumentFormat.OpenXml.Packaging.WordprocessingDocument","Open",[dnNew("System.IO.MemoryStream",[cBytes]),0])
oReadBody = oRead.MainDocumentPart.Document.Body
dnAssert("three paragraphs",len(oReadBody.Elements().toList()),3)
dnAssert("the text of all of them",oReadBody.InnerText,"First paragraphمرحبا بالعالمThird paragraph")
oRead.Dispose()

dnTestSummary()
