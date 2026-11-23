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
oBox = new PictureBox() {
	Dock = "Fill"
	SizeMode = "Zoom"
	BackColor = uiColor("DimGray")
}
oForm.Controls.Add(oBox)
oInfo = new StatusStrip()
oInfoText = new ToolStripStatusLabel()
oInfoText.Text = "No picture"
oInfo.Items.Add(oInfoText)
oForm.Controls.Add(oInfo)
oBox.BringToFront()

uiRun(oForm)

# --------------------------------------------------------------------------

func showImage
	if isobject(oImage)
		oBox.Image = oImage
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

func grayscale
	if not isobject(oImage)
		return
	ok
	for nY = 0 to oImage.Height - 1
		for nX = 0 to oImage.Width - 1
			oPixel = oImage.GetPixel(nX,nY)
			nGray = floor(oPixel.R * 0.299 + oPixel.G * 0.587 + oPixel.B * 0.114)
			oImage.SetPixel(nX,nY,uiRGB(nGray,nGray,nGray))
		next
	next
	showImage()

func setZoom nPercent
	nZoom = nPercent
	if nZoom = 100
		oBox.SizeMode = "Zoom"
	else
		oBox.SizeMode = "CenterImage"
	ok
	showImage()

func zoomBy nDelta
	nZoom += nDelta
	if nZoom < 25
		nZoom = 25
	ok
	showImage()
