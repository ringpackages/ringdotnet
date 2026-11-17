# Sudoku - type the digits, "Check" finds mistakes, "Solve" uses backtracking (a port of ring/applications/sudoku)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

aPuzzle = "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
lLoading = false	# true while the program fills the boxes (the TextChanged events are ignored)
aGrid = list(81)	# the digits, 0 = empty
aFixed = list(81)	# 1 for the digits that belong to the puzzle
aBoxes = []

oForm = uiForm("Sudoku",420,500)
oForm.FormBorderStyle = "FixedSingle"
oForm.MaximizeBox = 0
for nCell = 1 to 81
	nRow = floor((nCell - 1) / 9)
	nColumn = (nCell - 1) % 9
	nX = 12 + nColumn * 40 + floor(nColumn / 3) * 4
	nY = 12 + nRow * 40 + floor(nRow / 3) * 4
	oBox = uiTextBox(oForm,nX,nY,38,38)
	oBox.MaxLength = 1
	oBox.TextAlign = "Center"
	oBox.Font = uiFont("Segoe UI",16,true)
	oBox.setTextChangedEvent("typed(" + nCell + ")")
	aBoxes + oBox
next
oInfo = uiLabel(oForm,"",12,400,396,24)
uiButton(oForm,"New",12,430,70,32,"loadPuzzle(aPuzzle)")
uiButton(oForm,"Check",92,430,70,32,"checkBoard()")
uiButton(oForm,"Solve",172,430,70,32,"solveBoard()")
uiButton(oForm,"Clear",252,430,70,32,"loadPuzzle(copy('0',81))")
loadPuzzle(aPuzzle)

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func loadPuzzle cDigits
	lLoading = true
	for nCell = 1 to 81
		aGrid[nCell] = number(cDigits[nCell])
		aFixed[nCell] = (aGrid[nCell] > 0)
		if aGrid[nCell] > 0
			aBoxes[nCell].Text = "" + aGrid[nCell]
		else
			aBoxes[nCell].Text = ""
		ok
		aBoxes[nCell].ReadOnly = aFixed[nCell]
		if aFixed[nCell]
			aBoxes[nCell].BackColor = uiColor("Gainsboro")
		else
			aBoxes[nCell].BackColor = uiColor("White")
		ok
	next
	lLoading = false
	oInfo.Text = "Fill the empty squares"

func typed nCell
	if lLoading or aFixed[nCell]
		return
	ok
	cText = aBoxes[nCell].Text
	if cText = "" or (len(cText) = 1 and isdigit(cText) and cText != "0")
		if cText = ""
			aGrid[nCell] = 0
		else
			aGrid[nCell] = number(cText)
		ok
		aBoxes[nCell].ForeColor = uiColor("Black")
	else
		lLoading = true
		aBoxes[nCell].Text = ""
		lLoading = false
		aGrid[nCell] = 0
	ok

# can nDigit go in the cell without breaking a rule
func canPlace aCells, nCell, nDigit
	nRow = floor((nCell - 1) / 9)
	nColumn = (nCell - 1) % 9
	for nOther = 0 to 8
		if aCells[nRow * 9 + nOther + 1] = nDigit and nRow * 9 + nOther + 1 != nCell
			return false
		ok
		if aCells[nOther * 9 + nColumn + 1] = nDigit and nOther * 9 + nColumn + 1 != nCell
			return false
		ok
	next
	nBoxRow = floor(nRow / 3) * 3
	nBoxColumn = floor(nColumn / 3) * 3
	for nR = 0 to 2
		for nC = 0 to 2
			nIndex = (nBoxRow + nR) * 9 + nBoxColumn + nC + 1
			if aCells[nIndex] = nDigit and nIndex != nCell
				return false
			ok
		next
	next
	return true

# backtracking solver; fills aCells and returns true when the puzzle has a solution
func solve aCells
	nEmpty = 0
	for nCell = 1 to 81
		if aCells[nCell] = 0
			nEmpty = nCell
			exit
		ok
	next
	if nEmpty = 0
		return true
	ok
	for nDigit = 1 to 9
		if canPlace(aCells,nEmpty,nDigit)
			aCells[nEmpty] = nDigit
			if solve(aCells)
				return true
			ok
			aCells[nEmpty] = 0
		ok
	next
	return false

func solveBoard
	aWork = aGrid
	if solve(aWork)
		lLoading = true
		for nCell = 1 to 81
			aGrid[nCell] = aWork[nCell]
			aBoxes[nCell].Text = "" + aWork[nCell]
		next
		lLoading = false
		oInfo.Text = "Solved"
	else
		oInfo.Text = "This puzzle has no solution"
	ok

# mark the digits that break a rule
func checkBoard
	nWrong = 0
	for nCell = 1 to 81
		if aGrid[nCell] > 0 and not canPlace(aGrid,nCell,aGrid[nCell])
			aBoxes[nCell].ForeColor = uiColor("Red")
			nWrong++
		else
			aBoxes[nCell].ForeColor = uiColor("Black")
		ok
	next
	nEmpty = 0
	for nValue in aGrid
		if nValue = 0
			nEmpty++
		ok
	next
	if nWrong > 0
		oInfo.Text = "" + nWrong + " digits break the rules"
	but nEmpty > 0
		oInfo.Text = "So far so good, " + nEmpty + " squares left"
	else
		oInfo.Text = "Complete and correct!"
	ok

func selfTest
	dnAssert("puzzle loaded",aGrid[1],5)
	dnAssert("empty square",aBoxes[3].Text,"")
	dnAssert("given digits are read only",aBoxes[1].ReadOnly,1)
	aBoxes[3].Text = "4"
	dnAssert("typed digit",aGrid[3],4)
	checkBoard()
	dnAssert("correct digit",oInfo.Text,"So far so good, 50 squares left")
	aBoxes[3].Text = "5"
	checkBoard()
	dnAssert("a repeated digit is marked",aBoxes[3].ForeColor.Name,"Red")
	aBoxes[3].Text = "x"
	dnAssert("letters are rejected",aBoxes[3].Text,"")
	loadPuzzle(aPuzzle)
	solveBoard()
	dnAssert("solved",oInfo.Text,"Solved")
	dnAssert("known solution, first row",aBoxes[3].Text,"4")
	dnAssert("known solution, last square",aBoxes[81].Text,"9")
	checkBoard()
	dnAssert("the solution is valid",oInfo.Text,"Complete and correct!")
	aImpossible = aPuzzle
	aImpossible[3] = "5"
	loadPuzzle(aImpossible)
	solveBoard()
	dnAssert("impossible puzzle",oInfo.Text,"This puzzle has no solution")
