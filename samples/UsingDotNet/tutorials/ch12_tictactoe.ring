# a project - Tic-Tac-Toe (game logic in functions, nine buttons, a status line)
load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

# THE STATE: nine cells, "" (empty), "X" or "O"; whose turn it is; is the game over
aBoard = ["","","","","","","","",""]
cTurn = "X"
lOver = False

# THE WINDOW
oForm = ""
oStatus = ""
aButtons = []

func main

	oForm = uiForm("Tic-Tac-Toe",300,376)
	oStatus = uiLabel(oForm,"X to play",10,10,280,26)
	oStatus.Font = new Font("Segoe UI",14)
	for nCell = 1 to 9
		nRow = floor((nCell - 1) / 3)
		nColumn = (nCell - 1) % 3
		oButton = uiButton(oForm," ",10 + nColumn * 93,46 + nRow * 93,90,90,"play(" + nCell + ")")
		oButton.Font = new Font("Segoe UI",32)
		aButtons + oButton
	next
	uiButton(oForm,"New game",10,332,280,30,"newGame()")

	uiRun(oForm)

# ---------------------------------------------------------------- THE LOGIC (no window code here: easy to test)

# the winner of a board: "X", "O" or "" when nobody has won; the 8 lines of three cells
func winnerOf aCells

	aLines = [[1,2,3],[4,5,6],[7,8,9],[1,4,7],[2,5,8],[3,6,9],[1,5,9],[3,5,7]]
	for aLine in aLines
		cFirst = aCells[aLine[1]]
		if cFirst != "" and cFirst = aCells[aLine[2]] and cFirst = aCells[aLine[3]]
			return cFirst
		ok
	next
	return ""

func boardFull aCells

	for cCell in aCells
		if cCell = ""
			return False
		ok
	next
	return True

# ---------------------------------------------------------------- THE GAME: a move changes the state, then the window shows it

func play nCell

	if lOver or aBoard[nCell] != ""
		return
	ok
	aBoard[nCell] = cTurn
	aButtons[nCell].Text = cTurn
	cWinner = winnerOf(aBoard)
	if cWinner != ""
		oStatus.Text = cWinner + " wins!"
		lOver = True
	but boardFull(aBoard)
		oStatus.Text = "A draw"
		lOver = True
	else
		if cTurn = "X"
			cTurn = "O"
		else
			cTurn = "X"
		ok
		oStatus.Text = cTurn + " to play"
	ok

func newGame

	aBoard = ["","","","","","","","",""]
	cTurn = "X"
	lOver = False
	for oButton in aButtons
		oButton.Text = " "
	next
	oStatus.Text = "X to play"

# ---------------------------------------------------------------- THE TESTS: first the logic, then the window
