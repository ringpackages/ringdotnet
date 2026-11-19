# the checks of ch12_tictactoe.ring: run with  ring ch12_tictactoe.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("an empty board has no winner",winnerOf(["","","","","","","","",""]),"")
	dnAssert("a row",winnerOf(["X","X","X","","O","O","","",""]),"X")
	dnAssert("a column",winnerOf(["O","X","","O","X","","O","",""]),"O")
	dnAssert("a diagonal",winnerOf(["X","O","","O","X","","","","X"]),"X")
	dnAssert("a full board without a winner",boardFull(["X","O","X","X","O","O","O","X","X"]),True)

	# a game: X takes the top row while O plays elsewhere
	play(1) play(4) play(2) play(5) play(3)
	dnAssert("X wins",oStatus.Text,"X wins!")
	play(9)                                          # the game is over: ignored
	dnAssert("no more moves after the end",aBoard[9],"")
	newGame()
	dnAssert("a new game",oStatus.Text,"X to play")
	play(1) play(2) play(3) play(5) play(4) play(6) play(8) play(7) play(9)
	dnAssert("a draw",oStatus.Text,"A draw")
