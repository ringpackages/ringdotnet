# Image viewer - open a picture, zoom, rotate, flip, grayscale and save (System.Drawing)

load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Drawing.Imaging"
	"System.Windows.Forms"
}

oImage = ""		# the picture being shown (a Bitmap)
nZoom = 100

oForm = uiForm("Image viewer",640,480)
uiMenu(oForm,[
	["File",[["Open...","openDialog()","Control, O"],["Save As...","saveDialog()","Control, S"],["-",""],["Exit","oForm.Close()"]]],
	["Image",[["Rotate right","rotate()"],["Flip horizontal","flip()"],["Grayscale","grayscale()"],["-",""],["Zoom in","zoomBy(25)"],["Zoom out","zoomBy(-25)"],["Actual size","setZoom(100)"]]]
])
# the picture is shown in a panel that scrolls; the zoom changes the size of the picture box
oPanel = new Panel() {
	Dock = "Fill"
	AutoScroll = True
	BackColor = uiColor("DimGray")
}
oBox = new PictureBox() {
	SizeMode = "StretchImage"
	Location = new Point(0,0)
	Size = new Size(1,1)
}
oPanel.Controls.Add(oBox)
oForm.Controls.Add(oPanel)
oInfo = new StatusStrip()
oInfoText = new ToolStripStatusLabel()
oInfoText.Text = "No picture"
oInfo.Items.Add(oInfoText)
oForm.Controls.Add(oInfo)
oPanel.BringToFront()
oForm.setMouseWheelEvent("wheelZoom(aDotNetArgs[2].Delta)")

uiRun(oForm)

# --------------------------------------------------------------------------

func showImage

	if isobject(oImage)
		oBox.Image = oImage
		oBox.Width = max([1,floor(oImage.Width * nZoom / 100)])
		oBox.Height = max([1,floor(oImage.Height * nZoom / 100)])
		oInfoText.Text = "" + oImage.Width + " x " + oImage.Height + "   zoom " + nZoom + "%"
	ok

func openDialog

	cFile = uiOpenFileName("Open picture","Pictures|*.png;*.jpg;*.jpeg;*.bmp;*.gif|All files|*.*")
	if cFile != ""
		loadFile(cFile)
	ok

func loadFile cFile

	try
		oLoaded = new Bitmap(cFile,0)
	catch
		uiMessage("Can't open " + cFile + nl + "(is it a picture?)","Image viewer")
		return
	done
	oImage = oLoaded
	nZoom = 100
	cName = new Path().GetFileName(cFile)
	oForm.Text = cName + " - Image viewer"
	showImage()

func saveDialog

	cFile = uiSaveFileName("Save picture","PNG|*.png")
	if cFile != ""
		saveTo(cFile)
	ok

func saveTo cFile

	oImage.Save([ :filename = cFile, :format = new ImageFormat().Png ])

func rotate

	if isobject(oImage)
		oImage.RotateFlip("Rotate90FlipNone")
		showImage()
	ok

func flip

	if isobject(oImage)
		oImage.RotateFlip("RotateNoneFlipX")
		showImage()
	ok

# One call to .NET for the whole picture: a color matrix gives every pixel its gray value
# (a loop with GetPixel and SetPixel would cross from Ring to .NET several times for every pixel)
func grayscale

	if not isobject(oImage)
		return
	ok
	nWidth = oImage.Width
	nHeight = oImage.Height
	oMatrix = new ColorMatrix
	oMatrix.@New([
		[0.299,0.299,0.299,0,0],
		[0.587,0.587,0.587,0,0],
		[0.114,0.114,0.114,0,0],
		[0,0,0,1,0],
		[0,0,0,0,1] ])
	oAttributes = new ImageAttributes()
	oAttributes.SetColorMatrix(oMatrix)
	oGray = new Bitmap(nWidth,nHeight)
	oGraphics = new Graphics().FromImage(oGray)
	oGraphics.callMethod("DrawImage",[oImage,new Rectangle(0,0,nWidth,nHeight),0,0,nWidth,nHeight,"Pixel",oAttributes])
	oGraphics.Dispose()
	oImage.Dispose()
	oImage = oGray
	showImage()

func setZoom nPercent

	nZoom = nPercent
	showImage()

# the mouse wheel: turn it away from you to zoom in, towards you to zoom out
func wheelZoom nDelta

	if nDelta > 0
		zoomBy(25)
	but nDelta < 0
		zoomBy(-25)
	ok

func zoomBy nDelta

	nZoom += nDelta
	if nZoom < 25
		nZoom = 25
	ok
	if nZoom > 800
		nZoom = 800
	ok
	showImage()
