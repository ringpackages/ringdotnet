# the checks of GameOfLife.ring: run with  ring GameOfLife.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	dnAssert("glider has 5 cells",population(),5)
	for nStep = 1 to 4
		nextGeneration()
	next
	dnAssert("still 5 cells after 4 generations",population(),5)
	dnAssert("the glider moved by (1,1)",isAlive(7,6) + isAlive(8,7) + isAlive(6,8) + isAlive(7,8) + isAlive(8,8),5)
	dnAssert("cell is drawn",oCanvas.pixel(8 * C_CELL + 5,8 * C_CELL + 5),"ff006400")
	# a blinker flips between horizontal and vertical
	clearAll()
	for nColumn = 10 to 12
		aCells[cellIndex(nColumn,10)] = 1
	next
	nextGeneration()
	dnAssert("blinker is vertical",isAlive(11,9) + isAlive(11,10) + isAlive(11,11),3)
	nextGeneration()
	dnAssert("blinker is horizontal again",isAlive(10,10) + isAlive(11,10) + isAlive(12,10),3)
	# a click toggles a cell
	clearAll()
	clickCell(3 * C_CELL + 2,4 * C_CELL + 2)
	dnAssert("click makes a cell alive",isAlive(3,4),1)
	clickCell(3 * C_CELL + 2,4 * C_CELL + 2)
	dnAssert("second click removes it",isAlive(3,4),0)
	oRun.PerformClick()
	dnAssert("button starts the timer",oRun.Text,"Stop")
	oRun.PerformClick()
