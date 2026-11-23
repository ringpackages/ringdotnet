# the checks of Snake.ring: run with  ring Snake.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oTimer.Stop()
	aSnake = [[5,5],[4,5],[3,5]]
	cDirection = "Right"
	cNextDirection = "Right"
	aFood = [7,5]
	nScore = 0
	tick()
	tick()
	dnAssert("moved right",aSnake[1][1],7)
	dnAssert("ate the food and grew",len(aSnake),4)
	dnAssert("score",nScore,10)
	keyPressed("Left")
	dnAssert("cannot reverse",cNextDirection,"Right")
	keyPressed("Down")
	tick()
	dnAssert("turned down",aSnake[1][2],6)
	dnAssert("food pixel is red",oCanvas.pixel(aFood[1] * C_CELL + 10,aFood[2] * C_CELL + 10),"ffff0000")
	dnAssert("head pixel is green",oCanvas.pixel(aSnake[1][1] * C_CELL + 10,aSnake[1][2] * C_CELL + 10),"ff32cd32")
	# hit the bottom wall
	aSnake = [[5,C_ROWS - 1],[5,C_ROWS - 2],[5,C_ROWS - 3]]
	cDirection = "Down"
	cNextDirection = "Down"
	tick()
	dnAssert("game over at the wall",lAlive,0)
	keyPressed("Space")
	dnAssert("space starts again",lAlive,1)
	oTimer.Stop()
	cDirection = "Right"
	cNextDirection = "Right"
	if uiSendKeys(oForm,"{DOWN}")
		dnAssert("the down arrow key reaches the game",cNextDirection,"Down")
		uiSendKeys(oForm,"{UP}")
		dnAssert("the up arrow key reaches the game",cNextDirection,"Up")
	ok
	# hit itself
	aSnake = [[5,5],[5,6],[6,6],[6,5],[6,4]]
	cDirection = "Up"
	cNextDirection = "Right"
	tick()
	dnAssert("game over on itself",lAlive,0)
