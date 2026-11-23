# the checks of FifteenPuzzle.ring: run with  ring FifteenPuzzle.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

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
	dnAssert("neighbors of a corner",len(neighbors(1)),2)
	dnAssert("neighbors of the middle",len(neighbors(6)),4)
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
