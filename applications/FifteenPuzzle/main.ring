# Fifteen puzzle (sliding tiles) - a port of ring/applications/fifteenpuzzle to RingDotNet

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
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

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

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
func neighbours nCell
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
	if find(neighbours(nEmpty),nCell) > 0
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
		aNear = neighbours(emptyCell())
		slideTile(aNear[random(len(aNear) - 1) + 1])
	next
	nMoves = 0
	oMessage.Text = ""
	showBoard()

func selfTest
	# a position one move from solved
	for nCell = 1 to 15
		aTiles[nCell] = nCell
	next
	aTiles[16] = 0
	aTiles[15] = 0
	aTiles[16] = 15
	nMoves = 0
	showBoard()
	dnAssert("not solved",isSolved(),0)
	dnAssert("tile text",aCells[16].Text,"15")
	dnAssert("neighbours of a corner",len(neighbours(1)),2)
	dnAssert("neighbours of the middle",len(neighbours(6)),4)
	aCells[16].PerformClick()
	dnAssert("tile did not move (it is not next to the empty cell... it is)",aTiles[15],15)
	dnAssert("solved after the move",isSolved(),1)
	dnAssert("counted the move",nMoves,1)
	dnAssert("message",left(oMessage.Text,6),"Solved")
	aCells[1].PerformClick()
	dnAssert("far tile does not move",nMoves,1)
	# shuffling keeps the puzzle solvable and the tiles complete
	shuffleBoard()
	nTotal = 0
	for nTile in aTiles
		nTotal += nTile
	next
	dnAssert("all tiles present",nTotal,120)
