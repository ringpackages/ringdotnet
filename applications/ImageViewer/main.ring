# Image viewer - open a picture, zoom, rotate, flip, grayscale and save (System.Drawing)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
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

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

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
	oImage.Save@([ :filename = cFile, :format = new ImageFormat().Png ])

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

func selfTest
	# make a small picture: red on the left half, blue on the right half
	oSample = new Bitmap(40,20)
	for nY = 0 to 19
		for nX = 0 to 39
			if nX < 20
				oSample.SetPixel(nX,nY,uiColor("Red"))
			else
				oSample.SetPixel(nX,nY,uiColor("Blue"))
			ok
		next
	next
	cFile = new Path().Combine(new Path().GetTempPath(),"imageviewer_selftest.png")
	oSample.Save@([ :filename = cFile, :format = new ImageFormat().Png ])
	loadFile(cFile)
	dnAssert("loaded size",oInfoText.Text,"40 x 20   zoom 100%")
	dnAssert("title",oForm.Text,"imageviewer_selftest.png - Image viewer")
	dnAssert("left is red",oImage.GetPixel(5,5).Name,"ffff0000")
	flip()
	dnAssert("flipped: left is blue",oImage.GetPixel(5,5).Name,"ff0000ff")
	rotate()
	dnAssert("rotated size",oInfoText.Text,"20 x 40   zoom 100%")
	grayscale()
	oGray = oImage.GetPixel(5,5)
	dnAssert("gray has equal channels",oGray.R = oGray.G and oGray.G = oGray.B,True)
	zoomBy(50)
	dnAssert("zoom",nZoom,150)
	zoomBy(-500)
	dnAssert("zoom has a minimum",nZoom,25)
	cOut = new Path().Combine(new Path().GetTempPath(),"imageviewer_saved.png")
	saveTo(cOut)
	dnAssert("saved",new File().Exists(cOut),True)
	oBox.Image = dnNull()
	oImage.Dispose()
	new File().Delete(cFile)
	new File().Delete(cOut)
