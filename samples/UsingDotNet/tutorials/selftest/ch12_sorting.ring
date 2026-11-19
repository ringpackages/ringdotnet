# the checks of ch12_sorting.ring: run with  ring ch12_sorting.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func isSorted
	for nI = 1 to len(aValues) - 1
		if aValues[nI] > aValues[nI + 1]
			return False
		ok
	next
	return True

func selfTest
	oTimer.Stop()
	dnAssert("the bars start shuffled",isSorted(),False)
	for nAlgorithm = 0 to 2
		shuffle()
		oAlgorithm.SelectedIndex = nAlgorithm
		startSorting()
		oTimer.Stop()
		while nStep < len(aSteps)
			showStep()
		end
		showStep()
		dnAssert("algorithm " + nAlgorithm + " sorts",isSorted(),True)
		dnAssert("algorithm " + nAlgorithm + " compared",nCompares > 0,True)
	next
	# the same start gives the same work: selection sort makes at most n-1 swaps
	shuffle()
	oAlgorithm.SelectedIndex = 1
	startSorting()
	oTimer.Stop()
	nSwapsPlanned = 0
	for aStep in aSteps
		if aStep[1] = "swap"
			nSwapsPlanned++
		ok
	next
	dnAssert("selection sort swaps at most n-1 times",nSwapsPlanned <= C_COUNT - 1,True)
