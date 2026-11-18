# 2048 - use the arrow keys (a port of ring/applications/game2048 to RingDotNet)

load "dotnetlib.ring"
dnUseDesktop()
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

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

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
	ok
	if moveBoard(cKey)
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

func selfTest
	aResult = slideLine([2,2,4,0])
	dnAssert("slide merges",list2str(aResult[1]),list2str([4,4,0,0]))
	dnAssert("slide score",aResult[2],4)
	dnAssert("slide does not merge twice",list2str(slideLine([2,2,2,2])[1]),list2str([4,4,0,0]))
	dnAssert("slide gaps",list2str(slideLine([0,2,0,2])[1]),list2str([4,0,0,0]))
	aBoard = list(16)
	aBoard[1] = 2
	aBoard[4] = 2
	aBoard[5] = 4
	nScore = 0
	dnAssert("move left moved",moveBoard("Left"),1)
	dnAssert("left merged row 1",aBoard[1],4)
	aBoard = list(16)
	aBoard[1] = 2
	aBoard[2] = 2
	nScore = 0
	moveBoard("Right")
	dnAssert("right slides to the end",aBoard[4],4)
	aBoard = list(16)
	aBoard[1] = 8
	aBoard[5] = 8
	moveBoard("Down")
	dnAssert("down merges",aBoard[13],16)
	moveBoard("Up")
	dnAssert("up moves back",aBoard[1],16)
	dnAssert("score counts merges",nScore,20)
	dnAssert("no move possible when nothing changes",moveBoard("Up"),0)
	# keyboard handling goes through the KeyDown event handler
	newGame()
	nTiles = 0
	for nCell in aBoard
		if nCell > 0 nTiles++ ok
	next
	dnAssert("new game starts with two tiles",nTiles,2)
	keyPressed("Left")
	keyPressed("Up")
	dnAssert("game goes on",lGameOver,0)
	# real key presses, with the New game button focused (it used to take the arrow keys)
	oNewGame.Focus()
	aBoard = list(16)
	aBoard[1] = 2
	aBoard[2] = 2
	aBoard[16] = 4
	nScore = 0
	lGameOver = false
	if uiSendKeys(oForm,"{LEFT}")
		dnAssert("the left arrow key reaches the game",aBoard[1],4)
		aBoard = list(16)
		aBoard[1] = 8
		aBoard[5] = 8
		uiSendKeys(oForm,"{DOWN}")
		dnAssert("the down arrow key reaches the game",aBoard[13],16)
		aBoard = list(16)
		aBoard[13] = 16
		uiSendKeys(oForm,"{UP}")
		dnAssert("the up arrow key reaches the game",aBoard[1],16)
		uiSendKeys(oForm," ")
		dnAssert("Space does not press the New game button",nScore > 0,True)
	ok
	# a full board without equal neighbours is game over
	aBoard = [2,4,2,4, 4,2,4,2, 2,4,2,4, 4,2,4,2]
	dnAssert("no moves left",canMove(),0)
