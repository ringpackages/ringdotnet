# the checks of TicTacToe.ring: run with  ring TicTacToe.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	# X plays 1 and 2: the computer takes the center, then must block at 3
	move(1)
	dnAssert("X placed",aButtons[1].Text,"X")
	dnAssert("computer answered in the center",aButtons[5].Text,"O")
	move(2)
	dnAssert("computer blocks the top row",aButtons[3].Text,"O")
	move(7)
	dnAssert("computer blocks the left column",aBoard[4],2)
	dnAssert("game continues",lGameOver,0)
	newGame()
	dnAssert("board cleared",aButtons[1].Text,"")
	# the computer wins when the player ignores it
	move(1)
	move(9)
	move(8)
	dnAssert("game ended",lGameOver,1)
	dnAssert("score updated",nWinsO + nDraws + nWinsX >= 1,True)
