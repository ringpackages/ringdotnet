# the checks of Minesweeper.ring: run with  ring Minesweeper.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	# a known layout: mines in the top row, cells 1 to 9, except 5
	aMine = list(C_COLUMNS * C_ROWS)
	for nCell in [1,3,5,7,9]
		aMine[nCell] = 1
	next
	# C_MINES stays 10 so the win check below uses its own counts
	startPlay()
	dnAssert("neighbor count",mineCount(11),2)
	dnAssert("corner has 3 neighbors",len(neighbors(1)),3)
	dnAssert("middle has 8 neighbors",len(neighbors(41)),8)
	aButtons[11].PerformClick()
	cButton = "Left"
	cellClicked(11,"Left")
	dnAssert("number shown",aButtons[11].Text,"2")
	cellClicked(81,"Left")
	dnAssert("flood fill opened far cells",aRevealed[72] + aRevealed[73] + aRevealed[40],3)
	cellClicked(2,"Right")
	dnAssert("flag placed",aButtons[2].Text,"F")
	dnAssert("flag counter",nFlags,1)
	cellClicked(2,"Left")
	dnAssert("flagged cell is protected",aRevealed[2],0)
	cellClicked(2,"Right")
	dnAssert("flag removed",aButtons[2].Text,"")
	# the right mouse button on the real button
	cellClicked(1,"Left")
	dnAssert("mine ends the game",lPlaying,0)
	dnAssert("message",oInfo.Text,"Boom! Game over")
	dnAssert("mines shown",aButtons[3].Text,"*")
