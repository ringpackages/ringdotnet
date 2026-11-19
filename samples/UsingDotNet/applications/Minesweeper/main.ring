# Minesweeper - left click reveals, right click flags (a port of ring/applications/minesweeper)

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_COLUMNS = 9
C_ROWS = 9
C_MINES = 10
C_SIZE = 32

aMine = list(C_COLUMNS * C_ROWS)	# 1 = mine
aRevealed = list(C_COLUMNS * C_ROWS)
aFlagged = list(C_COLUMNS * C_ROWS)
aButtons = []
lPlaying = true
nFlags = 0

oForm = uiForm("Minesweeper",C_COLUMNS * C_SIZE + 20,C_ROWS * C_SIZE + 70)
oForm {
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}
oInfo = uiLabel(oForm,"",10,8,200,24)
oInfo.Font = uiFont("Segoe UI",11,true)
uiButton(oForm,"New game",C_COLUMNS * C_SIZE - 80,6,90,28,"newGame()")
for nCell = 1 to C_COLUMNS * C_ROWS
	nRow = floor((nCell - 1) / C_COLUMNS)
	nColumn = (nCell - 1) % C_COLUMNS
	oButton = uiButton(oForm,"",10 + nColumn * C_SIZE,44 + nRow * C_SIZE,C_SIZE,C_SIZE,"")
	oButton {
		Font = uiFont("Segoe UI",11,true)
		Margin = dnNew("Padding",[ :all = 0 ])
		setMouseUpEvent("cellClicked(" + nCell + ",aDotNetArgs[2].Button)")
	}
	aButtons + oButton
next
newGame()

uiRun(oForm)

# --------------------------------------------------------------------------

func neighbours nCell
	aList = []
	nRow = floor((nCell - 1) / C_COLUMNS)
	nColumn = (nCell - 1) % C_COLUMNS
	for nDy = -1 to 1
		for nDx = -1 to 1
			if nDx != 0 or nDy != 0
				nR = nRow + nDy
				nC = nColumn + nDx
				if nR >= 0 and nR < C_ROWS and nC >= 0 and nC < C_COLUMNS
					aList + (nR * C_COLUMNS + nC + 1)
				ok
			ok
		next
	next
	return aList

func mineCount nCell
	nTotal = 0
	for nNear in neighbours(nCell)
		nTotal += aMine[nNear]
	next
	return nTotal

func newGame
	aMine = list(C_COLUMNS * C_ROWS)
	aRevealed = list(C_COLUMNS * C_ROWS)
	aFlagged = list(C_COLUMNS * C_ROWS)
	nPlaced = 0
	while nPlaced < C_MINES
		nCell = random(C_COLUMNS * C_ROWS - 1) + 1
		if not aMine[nCell]
			aMine[nCell] = 1
			nPlaced++
		ok
	end
	startPlay()

func startPlay
	lPlaying = true
	nFlags = 0
	for oButton in aButtons
		oButton {
			Text = ""
			Enabled = True
			BackColor = new Color().Empty
		}
	next
	showInfo()

func showInfo
	if lPlaying
		oInfo.Text = "Mines left: " + (C_MINES - nFlags)
	ok

func cellClicked nCell, cButton
	if not lPlaying
		return
	ok
	if cButton = "Right"
		toggleFlag(nCell)
	else
		reveal(nCell)
	ok

func toggleFlag nCell
	if aRevealed[nCell]
		return
	ok
	aFlagged[nCell] = not aFlagged[nCell]
	if aFlagged[nCell]
		aButtons[nCell].Text = "F"
		aButtons[nCell].ForeColor = uiColor("Red")
		nFlags++
	else
		aButtons[nCell].Text = ""
		nFlags--
	ok
	showInfo()

func reveal nCell
	if aRevealed[nCell] or aFlagged[nCell]
		return
	ok
	if aMine[nCell]
		gameOver()
		return
	ok
	# flood fill over the cells without mines around
	aQueue = [nCell]
	while len(aQueue) > 0
		nCurrent = aQueue[len(aQueue)]
		del(aQueue,len(aQueue))
		if aRevealed[nCurrent]
			loop
		ok
		aRevealed[nCurrent] = 1
		aButtons[nCurrent].BackColor = uiColor("LightGray")
		nNear = mineCount(nCurrent)
		if nNear > 0
			aButtons[nCurrent].Text = "" + nNear
			aButtons[nCurrent].ForeColor = numberColor(nNear)
		else
			aButtons[nCurrent].Text = ""
			for nOther in neighbours(nCurrent)
				if not aRevealed[nOther] and not aFlagged[nOther]
					aQueue + nOther
				ok
			next
		ok
	end
	checkWin()

func numberColor nNear
	aColors = ["Blue","Green","Red","DarkBlue","Brown","Teal","Black","Gray"]
	return uiColor(aColors[nNear])

func checkWin
	nHidden = 0
	for nCell = 1 to len(aRevealed)
		if not aRevealed[nCell]
			nHidden++
		ok
	next
	if nHidden = C_MINES
		lPlaying = false
		oInfo.Text = "You won!"
	ok

func gameOver
	lPlaying = false
	for nCell = 1 to len(aMine)
		if aMine[nCell]
			aButtons[nCell].Text = "*"
			aButtons[nCell].BackColor = uiColor("Tomato")
		ok
	next
	oInfo.Text = "Boom! Game over"
