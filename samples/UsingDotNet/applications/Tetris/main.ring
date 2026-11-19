# Tetris - Left/Right move, Up rotates, Down drops one row, Space drops all the way (a port of ring/applications/tetris)

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_COLUMNS = 10
C_ROWS = 20
C_CELL = 24

# the 7 pieces: each is a list of [column, row] cells (rotated around the first cell)
aPieces = [
	[[0,0],[-1,0],[1,0],[2,0]],	# I
	[[0,0],[1,0],[0,1],[1,1]],	# O
	[[0,0],[-1,0],[1,0],[0,1]],	# T
	[[0,0],[-1,0],[1,0],[1,1]],	# L
	[[0,0],[-1,0],[1,0],[-1,1]],	# J
	[[0,0],[1,0],[-1,1],[0,1]],	# S
	[[0,0],[-1,0],[0,1],[1,1]]	# Z
]
aColors = ["Cyan","Gold","Purple","Orange","RoyalBlue","LimeGreen","Red"]

aBoard = list(C_COLUMNS * C_ROWS)	# 0 = empty, otherwise the piece number
aCurrent = []		# the cells of the falling piece (offsets)
nPiece = 0
nPieceX = 0
nPieceY = 0
nScore = 0
nLines = 0
lGameOver = false

oForm = uiForm("Tetris",C_COLUMNS * C_CELL + 150,C_ROWS * C_CELL)
oForm {
	KeyPreview = True
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}
oPicture = uiPictureBox(oForm,0,0,C_COLUMNS * C_CELL,C_ROWS * C_CELL)
oCanvas = new UiCanvas(oPicture)
oInfo = uiLabel(oForm,"",C_COLUMNS * C_CELL + 10,10,130,120)
oInfo.Font = uiFont("Segoe UI",11,true)
oNewGame = uiButton(oForm,"New game",C_COLUMNS * C_CELL + 10,140,120,30,"newGame()")
uiGameKeys(oForm,"keyPressed(aDotNetArgs[2].KeyCode)")
oTimer = uiTimer(500,"tick()")
newGame()

uiRun(oForm)

# --------------------------------------------------------------------------

func cellOf nColumn, nRow
	return nRow * C_COLUMNS + nColumn + 1

# does the piece fit at the position
func fits aCells, nX, nY
	for aCell in aCells
		nColumn = nX + aCell[1]
		nRow = nY + aCell[2]
		if nColumn < 0 or nColumn >= C_COLUMNS or nRow >= C_ROWS
			return false
		ok
		if nRow >= 0 and aBoard[cellOf(nColumn,nRow)] != 0
			return false
		ok
	next
	return true

func rotated aCells
	aNew = []
	for aCell in aCells
		aNew + [-aCell[2],aCell[1]]
	next
	return aNew

func newPiece
	nPiece = random(len(aPieces) - 1) + 1
	aCurrent = aPieces[nPiece]
	nPieceX = 4
	nPieceY = 0
	if not fits(aCurrent,nPieceX,nPieceY)
		lGameOver = true
		oTimer.Stop()
	ok

func newGame
	aBoard = list(C_COLUMNS * C_ROWS)
	nScore = 0
	nLines = 0
	lGameOver = false
	newPiece()
	draw()
	oTimer.Start()

# lock the piece into the board and clear the full rows
func lockPiece
	for aCell in aCurrent
		nColumn = nPieceX + aCell[1]
		nRow = nPieceY + aCell[2]
		if nRow >= 0
			aBoard[cellOf(nColumn,nRow)] = nPiece
		ok
	next
	nCleared = clearRows()
	aPoints = [0,100,300,500,800]
	nScore += aPoints[nCleared + 1]
	nLines += nCleared
	newPiece()

func clearRows
	nCleared = 0
	nRow = C_ROWS - 1
	while nRow >= 0
		lFull = true
		for nColumn = 0 to C_COLUMNS - 1
			if aBoard[cellOf(nColumn,nRow)] = 0
				lFull = false
				exit
			ok
		next
		if lFull
			# move everything above one row down
			for nMove = nRow to 1 step -1
				for nColumn = 0 to C_COLUMNS - 1
					aBoard[cellOf(nColumn,nMove)] = aBoard[cellOf(nColumn,nMove - 1)]
				next
			next
			for nColumn = 0 to C_COLUMNS - 1
				aBoard[cellOf(nColumn,0)] = 0
			next
			nCleared++
		else
			nRow--
		ok
	end
	return nCleared

func tick
	if lGameOver
		return
	ok
	if fits(aCurrent,nPieceX,nPieceY + 1)
		nPieceY++
	else
		lockPiece()
	ok
	draw()

func keyPressed cKey
	if lGameOver
		return
	ok
	switch cKey
	on "Left"
		if fits(aCurrent,nPieceX - 1,nPieceY)
			nPieceX--
		ok
	on "Right"
		if fits(aCurrent,nPieceX + 1,nPieceY)
			nPieceX++
		ok
	on "Up"
		aTurned = rotated(aCurrent)
		if fits(aTurned,nPieceX,nPieceY)
			aCurrent = aTurned
		ok
	on "Down"
		tick()
	on "Space"
		while fits(aCurrent,nPieceX,nPieceY + 1)
			nPieceY++
		end
		lockPiece()
	off
	draw()

func draw
	oCanvas.clear("#101820")
	for nRow = 0 to C_ROWS - 1
		for nColumn = 0 to C_COLUMNS - 1
			nValue = aBoard[cellOf(nColumn,nRow)]
			if nValue > 0
				oCanvas.fillRect(nColumn * C_CELL + 1,nRow * C_CELL + 1,C_CELL - 2,C_CELL - 2,aColors[nValue])
			ok
		next
	next
	if not lGameOver
		for aCell in aCurrent
			oCanvas.fillRect((nPieceX + aCell[1]) * C_CELL + 1,(nPieceY + aCell[2]) * C_CELL + 1,C_CELL - 2,C_CELL - 2,aColors[nPiece])
		next
	ok
	cText = "Score " + nScore + nl + "Lines " + nLines
	if lGameOver
		cText += nl + nl + "GAME OVER"
	ok
	oInfo.Text = cText
	oCanvas.show()
