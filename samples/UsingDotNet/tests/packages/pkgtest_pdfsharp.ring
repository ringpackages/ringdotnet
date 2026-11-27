# PDFsharp: a PDF document made in memory (pages with a size and an orientation, document information, drawn shapes), saved, and opened again to read it back
load "pkg.ring"
pkgUse("pdfsharp",[["PDFsharp","6.2.4"]],[["PdfSharp.dll",["PdfSharp.Pdf","PdfSharp.Pdf.IO","PdfSharp.Drawing"]]])
pkgImport("pdfsharp","PdfSharp.dll","PdfSharp.Pdf")
pkgImport("pdfsharp","PdfSharp.dll","PdfSharp.Pdf.IO")
pkgImport("pdfsharp","PdfSharp.dll","PdfSharp.Drawing")

using {
	"System.IO"
}

oDoc = new PdfDocument()
oInfo = oDoc.Info
oInfo.Title = "A document from Ring"
oInfo.Author = "RingDotNet"
oPage = oDoc.AddPage(NULL)
oPage.Size = "A4"
dnAssert("a page was added",oDoc.PageCount,1)
oSecond = oDoc.AddPage(NULL)
oSecond.Size = "A5"
oSecond.Orientation = "Landscape"
dnAssert("two pages",oDoc.PageCount,2)

# the sizes of the standard page formats, in points (1/72 inch)
oWidth = oPage.Width
oHeight = oPage.Height
dnAssert("A4 is 595 points wide",floor(oWidth.Point),595)
dnAssert("A4 is 842 points high",floor(oHeight.Point),842)
oLandscapeWidth = oSecond.Width
dnAssert("A5 landscape is 595 points wide",floor(oLandscapeWidth.Point),595)

# shapes drawn on the first page
oGraphics = dnStatic("PdfSharp.Drawing.XGraphics","FromPdfPage",[oPage])
oPens = new XPens()
oBrushes = new XBrushes()
oGraphics.DrawRectangle([ :pen = oPens.Black, :brush = oBrushes.LightBlue, :x = 50, :y = 50, :width = 200, :height = 100 ])
oGraphics.DrawEllipse([ :pen = oPens.DarkRed, :x = 100, :y = 200, :width = 120, :height = 80 ])
oGraphics.Dispose()

# saved to a file, and opened again
cFile = new Path().Combine([ new Path().GetTempPath(),"ringdotnet_pdfsharp_test.pdf" ])
oDoc.Save(cFile)
dnAssert("the file exists",new File().Exists(cFile),1)
cHead = left(read(cFile),5)
dnAssert("the file is a PDF",cHead,"%PDF-")
oRead = dnStatic("PdfSharp.Pdf.IO.PdfReader","Open",[cFile,"Import"])
dnAssert("the pages are read back",oRead.PageCount,2)
oReadInfo = oRead.Info
dnAssert("the title is read back",oReadInfo.Title,"A document from Ring")
dnAssert("the author is read back",oReadInfo.Author,"RingDotNet")
oRead.Close()
new File().Delete(cFile)

dnTestSummary()
