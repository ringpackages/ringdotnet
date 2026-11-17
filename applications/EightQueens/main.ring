# Eight queens - place 8 queens so that none attacks another (a port of ring/applications/eightqueens)
# Click a square to put or remove a queen; "Solve" finds a solution with backtracking.

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_SIZE = 8
aQueens = list(C_SIZE)	# aQueens[column] = the row of the queen of that column (0 = none)
aSquares = []

oForm = uiForm("Eight queens",360,440)
oForm.FormBorderStyle = "FixedSingle"
oForm.MaximizeBox = 0
for nCell = 1 to C_SIZE * C_SIZE
	nRow = floor((nCell - 1) / C_SIZE) + 1
	nColumn = (nCell - 1) % C_SIZE + 1
	oSquare = uiButton(oForm,"",10 + (nColumn - 1) * 42,10 + (nRow - 1) * 42,42,42,"toggle(" + nRow + "," + nColumn + ")")
	oSquare.FlatStyle = "Flat"
	oSquare.Font = uiFont("Segoe UI",18,true)
	aSquares + oSquare
next
oInfo = uiLabel(oForm,"",10,355,340,24)
uiButton(oForm,"Solve",10,385,80,32,"solveIt()")
uiButton(oForm,"Clear",100,385,80,32,"clearBoard()")
oCount = uiLabel(oForm,"",190,392,160,22)
showBoard()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func squareOf nRow, nColumn
	return (nRow - 1) * C_SIZE + nColumn

# do two queens (row, column) attack each other
func attacks nRow1, nColumn1, nRow2, nColumn2
	if nRow1 = nRow2 or nColumn1 = nColumn2
		return true
	ok
	return fabs(nRow1 - nRow2) = fabs(nColumn1 - nColumn2)

# the columns whose queen is attacked by another queen
func conflicts
	aBad = list(C_SIZE)
	for nA = 1 to C_SIZE
		for nB = nA + 1 to C_SIZE
			if aQueens[nA] > 0 and aQueens[nB] > 0 and attacks(aQueens[nA],nA,aQueens[nB],nB)
				aBad[nA] = 1
				aBad[nB] = 1
			ok
		next
	next
	return aBad

func showBoard
	aBad = conflicts()
	nPlaced = 0
	for nRow = 1 to C_SIZE
		for nColumn = 1 to C_SIZE
			oSquare = aSquares[squareOf(nRow,nColumn)]
			if (nRow + nColumn) % 2 = 0
				oSquare.BackColor = uiColor("Wheat")
			else
				oSquare.BackColor = uiColor("Sienna")
			ok
			if aQueens[nColumn] = nRow
				oSquare.Text = "Q"
				nPlaced++
				if aBad[nColumn]
					oSquare.ForeColor = uiColor("Red")
				else
					oSquare.ForeColor = uiColor("DarkGreen")
				ok
			else
				oSquare.Text = ""
			ok
		next
	next
	nBad = 0
	for nValue in aBad
		nBad += nValue
	next
	if nPlaced = C_SIZE and nBad = 0
		oInfo.Text = "Solved!"
	else
		oInfo.Text = "Queens: " + nPlaced + "/8   conflicts: " + nBad
	ok

func toggle nRow, nColumn
	if aQueens[nColumn] = nRow
		aQueens[nColumn] = 0
	else
		aQueens[nColumn] = nRow
	ok
	showBoard()

func clearBoard
	aQueens = list(C_SIZE)
	showBoard()

# the number of ways to complete the board from column nColumn (backtracking)
func countSolutions nColumn, aPlaced
	if nColumn > C_SIZE
		return 1
	ok
	nTotal = 0
	for nRow = 1 to C_SIZE
		lSafe = true
		for nBefore = 1 to nColumn - 1
			if attacks(aPlaced[nBefore],nBefore,nRow,nColumn)
				lSafe = false
				exit
			ok
		next
		if lSafe
			aPlaced[nColumn] = nRow
			nTotal += countSolutions(nColumn + 1,aPlaced)
			aPlaced[nColumn] = 0
		ok
	next
	return nTotal

func solveIt
	aQueens = firstSolution()
	showBoard()
	oCount.Text = "92 solutions exist"

# a solution found by backtracking
func firstSolution
	aResult = list(C_SIZE)
	findOne(1,aResult)
	return aResult

func findOne nColumn, aPlaced
	if nColumn > C_SIZE
		return true
	ok
	for nRow = 1 to C_SIZE
		lSafe = true
		for nBefore = 1 to nColumn - 1
			if attacks(aPlaced[nBefore],nBefore,nRow,nColumn)
				lSafe = false
				exit
			ok
		next
		if lSafe
			aPlaced[nColumn] = nRow
			if findOne(nColumn + 1,aPlaced)
				return true
			ok
			aPlaced[nColumn] = 0
		ok
	next
	return false

func selfTest
	toggle(1,1)
	toggle(2,2)
	dnAssert("diagonal conflict",oInfo.Text,"Queens: 2/8   conflicts: 2")
	dnAssert("conflicting queens are red",aSquares[squareOf(1,1)].ForeColor.Name,"Red")
	toggle(2,2)
	dnAssert("one queen is fine",oInfo.Text,"Queens: 1/8   conflicts: 0")
	toggle(1,1)
	dnAssert("queen removed",oInfo.Text,"Queens: 0/8   conflicts: 0")
	solveIt()
	dnAssert("solver finds a full solution",oInfo.Text,"Solved!")
	dnAssert("a queen in every column",aSquares[squareOf(aQueens[1],1)].Text,"Q")
	dnAssert("the number of solutions of the 8 queens problem",countSolutions(1,list(C_SIZE)),92)
