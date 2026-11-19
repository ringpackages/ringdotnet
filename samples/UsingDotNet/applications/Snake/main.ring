# Snake - arrow keys, eat the food, do not hit the walls or yourself (a port of ring/applications/snake)

load "dotnet.ring"
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

uiRun(oForm)

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
