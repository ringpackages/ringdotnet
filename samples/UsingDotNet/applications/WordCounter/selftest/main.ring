# the checks of main.ring: run with  ring main.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oText.Text = "the cat and the hat" + windowsnl() + "The end"
	dnAssert("word count",len(wordsOf(oText.Text)),7)
	dnAssert("unique words",len(uniqueWords(wordsOf(oText.Text))),5)
	dnAssert("stats label",substr(oStats.Text,"Words: 7") > 0,True)
	dnAssert("two lines",substr(oStats.Text,"Lines: 2") > 0,True)
	aCounts = countWords(wordsOf(oText.Text))
	dnAssert("sorted counts: first the 'the'",aCounts[len(aCounts)][1],"the")
	dnAssert("the count is 3",aCounts[len(aCounts)][2],3)
	dnAssert("top list filled",oTop.Items.Count,5)
	oText.Text = ""
	dnAssert("empty text",substr(oStats.Text,"Words: 0") > 0,True)
	oText.Text = "naïve café 42 times"
	dnAssert("unicode letters and digits",len(wordsOf(oText.Text)),4)
