# Paint - draw with the mouse (mouse events and UiCanvas), save the picture as PNG

load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Drawing.Imaging"
	"System.Windows.Forms"
}

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
oPicture {
	setMouseDownEvent("mouseDown(aDotNetArgs[2].X,aDotNetArgs[2].Y)")
	setMouseMoveEvent("mouseMove(aDotNetArgs[2].X,aDotNetArgs[2].Y)")
	setMouseUpEvent("lDrawing = false")
}

nX = 6
for cName in ["Black","Red","Green","Blue","Orange","Purple","Brown","White"]
	oSwatch = uiButton(oForm,"",nX,6,28,28,"cColor = '" + cName + "'")
	oSwatch.BackColor = uiColor(cName)
	nX += 32
next
uiLabel(oForm,"Size",280,12,32,20)
oSize = new TrackBar() {
	Location = new Point(312,6)
	Size = new Size(130,30)
	Minimum = 1
	Maximum = 30
	Value = 4
	setScrollEvent("nPenSize = oSize.Value")
}
oForm.Controls.Add(oSize)
uiButton(oForm,"Clear",460,6,60,28,"clearCanvas()")
uiButton(oForm,"Save...",526,6,70,28,"saveDialog()")

uiRun(oForm)

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
	oCanvas.oBitmap.Save([ :filename = cFile, :format = new ImageFormat().Png ])

func saveDialog
	cFile = uiSaveFileName("Save picture","PNG image (*.png)|*.png")
	if cFile != ""
		saveTo(cFile)
	ok
