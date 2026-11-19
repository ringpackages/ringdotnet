# the checks of main.ring: run with  ring main.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	cWord = "RING"
	cGuessed = ""
	nWrong = 0
	showState()
	dnAssert("masked",oWord.Text,"_ _ _ _")
	letter("R")
	dnAssert("letter revealed",oWord.Text,"R _ _ _")
	letter("Z")
	dnAssert("wrong guess counted",nWrong,1)
	dnAssert("the button is disabled",aLetterButtons[26].Enabled,False)
	dnAssert("no body yet",oCanvas.pixel(130,90),"ffffffff")
	letter("Z")
	dnAssert("same letter twice is ignored",nWrong,1)
	letter("Q")
	dnAssert("the body is drawn at the second mistake",oCanvas.pixel(130,90),"ff000000")
	letter("I")
	letter("N")
	letter("G")
	dnAssert("won",oInfo.Text,"You won!")
	cWord = "RING"
	cGuessed = ""
	nWrong = 0
	for cLetter in ["A","B","C","D","E","F"]
		letter(cLetter)
	next
	dnAssert("lost after 6 wrong guesses",left(oInfo.Text,8),"You lost")
	dnAssert("the word is shown",oWord.Text,"RING")
