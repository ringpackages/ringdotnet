# Snake - arrow keys, eat the food, do not hit the walls or yourself (a port of ring/applications/snake)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_COLUMNS = 24
C_ROWS = 18
C_CELL = 20

aSnake = []		# [[x,y], ...] the head first
cDirection = "Right"
cNextDirection = "Right"
aFood = [0,0]
nScore = 0
lAlive = true

oForm = uiForm("Snake",C_COLUMNS * C_CELL,C_ROWS * C_CELL + 30)
oForm {
	KeyPreview = True
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}
oPicture = uiPictureBox(oForm,0,30,C_COLUMNS * C_CELL,C_ROWS * C_CELL)
oCanvas = new UiCanvas(oPicture)
oInfo = uiLabel(oForm,"",8,6,300,20)
oInfo.Font = uiFont("Segoe UI",11,true)
uiGameKeys(oForm,"keyPressed(aDotNetArgs[2].KeyCode)")
oTimer = uiTimer(130,"tick()")
newGame()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func newGame
	aSnake = [[12,9],[11,9],[10,9]]
	cDirection = "Right"
	cNextDirection = "Right"
	nScore = 0
	lAlive = true
	placeFood()
	draw()
	oTimer.Start()

func placeFood
	while true
		aFood = [random(C_COLUMNS - 1),random(C_ROWS - 1)]
		if not onSnake(aFood[1],aFood[2])
			exit
		ok
	end

func onSnake nX, nY
	for aPart in aSnake
		if aPart[1] = nX and aPart[2] = nY
			return true
		ok
	next
	return false

func keyPressed cKey
	if cKey = "Left" and cDirection != "Right"
		cNextDirection = "Left"
	but cKey = "Right" and cDirection != "Left"
		cNextDirection = "Right"
	but cKey = "Up" and cDirection != "Down"
		cNextDirection = "Up"
	but cKey = "Down" and cDirection != "Up"
		cNextDirection = "Down"
	but cKey = "Space" and not lAlive
		newGame()
	ok

# one step of the game
func tick
	if not lAlive
		return
	ok
	cDirection = cNextDirection
	nX = aSnake[1][1]
	nY = aSnake[1][2]
	switch cDirection
	on "Left"	nX--
	on "Right"	nX++
	on "Up"		nY--
	on "Down"	nY++
	off
	if nX < 0 or nY < 0 or nX >= C_COLUMNS or nY >= C_ROWS or onSnake(nX,nY)
		lAlive = false
		oTimer.Stop()
		draw()
		return
	ok
	insert(aSnake,0,[nX,nY])
	if nX = aFood[1] and nY = aFood[2]
		nScore += 10
		placeFood()
	else
		del(aSnake,len(aSnake))
	ok
	draw()

func draw
	oCanvas.clear("#202020")
	oCanvas.fillRect(aFood[1] * C_CELL + 2,aFood[2] * C_CELL + 2,C_CELL - 4,C_CELL - 4,"Red")
	for nIndex = 1 to len(aSnake)
		if nIndex = 1
			oCanvas.fillRect(aSnake[nIndex][1] * C_CELL + 1,aSnake[nIndex][2] * C_CELL + 1,C_CELL - 2,C_CELL - 2,"LimeGreen")
		else
			oCanvas.fillRect(aSnake[nIndex][1] * C_CELL + 1,aSnake[nIndex][2] * C_CELL + 1,C_CELL - 2,C_CELL - 2,"ForestGreen")
		ok
	next
	if lAlive
		oInfo.Text = "Score: " + nScore
	else
		oInfo.Text = "Game over - score " + nScore + " (Space = new game)"
	ok
	oCanvas.show()

func selfTest
	oTimer.Stop()
	aSnake = [[5,5],[4,5],[3,5]]
	cDirection = "Right"
	cNextDirection = "Right"
	aFood = [7,5]
	nScore = 0
	tick()
	tick()
	dnAssert("moved right",aSnake[1][1],7)
	dnAssert("ate the food and grew",len(aSnake),4)
	dnAssert("score",nScore,10)
	keyPressed("Left")
	dnAssert("cannot reverse",cNextDirection,"Right")
	keyPressed("Down")
	tick()
	dnAssert("turned down",aSnake[1][2],6)
	dnAssert("food pixel is red",oCanvas.pixel(aFood[1] * C_CELL + 10,aFood[2] * C_CELL + 10),"ffff0000")
	dnAssert("head pixel is green",oCanvas.pixel(aSnake[1][1] * C_CELL + 10,aSnake[1][2] * C_CELL + 10),"ff32cd32")
	# hit the bottom wall
	aSnake = [[5,C_ROWS - 1],[5,C_ROWS - 2],[5,C_ROWS - 3]]
	cDirection = "Down"
	cNextDirection = "Down"
	tick()
	dnAssert("game over at the wall",lAlive,0)
	keyPressed("Space")
	dnAssert("space starts again",lAlive,1)
	oTimer.Stop()
	cDirection = "Right"
	cNextDirection = "Right"
	if uiSendKeys(oForm,"{DOWN}")
		dnAssert("the down arrow key reaches the game",cNextDirection,"Down")
		uiSendKeys(oForm,"{UP}")
		dnAssert("the up arrow key reaches the game",cNextDirection,"Up")
	ok
	# hit itself
	aSnake = [[5,5],[5,6],[6,6],[6,5],[6,4]]
	cDirection = "Up"
	cNextDirection = "Right"
	tick()
	dnAssert("game over on itself",lAlive,0)
