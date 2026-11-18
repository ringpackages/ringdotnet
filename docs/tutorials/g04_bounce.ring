# Tutorial 14: drawing and animation - a canvas, a timer and the keyboard
load "dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_WIDTH = 400
C_HEIGHT = 260

oForm = ""
oPicture = ""
oCanvas = ""
oTimer = ""
nX = 60
nY = 40
nDX = 4
nDY = 3
nPaddle = 160
nScore = 0

func main
	oForm = uiForm("Bounce",C_WIDTH,C_HEIGHT)
	oPicture = uiPictureBox(oForm,0,0,C_WIDTH,C_HEIGHT)
	oCanvas = new UiCanvas(oPicture)               # a canvas draws on the picture box
	draw()

	# the form (not a button) must receive the keys: arrows move the paddle
	oForm.KeyPreview = True
	oForm.setKeyDownEvent("keyPressed(aDotNetArgs[2].KeyCode)")

	# a timer calls step() every 20 milliseconds
	oTimer = uiTimer(20,"step()")
	oTimer.Start()

	uiTest(oForm,"selfTest()")
	uiRun(oForm)
	uiEnd()

func step
	nX += nDX
	nY += nDY
	if nX < 10 or nX > C_WIDTH - 10
		nDX = -nDX
	ok
	if nY < 10
		nDY = -nDY
	ok
	# the ball hits the paddle
	if nY >= C_HEIGHT - 30 and nX >= nPaddle and nX <= nPaddle + 80 and nDY > 0
		nDY = -nDY
		nScore++
	ok
	if nY > C_HEIGHT
		nY = 40
		nScore = 0
	ok
	draw()

func draw
	oCanvas.clear("Black")
	oCanvas.fillCircle(nX,nY,10,"Orange")
	oCanvas.fillRect(nPaddle,C_HEIGHT - 20,80,10,"SteelBlue")
	oCanvas.text("Score " + nScore,8,6,"White",11)
	oCanvas.show()

func keyPressed cKey
	if cKey = "Left"
		nPaddle = max(0,nPaddle - 30)
	but cKey = "Right"
		nPaddle = min(C_WIDTH - 80,nPaddle + 30)
	ok
	draw()

func selfTest
	oTimer.Stop()
	nBefore = nX
	step() step() step()
	dnAssert("the ball moved",nX,nBefore + 3 * nDX)
	keyPressed("Left")
	dnAssert("the paddle moved",nPaddle,130)
	dnAssert("the ball is orange",oCanvas.pixel(nX,nY),"ffffa500")
