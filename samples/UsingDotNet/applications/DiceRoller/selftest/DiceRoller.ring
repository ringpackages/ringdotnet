# the checks of DiceRoller.ring: run with  ring DiceRoller.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	aDice = [1,2,3,4,6]
	draw()
	dnAssert("total",oTotal.Text,"Total: 16")
	dnAssert("the 1 has a center pip",oCanvas.pixel(10 + 35,25 + 20),"ff000000")
	dnAssert("the 1 has no corner pip",oCanvas.pixel(10 + 15,25),"ffffffff")
	dnAssert("the 6 has a pip in the middle row",oCanvas.pixel(10 + 4 * 80 + 15,25 + 20),"ff000000")
	dnAssert("pip counts",len(pips(1)) + len(pips(2)) + len(pips(3)) + len(pips(4)) + len(pips(5)) + len(pips(6)),21)
	rollAll()
	dnAssert("5 rolls counted",nRolls,5)
	rollMany(1000)
	dnAssert("1005 rolls",nRolls,1005)
	nSum = 0
	for nCount in aCounts
		nSum += nCount
	next
	dnAssert("statistics add up",nSum,1005)
	dnAssert("each face came up",aCounts[1] > 80 and aCounts[6] > 80,True)
	lValid = true
	for nFace in aDice
		if nFace < 1 or nFace > 6
			lValid = false
		ok
	next
	dnAssert("dice are between 1 and 6",lValid,1)
