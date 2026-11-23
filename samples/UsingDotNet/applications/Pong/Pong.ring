# Pong - Up/Down (or W/S) move your paddle, the computer plays the other one (a port of ring/applications/pong)

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_WIDTH = 600
C_HEIGHT = 400
C_PADDLE_HEIGHT = 80
C_PADDLE_WIDTH = 12

nPlayerY = 160		# the top of the paddles
nComputerY = 160
nBallX = 300
nBallY = 200
nBallDX = 5
nBallDY = 3
nPlayerScore = 0
nComputerScore = 0
nPlayerMove = 0		# -1, 0 or 1 while a key is held
nKeyEvents = 0		# key events seen (for the test)

oForm = uiForm("Pong",C_WIDTH,C_HEIGHT + 30)
oForm {
	KeyPreview = True
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}
oPicture = uiPictureBox(oForm,0,30,C_WIDTH,C_HEIGHT)
oCanvas = new UiCanvas(oPicture)
oScore = uiLabel(oForm,"",10,6,400,22)
oScore.Font = uiFont("Segoe UI",12,true)
uiGameKeys(oForm,"keyChanged(aDotNetArgs[2].KeyCode,true)")
oForm.setKeyUpEvent("keyChanged(aDotNetArgs[2].KeyCode,false)")
oTimer = uiTimer(20,"tick()")
oTimer.Start()
draw()

uiRun(oForm)

# --------------------------------------------------------------------------

func keyChanged cKey, lDown
	nKeyEvents++
	if cKey = "Up" or cKey = "W"
		if lDown
			nPlayerMove = -1
		else
			nPlayerMove = 0
		ok
	but cKey = "Down" or cKey = "S"
		if lDown
			nPlayerMove = 1
		else
			nPlayerMove = 0
		ok
	ok

func clampPaddle nY
	if nY < 0
		return 0
	but nY > C_HEIGHT - C_PADDLE_HEIGHT
		return C_HEIGHT - C_PADDLE_HEIGHT
	ok
	return nY

func serve nDirection
	nBallX = C_WIDTH / 2
	nBallY = C_HEIGHT / 2
	nBallDX = 5 * nDirection
	nBallDY = 3

# one step of the game
func tick
	nPlayerY = clampPaddle(nPlayerY + nPlayerMove * 7)
	# the computer follows the ball slowly
	nTarget = nBallY - C_PADDLE_HEIGHT / 2
	if nComputerY < nTarget - 4
		nComputerY = clampPaddle(nComputerY + 4)
	but nComputerY > nTarget + 4
		nComputerY = clampPaddle(nComputerY - 4)
	ok
	nBallX += nBallDX
	nBallY += nBallDY
	if nBallY < 6 or nBallY > C_HEIGHT - 6
		nBallDY = -nBallDY
	ok
	# paddles
	if nBallDX < 0 and nBallX < 30 + C_PADDLE_WIDTH and nBallY >= nPlayerY and nBallY <= nPlayerY + C_PADDLE_HEIGHT
		nBallDX = -nBallDX * 1.05
		nBallDY += (nBallY - (nPlayerY + C_PADDLE_HEIGHT / 2)) / 12
	ok
	if nBallDX > 0 and nBallX > C_WIDTH - 30 - C_PADDLE_WIDTH and nBallY >= nComputerY and nBallY <= nComputerY + C_PADDLE_HEIGHT
		nBallDX = -nBallDX * 1.05
		nBallDY += (nBallY - (nComputerY + C_PADDLE_HEIGHT / 2)) / 12
	ok
	# goals
	if nBallX < 0
		nComputerScore++
		serve(1)
	but nBallX > C_WIDTH
		nPlayerScore++
		serve(-1)
	ok
	draw()

func draw
	oCanvas.clear("Black")
	for nY = 0 to C_HEIGHT step 24
		oCanvas.fillRect(C_WIDTH / 2 - 2,nY,4,12,"DimGray")
	next
	oCanvas.fillRect(30,nPlayerY,C_PADDLE_WIDTH,C_PADDLE_HEIGHT,"DodgerBlue")
	oCanvas.fillRect(C_WIDTH - 30 - C_PADDLE_WIDTH,nComputerY,C_PADDLE_WIDTH,C_PADDLE_HEIGHT,"Tomato")
	oCanvas.fillCircle(nBallX,nBallY,7,"White")
	oScore.Text = "You " + nPlayerScore + "  :  " + nComputerScore + " Computer"
	oCanvas.show()
