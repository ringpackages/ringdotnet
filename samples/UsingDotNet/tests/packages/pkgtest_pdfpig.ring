# PdfPig: reads text and page data from PDF bytes; the PDF is made here as a binary text with correct offsets
load "pkg.ring"
pkgUse("pdfpig",[["PdfPig","0.1.9"]],[["UglyToad.PdfPig.dll",["UglyToad.PdfPig","UglyToad.PdfPig.Content"]],["UglyToad.PdfPig.Core.dll",[]],["UglyToad.PdfPig.Fonts.dll",[]],["UglyToad.PdfPig.Tokenization.dll",[]],["UglyToad.PdfPig.Tokens.dll",[]]])
pkgImport("pdfpig","UglyToad.PdfPig.dll","UglyToad.PdfPig")
pkgImport("pdfpig","UglyToad.PdfPig.dll","UglyToad.PdfPig.Content")

cFile = cPkgCache + "pdfpig/test.pdf"
write(cFile,makePdf("Hello from Ring"))
oDoc = dnStatic("UglyToad.PdfPig.PdfDocument","Open",[cFile])
dnAssert("one page",oDoc.NumberOfPages,1)
oPage = oDoc.GetPage(1)
dnAssert("the page text",oPage.Text,"Hello from Ring")
dnAssert("the page width",oPage.Width,200)
dnAssert("the page height",oPage.Height,100)
dnAssert("two words",len(oPage.GetWords(NULL).toList()),3)
oDoc.Dispose()

cBad = cPkgCache + "pdfpig/bad.pdf"
write(cBad,"this is not a pdf")
cError = ""
try
	dnStatic("UglyToad.PdfPig.PdfDocument","Open",[cBad])
catch
	cError = cCatchError
done
dnAssert("a text that is not a PDF raises an error",len(cError) > 0,1)

dnTestSummary()

func makePdf cText
	cStream = "BT /F1 12 Tf 10 50 Td (" + cText + ") Tj ET"
	aObjects = [
		"<< /Type /Catalog /Pages 2 0 R >>",
		"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
		"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 100] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>",
		"<< /Length " + len(cStream) + " >>" + char(10) + "stream" + char(10) + cStream + char(10) + "endstream",
		"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
	]
	cOut = "%PDF-1.4" + char(10)
	aOffsets = []
	for i = 1 to len(aObjects)
		aOffsets + len(cOut)
		cOut += "" + i + " 0 obj" + char(10) + aObjects[i] + char(10) + "endobj" + char(10)
	next
	nXref = len(cOut)
	cOut += "xref" + char(10) + "0 " + (len(aObjects) + 1) + char(10)
	cOut += "0000000000 65535 f " + char(10)
	for nOffset in aOffsets
		cOut += substr("0000000000",1,10 - len("" + nOffset)) + nOffset + " 00000 n " + char(10)
	next
	cOut += "trailer" + char(10) + "<< /Size " + (len(aObjects) + 1) + " /Root 1 0 R >>" + char(10) + "startxref" + char(10) + nXref + char(10) + "%%EOF" + char(10)
	return cOut
