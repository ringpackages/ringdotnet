# Conway's Game of Life - click cells to toggle them, Start runs the generations
# (a port of ring/applications/gameoflife to RingDotNet)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")

C_COLUMNS = 40
C_ROWS = 28
C_CELL = 14

aCells = list(C_COLUMNS * C_ROWS)	# 1 = alive
nGeneration = 0

oForm = uiForm("Game of Life",C_COLUMNS * C_CELL,C_ROWS * C_CELL + 40)
oForm.FormBorderStyle = "FixedSingle"
oForm.MaximizeBox = 0
oPicture = uiPictureBox(oForm,0,40,C_COLUMNS * C_CELL,C_ROWS * C_CELL)
oCanvas = new UiCanvas(oPicture)
oPicture.setMouseDownEvent("clickCell(aDotNetArgs[2].X,aDotNetArgs[2].Y)")
oRun = uiButton(oForm,"Start",6,6,70,28,"startStop()")
uiButton(oForm,"Step",82,6,60,28,"nextGeneration()")
uiButton(oForm,"Clear",148,6,60,28,"clearAll()")
uiButton(oForm,"Random",214,6,70,28,"randomFill()")
uiButton(oForm,"Glider",290,6,70,28,"glider()")
oInfo = uiLabel(oForm,"",370,12,180,20)
oTimer = uiTimer(120,"nextGeneration()")
glider()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func cellIndex nColumn, nRow
	return nRow * C_COLUMNS + nColumn + 1

func isAlive nColumn, nRow
	# the world wraps around
	nColumn = (nColumn + C_COLUMNS) % C_COLUMNS
	nRow = (nRow + C_ROWS) % C_ROWS
	return aCells[cellIndex(nColumn,nRow)]

func countNeighbours nColumn, nRow
	nTotal = 0
	for nDy = -1 to 1
		for nDx = -1 to 1
			if nDx != 0 or nDy != 0
				nTotal += isAlive(nColumn + nDx,nRow + nDy)
			ok
		next
	next
	return nTotal

func nextGeneration
	aNext = list(C_COLUMNS * C_ROWS)
	for nRow = 0 to C_ROWS - 1
		for nColumn = 0 to C_COLUMNS - 1
			nNear = countNeighbours(nColumn,nRow)
			if aCells[cellIndex(nColumn,nRow)]
				aNext[cellIndex(nColumn,nRow)] = (nNear = 2 or nNear = 3)
			else
				aNext[cellIndex(nColumn,nRow)] = (nNear = 3)
			ok
		next
	next
	aCells = aNext
	nGeneration++
	draw()

func population
	nTotal = 0
	for nCell in aCells
		nTotal += nCell
	next
	return nTotal

func draw
	oCanvas.clear("White")
	for nRow = 0 to C_ROWS - 1
		for nColumn = 0 to C_COLUMNS - 1
			if aCells[cellIndex(nColumn,nRow)]
				oCanvas.fillRect(nColumn * C_CELL + 1,nRow * C_CELL + 1,C_CELL - 1,C_CELL - 1,"DarkGreen")
			ok
		next
	next
	oInfo.Text = "Generation " + nGeneration + ", cells " + population()
	oCanvas.show()

func clickCell nMouseX, nMouseY
	nColumn = floor(nMouseX / C_CELL)
	nRow = floor(nMouseY / C_CELL)
	nIndex = cellIndex(nColumn,nRow)
	aCells[nIndex] = not aCells[nIndex]
	draw()

func startStop
	if oRun.Text = "Start"
		oRun.Text = "Stop"
		oTimer.Start()
	else
		oRun.Text = "Start"
		oTimer.Stop()
	ok

func clearAll
	aCells = list(C_COLUMNS * C_ROWS)
	nGeneration = 0
	draw()

func randomFill
	for nCell = 1 to len(aCells)
		aCells[nCell] = (random(3) = 0)
	next
	nGeneration = 0
	draw()

func glider
	aCells = list(C_COLUMNS * C_ROWS)
	for aPoint in [[1,0],[2,1],[0,2],[1,2],[2,2]]
		aCells[cellIndex(aPoint[1] + 5,aPoint[2] + 5)] = 1
	next
	nGeneration = 0
	draw()

func selfTest
	dnAssert("glider has 5 cells",population(),5)
	for nStep = 1 to 4
		nextGeneration()
	next
	dnAssert("still 5 cells after 4 generations",population(),5)
	dnAssert("the glider moved by (1,1)",isAlive(7,6) + isAlive(8,7) + isAlive(6,8) + isAlive(7,8) + isAlive(8,8),5)
	dnAssert("cell is drawn",oCanvas.pixel(8 * C_CELL + 5,8 * C_CELL + 5),"ff006400")
	# a blinker flips between horizontal and vertical
	clearAll()
	for nColumn = 10 to 12
		aCells[cellIndex(nColumn,10)] = 1
	next
	nextGeneration()
	dnAssert("blinker is vertical",isAlive(11,9) + isAlive(11,10) + isAlive(11,11),3)
	nextGeneration()
	dnAssert("blinker is horizontal again",isAlive(10,10) + isAlive(11,10) + isAlive(12,10),3)
	# a click toggles a cell
	clearAll()
	clickCell(3 * C_CELL + 2,4 * C_CELL + 2)
	dnAssert("click makes a cell alive",isAlive(3,4),1)
	clickCell(3 * C_CELL + 2,4 * C_CELL + 2)
	dnAssert("second click removes it",isAlive(3,4),0)
	oRun.PerformClick()
	dnAssert("button starts the timer",oRun.Text,"Stop")
	oRun.PerformClick()
