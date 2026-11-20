# a PDF file with a NuGet package - PDFsharp makes the pages: text, lines and a title, then the program reads the file back
#   (the project is in the folder Pdf: Pdf.csproj names PdfSharp, and Empty.cs is the one source file a project needs)
load "dotnet.ring"
using { "System.IO" }

cHere = currentdir()
cDll = cHere + "/Pdf/libs/PdfSharp.dll"
cClasses = cHere + "/Pdf/classes"

# STEP 1. Get the package and the packages it needs (nuget.org the first time) with dotnet publish
if not fexists(cDll)
	? "getting the package..."
	system("dotnet publish Pdf -c Release -o Pdf/libs -nologo -v q > nul")
ok
if not fexists(cDll)
	? "The package could not be restored. It is downloaded from nuget.org the first time, so the computer needs the internet once."
	bye
ok

# STEP 2. Make Ring classes for the namespaces that the program uses
chdir("../../../tools/dotnettools")
system(exefilename() + " wrapassembly.ring " + cDll + " " + cClasses + " PdfSharp.Pdf PdfSharp.Pdf.IO PdfSharp.Drawing > nul")
chdir(cHere)

# STEP 3. Load the assembly and the classes
dnLoad(cDll)
dnImportFrom(cClasses + "/","PdfSharp.Pdf")
dnImportFrom(cClasses + "/","PdfSharp.Pdf.IO")
dnImportFrom(cClasses + "/","PdfSharp.Drawing")

func main
	cFile = new Path().Combine([new Path().GetTempPath(),"tutorial-report.pdf"])

	# 1. A document has pages, and a page is drawn with an XGraphics, like a canvas. Fonts are made with dnNew and the names of the
	#    parameters of the constructor; the brush and the pen are ready objects of the classes XBrushes and XPens.
	oDocument = new PdfDocument()
	oDocument.Info.Title = "Sales report"
	oTitleFont = dnNew("PdfSharp.Drawing.XFont",[ :familyName = "Arial", :emSize = 22 ])
	oTextFont = dnNew("PdfSharp.Drawing.XFont",[ :familyName = "Arial", :emSize = 12 ])
	oBlack = new XBrushes().Black
	oPen = new XPens().Black

	aProducts = [ ["Tea",12.5,4], ["Coffee",20,3], ["Cake",8.25,2] ]
	for nPage = 1 to 2
		oPage = oDocument.AddPage(NULL)
		oGraphics = new XGraphics().FromPdfPage(oPage)
		oGraphics.DrawString([ :s = "Sales report, page " + nPage, :font = oTitleFont, :brush = oBlack, :x = 50, :y = 60 ])
		oGraphics.DrawLine([ :pen = oPen, :x1 = 50, :y1 = 72, :x2 = 400, :y2 = 72 ])
		nY = 100
		for aProduct in aProducts
			cLine = aProduct[1] + "   " + aProduct[2] + " x " + aProduct[3]
			oGraphics.DrawString([ :s = cLine, :font = oTextFont, :brush = oBlack, :x = 50, :y = nY ])
			nY += 22
		next
		oGraphics.Dispose()
	next
	oDocument.Save(cFile)
	oDocument.Close()
	cBytes = new File().ReadAllBytes(cFile)
	? "1. written: " + (left(cBytes,4) = "%PDF") + ", " + (len(cBytes) > 1000)

	# 2. Read the file back (the mode "Import" opens it for reading its pages)
	oRead = new PdfReader().Open([ :path = cFile, :openmode = "Import" ])
	? "2. the file has " + oRead.PageCount + " pages, the title is '" + oRead.Info.Title + "'"
	new File().Delete(cFile)
