# 2048 - use the arrow keys (a port of ring/applications/game2048 to RingDotNet)

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_SIZE = 4
aBoard = list(C_SIZE * C_SIZE)	# 0 = empty
aTileLabels = []
nScore = 0
lGameOver = false

oForm = uiForm("2048",340,420)
oForm {
	KeyPreview = True
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
	BackColor = uiRGB(187,173,160)
}
oScore = uiLabel(oForm,"Score: 0",10,8,200,28)
oScore {
	Font = uiFont("Segoe UI",14,true)
	BackColor = uiRGB(187,173,160)
}
oNewGame = uiButton(oForm,"New game",230,8,100,28,"newGame()")
for nCell = 1 to C_SIZE * C_SIZE
	nRow = floor((nCell - 1) / C_SIZE)
	nCol = (nCell - 1) % C_SIZE
	oTile = uiLabel(oForm,"",10 + nCol * 80,50 + nRow * 80,76,76)
	oTile {
		TextAlign = "MiddleCenter"
		Font = uiFont("Segoe UI",20,true)
	}
	aTileLabels + oTile
next
uiGameKeys(oForm,"keyPressed(aDotNetArgs[2].KeyCode)")
newGame()

uiRun(oForm)

# --------------------------------------------------------------------------

func tileColor nValue

	switch nValue
	on 0	return uiRGB(205,193,180)
	on 2	return uiRGB(238,228,218)
	on 4	return uiRGB(237,224,200)
	on 8	return uiRGB(242,177,121)
	on 16	return uiRGB(245,149,99)
	on 32	return uiRGB(246,124,95)
	on 64	return uiRGB(246,94,59)
	on 128	return uiRGB(237,207,114)
	on 256	return uiRGB(237,204,97)
	on 512	return uiRGB(237,200,80)
	other	return uiRGB(237,194,46)
	off

func showBoard

	for nCell = 1 to len(aBoard)
		if aBoard[nCell] = 0
			aTileLabels[nCell].Text = ""
		else
			aTileLabels[nCell].Text = "" + aBoard[nCell]
		ok
		aTileLabels[nCell].BackColor = tileColor(aBoard[nCell])
	next
	oScore.Text = "Score: " + nScore

# slide one line to the left: [new line, points gained]
func slideLine aLine

	aKept = []
	for nValue in aLine
		if nValue != 0
			aKept + nValue
		ok
	next
	aOut = []
	nGained = 0
	nIndex = 1
	while nIndex <= len(aKept)
		if nIndex < len(aKept) and aKept[nIndex] = aKept[nIndex + 1]
			aOut + (aKept[nIndex] * 2)
			nGained += aKept[nIndex] * 2
			nIndex += 2
		else
			aOut + aKept[nIndex]
			nIndex++
		ok
	end
	while len(aOut) < len(aLine)
		aOut + 0
	end
	return [aOut,nGained]

# move the whole board: "Left" "Right" "Up" "Down"; true when something moved
func moveBoard cDirection

	lMoved = false
	for nLine = 1 to C_SIZE
		aLine = []
		for nStep = 1 to C_SIZE
			aLine + aBoard[cellIndex(nLine,nStep,cDirection)]
		next
		aResult = slideLine(aLine)
		for nStep = 1 to C_SIZE
			nIndex = cellIndex(nLine,nStep,cDirection)
			if aBoard[nIndex] != aResult[1][nStep]
				lMoved = true
				aBoard[nIndex] = aResult[1][nStep]
			ok
		next
		nScore += aResult[2]
	next
	return lMoved

# the cell that is the nStep-th of line nLine when sliding in cDirection (nStep 1 = the cell the tiles slide to)
func cellIndex nLine, nStep, cDirection

	switch cDirection
	on "Left"
		return (nLine - 1) * C_SIZE + nStep
	on "Right"
		return (nLine - 1) * C_SIZE + (C_SIZE + 1 - nStep)
	on "Up"
		return (nStep - 1) * C_SIZE + nLine
	on "Down"
		return (C_SIZE - nStep) * C_SIZE + nLine
	off

func addRandomTile

	aFree = []
	for nCell = 1 to len(aBoard)
		if aBoard[nCell] = 0
			aFree + nCell
		ok
	next
	if len(aFree) > 0
		if random(9) = 0
			aBoard[aFree[random(len(aFree) - 1) + 1]] = 4
		else
			aBoard[aFree[random(len(aFree) - 1) + 1]] = 2
		ok
	ok

func canMove

	for cDirection in ["Left","Right","Up","Down"]
		aSaved = aBoard
		nSavedScore = nScore
		lPossible = moveBoard(cDirection)
		aBoard = aSaved
		nScore = nSavedScore
		if lPossible
			return true
		ok
	next
	return false

func keyPressed cKey

	if lGameOver or find(["Left","Right","Up","Down"],cKey) = 0
		return
	but moveBoard(cKey)
		addRandomTile()
		if not canMove()
			lGameOver = true
			uiMessage("Game over! Score: " + nScore,"2048")
		ok
	ok
	showBoard()

func newGame

	aBoard = list(C_SIZE * C_SIZE)
	nScore = 0
	lGameOver = false
	addRandomTile()
	addRandomTile()
	showBoard()
