# Fifteen puzzle (sliding tiles) - a port of ring/applications/fifteenpuzzle to RingDotNet

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_SIZE = 4
aTiles = []		# aTiles[cell] = tile number (0 = the empty cell)
aCells = []		# the buttons
nMoves = 0

oForm = uiForm("Fifteen puzzle",324,390)
oForm {
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}
for nCell = 1 to C_SIZE * C_SIZE
	nRow = floor((nCell - 1) / C_SIZE)
	nCol = (nCell - 1) % C_SIZE
	oCell = uiButton(oForm,"",10 + nCol * 75,10 + nRow * 75,72,72,"clickCell(" + nCell + ")")
	oCell.Font = uiFont("Segoe UI",20,true)
	aCells + oCell
	aTiles + (nCell % (C_SIZE * C_SIZE))
next
oMoves = uiLabel(oForm,"Moves: 0",10,320,150,24)
oMoves.Font = uiFont("Segoe UI",11,false)
uiButton(oForm,"Shuffle",220,316,94,30,"shuffleBoard()")
oMessage = uiLabel(oForm,"",10,350,300,24)
shuffleBoard()

uiRun(oForm)

# --------------------------------------------------------------------------

func showBoard
	for nCell = 1 to len(aTiles)
		if aTiles[nCell] = 0
			aCells[nCell].Text = ""
			aCells[nCell].BackColor = uiColor("Gainsboro")
		else
			aCells[nCell].Text = "" + aTiles[nCell]
			aCells[nCell].BackColor = uiColor("White")
		ok
	next
	oMoves.Text = "Moves: " + nMoves

func emptyCell
	return find(aTiles,0)

# cells that touch the cell
func neighbors nCell
	aList = []
	nRow = floor((nCell - 1) / C_SIZE)
	nCol = (nCell - 1) % C_SIZE
	if nRow > 0 aList + (nCell - C_SIZE) ok
	if nRow < C_SIZE - 1 aList + (nCell + C_SIZE) ok
	if nCol > 0 aList + (nCell - 1) ok
	if nCol < C_SIZE - 1 aList + (nCell + 1) ok
	return aList

func slideTile nCell
	nEmpty = emptyCell()
	if find(neighbors(nEmpty),nCell) > 0
		aTiles[nEmpty] = aTiles[nCell]
		aTiles[nCell] = 0
		return true
	ok
	return false

func clickCell nCell
	if slideTile(nCell)
		nMoves++
		showBoard()
		if isSolved()
			oMessage.Text = "Solved in " + nMoves + " moves!"
		ok
	ok

func isSolved
	for nCell = 1 to len(aTiles) - 1
		if aTiles[nCell] != nCell
			return false
		ok
	next
	return true

# shuffle with legal moves only, so the puzzle is always solvable
func shuffleBoard
	for nCell = 1 to len(aTiles)
		aTiles[nCell] = nCell % len(aTiles)
	next
	for nStep = 1 to 200
		aNear = neighbors(emptyCell())
		slideTile(aNear[random(len(aNear) - 1) + 1])
	next
	nMoves = 0
	oMessage.Text = ""
	showBoard()
