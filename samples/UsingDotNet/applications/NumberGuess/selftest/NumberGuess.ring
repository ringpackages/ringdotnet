# the checks of NumberGuess.ring: run with  ring NumberGuess.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	nSecret = 37
	nAttempts = 0
	oGuess.Value = 50
	guess()
	dnAssert("high hint",oHint.Text,"Try a number that is higher")
	oGuess.Value = 20
	guess()
	dnAssert("low hint",oHint.Text,"Try a number that is lower")
	oGuess.Value = 37
	guess()
	dnAssert("win message",left(oHint.Text,4),"Yes!")
	dnAssert("attempts",nAttempts,3)
	dnAssert("best score",nBest,3)
	dnAssert("history has 3 lines",oHistory.Items.Count,3)
	newGame()
	dnAssert("new game resets",nAttempts,0)
	dnAssert("secret in range",nSecret >= 1 and nSecret <= 100,True)
