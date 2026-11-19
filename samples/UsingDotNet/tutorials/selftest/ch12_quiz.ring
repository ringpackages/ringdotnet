# the checks of ch12_quiz.ring: run with  ring ch12_quiz.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

# the test plays: it chooses the answers like a user and clicks the button
func play nAnswer
	if nAnswer > 0
		aAnswers[nAnswer].Checked = True
	ok
	oNext.PerformClick()

func selfTest
	cleanUp()
	dnAssert("the first question",oQuestion.Text,"Which language is used with this package?")
	dnAssert("the progress",oProgress.Text,"Question 1 of 4")

	# nothing chosen: the program asks for an answer and stays
	play(0)
	dnAssert("choose first",oFeedback.Text,"Choose an answer first")

	# right answer
	play(1)
	dnAssert("right",oFeedback.Text,"Right!")
	dnAssert("the button says Next",oNext.Text,"Next")
	play(0)                                            # next question

	# wrong answer: the feedback says which is right
	dnAssert("question 2",oProgress.Text,"Question 2 of 4")
	play(3)
	dnAssert("wrong",oFeedback.Text,"Not quite: the answer is A text of bytes")
	play(0)

	# the other two right
	play(2)
	play(0)
	play(1)
	dnAssert("the last button",oNext.Text,"Result")
	play(0)

	dnAssert("the score",oQuestion.Text,"Your score: 3 of 4")
	dnAssert("the best scores",oFeedback.Text,"Best scores: 3")
