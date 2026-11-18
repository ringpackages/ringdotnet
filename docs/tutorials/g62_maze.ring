# Tutorial 62: a maze - make it with a stack (depth-first), solve it with a queue (breadth-first), draw it on a canvas
load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_COLUMNS = 21
C_ROWS = 13
C_CELL = 26

oForm = ""
oPicture = ""
oCanvas = ""
oInfo = ""
aOpen = []                # aOpen[row][column] = a text of the open sides: "N", "E", "S", "W" in any combination
aPath = []                # the solution: a list of [row, column]
nSeed = 2024

func main
	oForm = uiForm("Maze",C_COLUMNS * C_CELL + 30,C_ROWS * C_CELL + 100)
	oPicture = uiPictureBox(oForm,5,5,C_COLUMNS * C_CELL,C_ROWS * C_CELL)
	oCanvas = new UiCanvas(oPicture)
	uiButton(oForm,"New maze",10,C_ROWS * C_CELL + 15,100,28,"newMaze()")
	uiButton(oForm,"Solve",120,C_ROWS * C_CELL + 15,100,28,"solve()")
	oInfo = uiLabel(oForm,"",10,C_ROWS * C_CELL + 52,500,22)
	newMaze()
	uiTest(oForm,"selfTest()")
	uiRun(oForm)
	uiEnd()

func nextRandom nLimit
	nSeed = (nSeed * 1103515245 + 12345) % 2147483648
	return (floor(nSeed / 65536) % nLimit) + 1

# ---------------------------------------------------------------- making the maze (depth-first with a stack)

# Start with all walls. Walk to a random neighbour that has not been visited, opening the wall between the two cells; when
# there is no such neighbour go back (pop the stack). Every cell is visited once, so there is exactly one path between any two cells.
func newMaze
	aOpen = []
	aSeen = []
	for nRow = 1 to C_ROWS
		aOpen + list(C_COLUMNS)
		aSeen + list(C_COLUMNS)
		for nColumn = 1 to C_COLUMNS
			aOpen[nRow][nColumn] = ""
			aSeen[nRow][nColumn] = False
		next
	next
	aStack = [[1,1]]
	aSeen[1][1] = True
	while len(aStack) > 0
		aCell = aStack[len(aStack)]
		aFree = freeNeighbours(aCell,aSeen)
		if len(aFree) = 0
			del(aStack,len(aStack))
		else
			aNext = aFree[nextRandom(len(aFree))]
			openBetween(aCell,aNext)
			aSeen[aNext[1]][aNext[2]] = True
			aStack + [aNext[1],aNext[2]]
		ok
	end
	aPath = []
	oInfo.Text = "A new maze: " + C_COLUMNS + " x " + C_ROWS + " cells"
	draw()

# the four neighbours [row, column] that exist and were not visited
func freeNeighbours aCell, aSeen
	aList = []
	for aMove in [[-1,0],[0,1],[1,0],[0,-1]]
		nRow = aCell[1] + aMove[1]
		nColumn = aCell[2] + aMove[2]
		if nRow >= 1 and nRow <= C_ROWS and nColumn >= 1 and nColumn <= C_COLUMNS
			if not aSeen[nRow][nColumn]
				aList + [nRow,nColumn]
			ok
		ok
	next
	return aList

func openBetween aFrom, aTo
	if aTo[1] < aFrom[1]
		aOpen[aFrom[1]][aFrom[2]] += "N"
		aOpen[aTo[1]][aTo[2]] += "S"
	but aTo[1] > aFrom[1]
		aOpen[aFrom[1]][aFrom[2]] += "S"
		aOpen[aTo[1]][aTo[2]] += "N"
	but aTo[2] > aFrom[2]
		aOpen[aFrom[1]][aFrom[2]] += "E"
		aOpen[aTo[1]][aTo[2]] += "W"
	else
		aOpen[aFrom[1]][aFrom[2]] += "W"
		aOpen[aTo[1]][aTo[2]] += "E"
	ok

# ---------------------------------------------------------------- solving (breadth-first with a queue)

# Visit the cells in rings around the start: first the cells 1 step away, then 2 steps... The first time the exit is reached, the way
# there is the SHORTEST path. Each cell remembers the cell it was reached from, and the path is followed back from the exit.
func solve
	aFrom = []
	for nRow = 1 to C_ROWS
		aFrom + list(C_COLUMNS)
		for nColumn = 1 to C_COLUMNS
			aFrom[nRow][nColumn] = 0
		next
	next
	aQueue = [[1,1]]
	nHead = 1
	aFrom[1][1] = [1,1]
	while nHead <= len(aQueue)
		aCell = aQueue[nHead]
		nHead++
		if aCell[1] = C_ROWS and aCell[2] = C_COLUMNS
			exit
		ok
		for aMove in [["N",-1,0],["E",0,1],["S",1,0],["W",0,-1]]
			if substr(aOpen[aCell[1]][aCell[2]],aMove[1]) > 0
				nRow = aCell[1] + aMove[2]
				nColumn = aCell[2] + aMove[3]
				if isnumber(aFrom[nRow][nColumn])
					aFrom[nRow][nColumn] = aCell
					aQueue + [nRow,nColumn]
				ok
			ok
		next
	end
	aPath = []
	aCell = [C_ROWS,C_COLUMNS]
	while not (aCell[1] = 1 and aCell[2] = 1)
		aPath + [aCell[1],aCell[2]]
		aCell = aFrom[aCell[1]][aCell[2]]
	end
	aPath + [1,1]
	oInfo.Text = "The shortest way has " + len(aPath) + " cells"
	draw()

# ---------------------------------------------------------------- drawing

func draw
	oCanvas.clear("White")
	for aCell in aPath
		oCanvas.fillRect((aCell[2] - 1) * C_CELL + 4,(aCell[1] - 1) * C_CELL + 4,C_CELL - 8,C_CELL - 8,"Orange")
	next
	oCanvas.fillRect(4,4,C_CELL - 8,C_CELL - 8,"SeaGreen")                                              # start
	oCanvas.fillRect((C_COLUMNS - 1) * C_CELL + 4,(C_ROWS - 1) * C_CELL + 4,C_CELL - 8,C_CELL - 8,"Crimson")   # exit
	for nRow = 1 to C_ROWS
		for nColumn = 1 to C_COLUMNS
			nX = (nColumn - 1) * C_CELL
			nY = (nRow - 1) * C_CELL
			cOpen = aOpen[nRow][nColumn]
			if substr(cOpen,"N") = 0
				oCanvas.line(nX,nY,nX + C_CELL,nY,"Black",2)
			ok
			if substr(cOpen,"W") = 0
				oCanvas.line(nX,nY,nX,nY + C_CELL,"Black",2)
			ok
			if nRow = C_ROWS and substr(cOpen,"S") = 0
				oCanvas.line(nX,nY + C_CELL,nX + C_CELL,nY + C_CELL,"Black",2)
			ok
			if nColumn = C_COLUMNS and substr(cOpen,"E") = 0
				oCanvas.line(nX + C_CELL,nY,nX + C_CELL,nY + C_CELL,"Black",2)
			ok
		next
	next
	oCanvas.show()

func selfTest
	# a perfect maze: C_COLUMNS * C_ROWS cells joined by exactly (cells - 1) openings
	nOpenings = 0
	for nRow = 1 to C_ROWS
		for nColumn = 1 to C_COLUMNS
			nOpenings += len(aOpen[nRow][nColumn])
		next
	next
	dnAssert("a perfect maze has cells - 1 openings",nOpenings / 2,C_COLUMNS * C_ROWS - 1)
	solve()
	dnAssert("the path starts at the exit",aPath[1][1] = C_ROWS and aPath[1][2] = C_COLUMNS,True)
	dnAssert("the path ends at the start",aPath[len(aPath)][1] = 1 and aPath[len(aPath)][2] = 1,True)
	lConnected = True
	for nI = 1 to len(aPath) - 1
		if fabs(aPath[nI][1] - aPath[nI + 1][1]) + fabs(aPath[nI][2] - aPath[nI + 1][2]) != 1
			lConnected = False
		ok
	next
	dnAssert("every step of the path moves to a neighbour cell",lConnected,True)
	lThroughOpenings = True
	for nI = 1 to len(aPath) - 1
		aThis = aPath[nI]
		aThat = aPath[nI + 1]
		cSide = "N"
		if aThat[1] > aThis[1]
			cSide = "S"
		but aThat[2] > aThis[2]
			cSide = "E"
		but aThat[2] < aThis[2]
			cSide = "W"
		ok
		if substr(aOpen[aThis[1]][aThis[2]],cSide) = 0
			lThroughOpenings = False
		ok
	next
	dnAssert("the path never crosses a wall",lThroughOpenings,True)
	newMaze()
	dnAssert("a new maze has no path yet",len(aPath),0)
