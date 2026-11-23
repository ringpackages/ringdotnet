# the checks of Tetris.ring: run with  ring Tetris.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oTimer.Stop()
	# a flat I piece falls to the bottom
	aBoard = list(C_COLUMNS * C_ROWS)
	nPiece = 1
	aCurrent = aPieces[1]
	nPieceX = 4
	nPieceY = 0
	keyPressed("Left")
	dnAssert("moved left",nPieceX,3)
	keyPressed("Right")
	keyPressed("Right")
	dnAssert("moved right",nPieceX,5)
	keyPressed("Up")
	dnAssert("rotated to vertical",aCurrent[2][1],0)
	keyPressed("Space")
	dnAssert("locked at the bottom",aBoard[cellOf(5,C_ROWS - 1)],1)
	# fill the bottom row except one cell and drop a vertical I there to clear rows
	aBoard = list(C_COLUMNS * C_ROWS)
	for nColumn = 0 to C_COLUMNS - 2
		aBoard[cellOf(nColumn,C_ROWS - 1)] = 2
	next
	nScore = 0
	nLines = 0
	nPiece = 1
	aCurrent = rotated(aPieces[1])
	nPieceX = 9
	nPieceY = 1
	keyPressed("Space")
	dnAssert("a row was cleared",nLines,1)
	dnAssert("score for one row",nScore,100)
	dnAssert("the cleared row is replaced",aBoard[cellOf(0,C_ROWS - 1)],0)
	# real key presses with the New game button focused (it used to take the arrow keys and Space)
	oNewGame.Focus()
	aBoard = list(C_COLUMNS * C_ROWS)
	lGameOver = false
	nPiece = 3
	aCurrent = aPieces[3]
	nPieceX = 4
	nPieceY = 2
	if uiSendKeys(oForm,"{LEFT}")
		dnAssert("the left arrow key moves the piece",nPieceX,3)
		uiSendKeys(oForm,"{RIGHT}{RIGHT}")
		dnAssert("the right arrow key moves the piece",nPieceX,5)
		uiSendKeys(oForm,"{UP}")
		dnAssert("the up arrow key rotates the piece",aCurrent[2][1],0)
		uiSendKeys(oForm,"{DOWN}")
		dnAssert("the down arrow key drops one row",nPieceY,3)
		nScoreBefore = nScore
		uiSendKeys(oForm," ")
		dnAssert("Space drops the piece to the bottom",aBoard[cellOf(5,C_ROWS - 1)] > 0 or aBoard[cellOf(5,C_ROWS - 2)] > 0,True)
	ok
	# the walls stop the piece
	nPieceX = 0
	aCurrent = aPieces[2]
	keyPressed("Left")
	dnAssert("wall on the left",nPieceX,0)
	# the board fills up
	aBoard = list(C_COLUMNS * C_ROWS)
	for nColumn = 0 to C_COLUMNS - 1
		aBoard[cellOf(nColumn,0)] = 3
		aBoard[cellOf(nColumn,1)] = 3
	next
	newPiece()
	dnAssert("game over when the new piece does not fit",lGameOver,1)
	newGame()
	dnAssert("new game",lGameOver,0)
	oTimer.Stop()
