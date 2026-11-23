# the checks of MemoryGame.ring: run with  ring MemoryGame.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func waitMs nMilliseconds

	oClock = new Stopwatch()
	oClock.Start()
	while oClock.ElapsedMilliseconds < nMilliseconds
		new Application().DoEvents()
		new Thread().Sleep(5)
	end

func selfTest

	# a known layout: pairs next to each other
	aSymbols = ["A","A","B","B","C","C","D","D","E","E","F","F","G","G","H","H"]
	aCardButtons[1].PerformClick()
	dnAssert("card shows its symbol",aCardButtons[1].Text,"A")
	aCardButtons[2].PerformClick()
	dnAssert("a pair is kept",nPairs,1)
	dnAssert("matched color",aCardButtons[1].BackColor.Name,"LightGreen")
	aCardButtons[3].PerformClick()
	aCardButtons[5].PerformClick()
	dnAssert("a wrong pair is turned back after a moment",lBusy,1)
	dnAssert("both cards are still shown",aCardButtons[5].Text,"C")
	waitMs(1100)
	dnAssert("cards hidden again",aCardButtons[5].Text,"?")
	dnAssert("attempts counted",nAttempts,2)
	aCardButtons[3].PerformClick()
	aCardButtons[4].PerformClick()
	dnAssert("second pair",nPairs,2)
	newGame()
	dnAssert("new game hides everything",aCardButtons[1].Text,"?")
	dnAssert("16 symbols",len(aSymbols),16)
