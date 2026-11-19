# the checks of main.ring: run with  ring main.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oCount.Value = 3
	newGame()
	dnAssert("three disks on the first peg",len(aPegs[1]),3)
	dnAssert("cannot move an empty peg",canMove(2,3),0)
	dnAssert("move a small disk",moveDisk(1,2),1)
	dnAssert("cannot put a big disk on a small one",canMove(1,2),0)
	# click-based play: pick from peg 1, drop on peg 3
	clicked(100)
	dnAssert("picked",nHeld,1)
	clicked(500)
	dnAssert("dropped",len(aPegs[3]),1)
	# the solver
	newGame()
	aPlan = []
	solve(nDisks,1,3,2)
	dnAssert("7 moves for 3 disks",len(aPlan),7)
	for aStep in aPlan
		moveDisk(aStep[1],aStep[2])
	next
	draw()
	dnAssert("solved by the plan",isSolved(),1)
	dnAssert("minimum number of moves",nMoves,7)
	dnAssert("message",left(oInfo.Text,6),"Solved")
	oCount.Value = 5
	newGame()
	aPlan = []
	solve(nDisks,1,3,2)
	dnAssert("31 moves for 5 disks",len(aPlan),31)
