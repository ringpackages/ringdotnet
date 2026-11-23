# Tic-Tac-Toe against the computer - a port of ring/applications/tictactoe to RingDotNet

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

aBoard = list(9)	# 0 = empty, 1 = X (you), 2 = O (computer)
aButtons = []
lGameOver = false
nWinsX = 0
nWinsO = 0
nDraws = 0
aLines = [[1,2,3],[4,5,6],[7,8,9],[1,4,7],[2,5,8],[3,6,9],[1,5,9],[3,5,7]]

oForm = uiForm("Tic-Tac-Toe",306,400)
oForm {
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}

for nIndex = 1 to 9
	nRow = floor((nIndex - 1) / 3)
	nCol = (nIndex - 1) % 3
	oButton = uiButton(oForm,"",3 + nCol * 100,3 + nRow * 100,100,100,"move(" + nIndex + ")")
	oButton.Font = uiFont("Segoe UI",36,true)
	aButtons + oButton
next

oStatus = uiLabel(oForm,"Your turn (X)",10,310,286,24)
oStatus.Font = uiFont("Segoe UI",11,true)
oScore = uiLabel(oForm,"",10,336,286,20)
uiButton(oForm,"New game",216,358,80,28,"newGame()")
showScore()

uiRun(oForm)

# --------------------------------------------------------------------------

func showScore
	oScore.Text = "You " + nWinsX + "   Computer " + nWinsO + "   Draws " + nDraws

func newGame
	aBoard = list(9)
	lGameOver = false
	for oButton in aButtons
		oButton {
			Text = ""
			BackColor = new Color().Empty
		}
	next
	oStatus.Text = "Your turn (X)"

func move nIndex
	if lGameOver or aBoard[nIndex] != 0
		return
	ok
	place(nIndex,1)
	if not lGameOver
		place(computerMove(),2)
	ok

func place nIndex, nPlayer
	aBoard[nIndex] = nPlayer
	if nPlayer = 1
		aButtons[nIndex].Text = "X"
		aButtons[nIndex].ForeColor = uiColor("DarkBlue")
	else
		aButtons[nIndex].Text = "O"
		aButtons[nIndex].ForeColor = uiColor("DarkRed")
	ok
	nWinner = winner(aBoard)
	if nWinner > 0
		lGameOver = true
		for nCell in aLines[nWinner]
			aButtons[nCell].BackColor = uiColor("LightGreen")
		next
		if aBoard[aLines[nWinner][1]] = 1
			nWinsX++
			oStatus.Text = "You win!"
		else
			nWinsO++
			oStatus.Text = "The computer wins"
		ok
		showScore()
	but isFull(aBoard)
		lGameOver = true
		nDraws++
		oStatus.Text = "Draw"
		showScore()
	else
		oStatus.Text = "Your turn (X)"
	ok

# index of the winning line (0 = none)
func winner aCells
	for nLine = 1 to len(aLines)
		nA = aCells[aLines[nLine][1]]
		if nA != 0 and nA = aCells[aLines[nLine][2]] and nA = aCells[aLines[nLine][3]]
			return nLine
		ok
	next
	return 0

func isFull aCells
	for nCell in aCells
		if nCell = 0
			return false
		ok
	next
	return true

# a cell that wins or blocks, else the center, a corner, any cell
func computerMove
	for nPlayer in [2,1]
		for nCell = 1 to 9
			if aBoard[nCell] = 0
				aBoard[nCell] = nPlayer
				nLineFound = winner(aBoard)
				aBoard[nCell] = 0
				if nLineFound > 0
					return nCell
				ok
			ok
		next
	next
	for nCell in [5,1,3,7,9,2,4,6,8]
		if aBoard[nCell] = 0
			return nCell
		ok
	next
