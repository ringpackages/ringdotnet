# printing - PrintDocument and the PrintPage event: a report on several pages, margins, page numbers, landscape, and a preview without a printer
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Drawing.Imaging"
	"System.Drawing.Printing"
	"System.Windows.Forms"                  # (it also loads the helpers uiFont and uiColor)
}

aRows = []                        # the report: [number, name, price]
nPage = 0                         # the page that is being printed
nNextRow = 1                      # the first row that has not been printed yet
aOnPage = []                      # how many rows each page got

func main

	# 1. A report with 100 rows
	for i = 1 to 100
		aRows + [ i, "Item " + right("000" + i,3), 2.5 + i * 0.75 ]
	next
	? "1. the report has " + len(aRows) + " rows"

	# 2. A PrintDocument is a document that can be sent to a printer. The program does not draw on the printer: it answers the event
	#    PrintPage, once for each page, and draws on e.Graphics. When the page is full it sets e.HasMorePages = True and the document
	#    asks for the next page.
	oDocument = new PrintDocument()
	oDocument.DocumentName = "Price list"

	# 3. The PREVIEW controller: the pages are made as pictures in memory, and no printer and no dialog are used. The program (and the
	#    test) can then look at the pages. A real print job leaves this line out. The paper is set explicitly (A4, in hundredths of an
	#    inch, with margins of half an inch), so the pages are the same on every computer.
	oPreview = new PreviewPrintController()
	oDocument.PrintController = oPreview
	setupPaper(oDocument,False)
	? nl + "2. paper: " + oDocument.DefaultPageSettings.PaperSize.Width + " x " + oDocument.DefaultPageSettings.PaperSize.Height + " hundredths of an inch"

	# 4. Print: the event runs for each page
	oDocument.setPrintPageEvent("drawPage(aDotNetArgs[2])")
	nPage = 0
	nNextRow = 1
	aOnPage = []
	oDocument.Print()
	? nl + "3. the report needed " + nPage + " pages; rows on each page: " + joinList(aOnPage)

	# 5. The preview pages are pictures, but not bitmaps: each one is a METAFILE, a list of the drawing commands that the program gave
	#    (it can be drawn at any size). To look at the pixels the program draws the metafile on a white bitmap of 827 x 1169 pixels.
	aPages = oPreview.GetPreviewPageInfo().toList()
	oBitmap = pageBitmap(aPages[1].Image,827,1169)
	? nl + "4. the preview has " + len(aPages) + " pages; the first as a bitmap is " + oBitmap.Width + " x " + oBitmap.Height + " pixels"
	? "   a pixel in the margin is " + oBitmap.GetPixel(10,10).Name + ", and the page has black pixels: " + yesNo(countDark(oBitmap) > 0)
	cFile = new Path().Combine([ new Path().GetTempPath(), "ringdotnet-page1.png" ])
	oBitmap.Save([ :filename = cFile, :format = new ImageFormat().Png ])
	? "   the first page was saved as a picture: " + yesNo(new FileInfo(cFile).Length > 0)
	new File().Delete(cFile)
	oLast = pageBitmap(aPages[len(aPages)].Image,827,1169)
	? "   the last page has less on it than the first: " + yesNo(countDark(oLast) < countDark(oBitmap))

	# 6. Landscape: the page is wide and low, so fewer rows fit and more pages are needed
	nPortrait = nPage
	setupPaper(oDocument,True)
	oPreview = new PreviewPrintController()
	oDocument.PrintController = oPreview
	nPage = 0
	nNextRow = 1
	aOnPage = []
	oDocument.Print()
	? nl + "5. in landscape: " + nPage + " pages instead of " + nPortrait + "; rows on each page: " + joinList(aOnPage)

# A4 is 827 x 1169 hundredths of an inch; the margins are 50 (half an inch). Landscape turns the page.
func setupPaper oDocument,lLandscape

	oDocument.DefaultPageSettings.PaperSize = new PaperSize().@New([ :name = "A4", :width = 827, :height = 1169 ])
	oDocument.DefaultPageSettings.Margins = new Margins().@New([ :left = 50, :right = 50, :top = 50, :bottom = 50 ])
	oDocument.DefaultPageSettings.Landscape = lLandscape

# The PrintPage event: draw one page. e.MarginBounds is the rectangle inside the margins (in hundredths of an inch).
func drawPage oArgs

	nPage++
	oGraphics = oArgs.Graphics
	oBounds = oArgs.MarginBounds
	oFont = uiFont("Arial",10,False)
	oBold = uiFont("Arial",10,True)
	oBrush = new SolidBrush(uiColor("Black"))
	nLine = oFont.@GetHeight(oGraphics)                 # the height of a line of text in the unit of the page (hundredths of an inch)
	nY = oBounds.Top

	# the header: the title and the page number
	oGraphics.DrawString([ :s = "Price list", :font = oBold, :brush = oBrush, :point = new PointF(oBounds.Left,nY) ])
	oGraphics.DrawString([ :s = "Page " + nPage, :font = oBold, :brush = oBrush, :point = new PointF(oBounds.Right - 60,nY) ])
	nY += nLine * 2

	# the rows: as many as fit above the bottom margin (one line is kept for the footer)
	nCount = 0
	while nNextRow <= len(aRows) and nY + nLine * 2 <= oBounds.Bottom
		aRow = aRows[nNextRow]
		oGraphics.DrawString([ :s = "" + aRow[1], :font = oFont, :brush = oBrush, :point = new PointF(oBounds.Left,nY) ])
		oGraphics.DrawString([ :s = aRow[2], :font = oFont, :brush = oBrush, :point = new PointF(oBounds.Left + 80,nY) ])
		oGraphics.DrawString([ :s = "" + aRow[3], :font = oFont, :brush = oBrush, :point = new PointF(oBounds.Left + 260,nY) ])
		nY += nLine
		nNextRow++
		nCount++
	end
	aOnPage + nCount

	# the footer, and the answer to the document: are there more pages?
	oGraphics.DrawString([ :s = "(" + (nNextRow - 1) + " of " + len(aRows) + " rows printed)", :font = oFont, :brush = oBrush, :point = new PointF(oBounds.Left,oBounds.Bottom - nLine) ])
	oArgs.HasMorePages = (nNextRow <= len(aRows))

# a metafile drawn on a white bitmap of the given size
func pageBitmap oMetafile,nWidth,nHeight

	oBitmap = new Bitmap(nWidth,nHeight)
	oGraphics = new Graphics().FromImage(oBitmap)
	oGraphics.Clear(uiColor("White"))
	oGraphics.DrawImage([ :image = oMetafile, :rect = new Rectangle(0,0,nWidth,nHeight) ])
	oGraphics.Dispose()
	return oBitmap

# how many pixels of a picture are dark (a step of 4 keeps it quick)
func countDark oImage

	nDark = 0
	for x = 0 to oImage.Width - 1 step 4
		for y = 0 to oImage.Height - 1 step 4
			oColor = oImage.GetPixel(x,y)
			if oColor.R < 100 and oColor.G < 100 and oColor.B < 100
				nDark++
			ok
		next
	next
	return nDark

func joinList aList

	cText = ""
	for item in aList
		if cText != ""
			cText += ", "
		ok
		cText += "" + item
	next
	return cText

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"
