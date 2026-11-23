# the checks of Game2048.ring: run with  ring Game2048.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	aResult = slideLine([2,2,4,0])
	dnAssert("slide merges",list2str(aResult[1]),list2str([4,4,0,0]))
	dnAssert("slide score",aResult[2],4)
	dnAssert("slide does not merge twice",list2str(slideLine([2,2,2,2])[1]),list2str([4,4,0,0]))
	dnAssert("slide gaps",list2str(slideLine([0,2,0,2])[1]),list2str([4,0,0,0]))
	aBoard = list(16)
	aBoard[1] = 2
	aBoard[4] = 2
	aBoard[5] = 4
	nScore = 0
	dnAssert("move left moved",moveBoard("Left"),1)
	dnAssert("left merged row 1",aBoard[1],4)
	aBoard = list(16)
	aBoard[1] = 2
	aBoard[2] = 2
	nScore = 0
	moveBoard("Right")
	dnAssert("right slides to the end",aBoard[4],4)
	aBoard = list(16)
	aBoard[1] = 8
	aBoard[5] = 8
	moveBoard("Down")
	dnAssert("down merges",aBoard[13],16)
	moveBoard("Up")
	dnAssert("up moves back",aBoard[1],16)
	dnAssert("score counts merges",nScore,20)
	dnAssert("no move possible when nothing changes",moveBoard("Up"),0)
	# keyboard handling goes through the KeyDown event handler
	newGame()
	nTiles = 0
	for nCell in aBoard
		if nCell > 0 nTiles++ ok
	next
	dnAssert("new game starts with two tiles",nTiles,2)
	keyPressed("Left")
	keyPressed("Up")
	dnAssert("game goes on",lGameOver,0)
	# real key presses, with the New game button focused (it used to take the arrow keys)
	oNewGame.Focus()
	aBoard = list(16)
	aBoard[1] = 2
	aBoard[2] = 2
	aBoard[16] = 4
	nScore = 0
	lGameOver = false
	if uiSendKeys(oForm,"{LEFT}")
		dnAssert("the left arrow key reaches the game",aBoard[1],4)
		aBoard = list(16)
		aBoard[1] = 8
		aBoard[5] = 8
		uiSendKeys(oForm,"{DOWN}")
		dnAssert("the down arrow key reaches the game",aBoard[13],16)
		aBoard = list(16)
		aBoard[13] = 16
		uiSendKeys(oForm,"{UP}")
		dnAssert("the up arrow key reaches the game",aBoard[1],16)
		uiSendKeys(oForm," ")
		dnAssert("Space does not press the New game button",nScore > 0,True)
	ok
	# a full board without equal neighbors is game over
	aBoard = [2,4,2,4, 4,2,4,2, 2,4,2,4, 4,2,4,2]
	dnAssert("no moves left",canMove(),0)
