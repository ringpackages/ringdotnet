# the checks of main.ring: run with  ring main.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("puzzle loaded",aGrid[1],5)
	dnAssert("empty square",aBoxes[3].Text,"")
	dnAssert("given digits are read only",aBoxes[1].ReadOnly,True)
	aBoxes[3].Text = "4"
	dnAssert("typed digit",aGrid[3],4)
	checkBoard()
	dnAssert("correct digit",oInfo.Text,"So far so good, 50 squares left")
	aBoxes[3].Text = "5"
	checkBoard()
	dnAssert("a repeated digit is marked",aBoxes[3].ForeColor.Name,"Red")
	aBoxes[3].Text = "x"
	dnAssert("letters are rejected",aBoxes[3].Text,"")
	loadPuzzle(cPuzzle)
	solveBoard()
	dnAssert("solved",oInfo.Text,"Solved")
	dnAssert("known solution, first row",aBoxes[3].Text,"4")
	dnAssert("known solution, last square",aBoxes[81].Text,"9")
	checkBoard()
	dnAssert("the solution is valid",oInfo.Text,"Complete and correct!")
	aImpossible = cPuzzle
	aImpossible[3] = "5"
	loadPuzzle(aImpossible)
	solveBoard()
	dnAssert("impossible puzzle",oInfo.Text,"This puzzle has no solution")
