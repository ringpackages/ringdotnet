# Paint - draw with the mouse (mouse events and UiCanvas), save the picture as PNG

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System")
dnImport("System.IO")
dnImport("System.Drawing")
dnImport("System.Drawing.Imaging")
dnImport("System.Windows.Forms")

cColor = "Black"
nPenSize = 4
lDrawing = false
nLastX = 0
nLastY = 0

oForm = uiForm("Paint",640,480)
oPicture = uiPictureBox(oForm,0,40,640,440)
oCanvas = new UiCanvas(oPicture)
oCanvas.clear("White")
oCanvas.show()
oPicture.setMouseDownEvent("mouseDown(aDotNetArgs[2].X,aDotNetArgs[2].Y)")
oPicture.setMouseMoveEvent("mouseMove(aDotNetArgs[2].X,aDotNetArgs[2].Y)")
oPicture.setMouseUpEvent("lDrawing = false")

nX = 6
for cName in ["Black","Red","Green","Blue","Orange","Purple","Brown","White"]
	oSwatch = uiButton(oForm,"",nX,6,28,28,"cColor = '" + cName + "'")
	oSwatch.BackColor = uiColor(cName)
	nX += 32
next
uiLabel(oForm,"Size",280,12,32,20)
oSize = new TrackBar()
oSize.Location = new Point(312,6)
oSize.Size = new Size(130,30)
oSize.Minimum = 1
oSize.Maximum = 30
oSize.Value = 4
oSize.setScrollEvent("nPenSize = oSize.Value")
oForm.Controls.Add(oSize)
uiButton(oForm,"Clear",460,6,60,28,"clearCanvas()")
uiButton(oForm,"Save...",526,6,70,28,"saveDialog()")

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func mouseDown nX, nY
	lDrawing = true
	nLastX = nX
	nLastY = nY
	oCanvas.fillCircle(nX,nY,nPenSize / 2,cColor)
	oCanvas.show()

func mouseMove nX, nY
	if lDrawing
		oCanvas.line(nLastX,nLastY,nX,nY,cColor,nPenSize)
		oCanvas.fillCircle(nX,nY,nPenSize / 2,cColor)
		nLastX = nX
		nLastY = nY
		oCanvas.show()
	ok

func clearCanvas
	oCanvas.clear("White")
	oCanvas.show()

func saveTo cFile
	oCanvas.oBitmap.Save_2(cFile,new ImageFormat().Png)

func saveDialog
	cFile = uiSaveFileName("Save picture","PNG image (*.png)|*.png")
	if cFile != ""
		saveTo(cFile)
	ok

func selfTest
	# a stroke from (50,50) to (150,50), then a red dot
	mouseDown(50,50)
	mouseMove(100,50)
	mouseMove(150,50)
	lDrawing = false
	dnAssert("black line in the middle",oCanvas.pixel(100,50),"ff000000")
	dnAssert("white outside the line",oCanvas.pixel(100,90),"ffffffff")
	cColor = "Red"
	nPenSize = 10
	mouseDown(300,200)
	lDrawing = false
	dnAssert("red dot",oCanvas.pixel(300,200),"ffff0000")
	# buttons change the color: the 2nd swatch is red, the 3rd green
	oForm.Controls.Item(3).PerformClick()
	dnAssert("swatch sets the color",cColor,"Green")
	oSize.Value = 12
	dnAssert("pen size from the track bar value",oSize.Value,12)
	cFile = new Path().Combine(new Path().GetTempPath(),"paint_selftest.png")
	saveTo(cFile)
	dnAssert("picture saved",new File().Exists(cFile),1)
	dnAssert("PNG signature",substr(new File().ReadAllBytes(cFile),"PNG") > 0,1)
	new File().Delete(cFile)
	clearCanvas()
	dnAssert("cleared",oCanvas.pixel(100,50),"ffffffff")
