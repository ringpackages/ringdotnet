# the checks of ch12_maze.ring: run with  ring ch12_maze.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

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
	dnAssert("every step of the path moves to a neighbor cell",lConnected,True)
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
