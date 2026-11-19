# drawing with the mouse - MouseDown, MouseMove and MouseUp: a small paint program with colors, a pen size, clear and save
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Drawing.Imaging"
	"System.Windows.Forms"
}

# controls and state that the event code uses are global variables
oForm = ""
oPicture = ""
oBitmap = ""
oStatus = ""
cColor = "Black"
nPenSize = 4
lDrawing = False                  # is the mouse button down?
nLastX = 0
nLastY = 0
nStrokes = 0

func main
	oForm = uiForm("Paint",460,380)
	uiButton(oForm,"Black",10,10,70,28,"setColor('Black')")
	uiButton(oForm,"Red",86,10,70,28,"setColor('Red')")
	uiButton(oForm,"Blue",162,10,70,28,"setColor('Blue')")
	uiButton(oForm,"Thin",250,10,60,28,"nPenSize = 2")
	uiButton(oForm,"Thick",316,10,60,28,"nPenSize = 12")
	uiButton(oForm,"Clear",382,10,60,28,"clearCanvas()")

	# The picture box shows a Bitmap, and the program draws on the bitmap. The mouse events say where the mouse is: aDotNetArgs[2] is the
	# event argument, with X and Y (in pixels from the top left corner of the picture box) and the Button.
	oBitmap = new Bitmap(430,280)
	oPicture = uiPictureBox(oForm,10,48,430,280)
	oPicture.Image = oBitmap
	oPicture.BorderStyle = "FixedSingle"
	oPicture.setMouseDownEvent("mouseDown(aDotNetArgs[2].X,aDotNetArgs[2].Y)")
	oPicture.setMouseMoveEvent("mouseMove(aDotNetArgs[2].X,aDotNetArgs[2].Y)")
	oPicture.setMouseUpEvent("mouseUp()")
	oStatus = uiLabel(oForm,"Press the mouse button on the white area and move",10,334,430,22)

	clearCanvas()
	uiTest(oForm,"selfTest()")
	uiRun(oForm)
	uiEnd()

func clearCanvas
	oGraphics = new Graphics().FromImage(oBitmap)
	oGraphics.Clear(uiColor("White"))
	oGraphics.Dispose()
	oPicture.Refresh()
	nStrokes = 0
	oStatus.Text = "Clear"

func setColor cName
	cColor = cName
	oStatus.Text = "Color: " + cName

# The three steps of a stroke. Down starts it (and draws a dot, so that a click without a move also leaves a mark), Move continues it
# with a line from the last place to this one, and Up ends it. Moving the mouse with the button up draws nothing.
func mouseDown nX,nY
	lDrawing = True
	nLastX = nX
	nLastY = nY
	drawDot(nX,nY)

func mouseMove nX,nY
	if not lDrawing
		return
	ok
	drawLine(nLastX,nLastY,nX,nY)
	nLastX = nX
	nLastY = nY

func mouseUp
	if lDrawing
		nStrokes++
		oStatus.Text = "" + nStrokes + " strokes"
	ok
	lDrawing = False

# a dot: a filled circle with the size of the pen (a line of length zero draws nothing, so the first point of a stroke is a circle)
func drawDot nX,nY
	oGraphics = new Graphics().FromImage(oBitmap)
	oBrush = new SolidBrush(uiColor(cColor))
	nRadius = nPenSize / 2
	oGraphics.FillEllipse([ :brush = oBrush, :rect = new Rectangle(nX - nRadius,nY - nRadius,nPenSize,nPenSize) ])
	oBrush.Dispose()
	oGraphics.Dispose()
	oPicture.Refresh()

# a line with a round pen: round ends make the joints of the small steps of the mouse smooth
func drawLine nX1,nY1,nX2,nY2
	oGraphics = new Graphics().FromImage(oBitmap)
	oPen = new Pen(uiColor(cColor)) {
		Width = nPenSize
		StartCap = "Round"
		EndCap = "Round"
	}
	oGraphics.DrawLine([ :pen = oPen, :pt1 = new Point(nX1,nY1), :pt2 = new Point(nX2,nY2) ])
	oPen.Dispose()
	oGraphics.Dispose()
	oPicture.Refresh()                      # draw the picture box again

func selfTest
	# a new canvas is white
	dnAssert("white at the start",oBitmap.GetPixel(100,100).Name,"ffffffff")

	# a stroke from (50,100) to (150,100): the mouse goes down, moves in steps and goes up
	mouseDown(50,100)
	for nX = 60 to 150 step 10
		mouseMove(nX,100)
	next
	mouseUp()
	dnAssert("black in the middle",oBitmap.GetPixel(100,100).Name,"ff000000")
	dnAssert("white above",oBitmap.GetPixel(100,80).Name,"ffffffff")
	dnAssert("one stroke",nStrokes,1)

	# moving with the button up draws nothing
	mouseMove(200,200)
	mouseMove(250,200)
	dnAssert("no line without the button",oBitmap.GetPixel(225,200).Name,"ffffffff")

	# a click without a move leaves a dot, in another color and a thick pen
	setColor("Red")
	nPenSize = 12
	mouseDown(300,150)
	mouseUp()
	dnAssert("a red dot",oBitmap.GetPixel(300,150).Name,"ffff0000")
	dnAssert("two strokes",nStrokes,2)

	# the picture can be saved
	cFile = new Path().Combine([ new Path().GetTempPath(),"ringdotnet-paint.png" ])
	oBitmap.Save([ :filename = cFile, :format = new ImageFormat().Png ])
	dnAssert("the file has data",new FileInfo(cFile).Length > 0,True)
	new File().Delete(cFile)

	# clear: white again
	clearCanvas()
	dnAssert("white after clear",oBitmap.GetPixel(100,100).Name,"ffffffff")
	dnAssert("no strokes after clear",nStrokes,0)
