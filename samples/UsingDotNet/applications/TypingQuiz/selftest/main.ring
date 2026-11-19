# the checks of main.ring: run with  ring main.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	showTarget("hello ring")
	dnAssert("a correct start has no mistakes",mistakes("hello"),0)
	dnAssert("one mistake",mistakes("hallo ring"),1)
	dnAssert("extra characters count",mistakes("hello ring!!"),2)
	dnAssert("speed",wordsPerMinute(50,60000),10)
	oInput.Text = "hel"
	dnAssert("good so far",oResult.Text,"Good so far...")
	dnAssert("the watch started",oWatch.IsRunning,1)
	oInput.Text = "hex"
	dnAssert("mistake message",oResult.Text,"1 characters are different")
	oInput.Text = "hello ring"
	dnAssert("finished",left(oResult.Text,5),"Done!")
	dnAssert("the watch stopped",oWatch.IsRunning,0)
	dnAssert("best recorded",left(oBest.Text,5),"Best:")
	newSentence()
	dnAssert("new sentence is one of the list",find(aSentences,cTarget) > 0,True)
