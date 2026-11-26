# Chess end game: load the saved models and test them on the test positions (the 30 percent that no model has seen).
#   ring evaluate.ring
# (ring train.ring makes the models and the files data/train.csv and data/test.csv first.)
# For every saved model: the accuracy (the exact result) and the accuracy within one move. For the best model: the accuracy for each result, and how far the wrong answers are.
load "chesslib.ring"

func main

	if not fexists("models/index.txt")
		? "There are no models yet: run   ring train.ring   first."
		return
	ok
	chessSetup()
	oMl = chessContext(1)
	oTest = chessLoad(oMl,"data/test.csv")
	aActual = chessColumn(oTest,"System.String","GameResult")
	? "test positions: " + len(aActual)

	aIndex = str2list(read("models/index.txt"))
	? nl + padRight("model",62) + padRight("accuracy",10) + "within 1"
	aBest = []
	for cLine in aIndex
		if len(cLine) > 3
			aParts = str2list(substr(cLine,"|",nl))
			aAlgorithm = [aParts[1],aParts[2],aParts[3]]
			# the model is read from its file: the whole pipeline is in it (the features, the trainer and the answer as the text of the result)
			aLoaded = oMl.Model.callMethod("Load",[currentdir() + "/" + chessModelFile(aAlgorithm)])          # Load is a keyword of Ring
			aPredicted = chessColumn(aLoaded[1].Transform(oTest),"System.String","PredictedResult")
			aAccuracy = chessAccuracy(aActual,aPredicted)
			? padRight(aParts[2] + " [" + aParts[3] + "]",62) + padRight(percent(aAccuracy[1]),10) + percent(aAccuracy[2])
			if len(aBest) = 0
				aBest = [aAlgorithm,aPredicted]          # the first line of the index is the best model
			ok
		ok
	next

	# the best model result by result: how many positions have the result, and how many of them the model gets right
	? nl + "the best model, " + aBest[1][2] + " [" + aBest[1][3] + "], result by result:"
	? padRight("result",10) + padRight("positions",11) + padRight("right",8) + "right (%)"
	aPredicted = aBest[2]
	for cResult in ["draw","zero","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen"]
		nSupport = 0
		nRight = 0
		nTotal = len(aActual)
		for nPlace = 1 to nTotal
			if aActual[nPlace] = cResult
				nSupport++
				if aPredicted[nPlace] = cResult
					nRight++
				ok
			ok
		next
		if nSupport > 0
			? padRight(cResult,10) + padRight(nSupport,11) + padRight(nRight,8) + percent(nRight / nSupport)
		ok
	next

	# how far the answers are from the result, in moves (for the games that are wins and are answered as wins)
	aOff = [0,0,0,0,0]
	nWrongKind = 0
	nTotal = len(aActual)
	for nPlace = 1 to nTotal
		if (aActual[nPlace] = "draw") != (aPredicted[nPlace] = "draw")
			nWrongKind++
		but aActual[nPlace] != "draw"
			nOff = fabs(chessDepth(aActual[nPlace]) - chessDepth(aPredicted[nPlace]))
			if nOff > 3
				nOff = 4
			ok
			aOff[nOff + 1]++
		ok
	next
	? nl + "the answers of the best model for the wins:"
	? "  exactly right:        " + aOff[1]
	? "  one move off:         " + aOff[2]
	? "  two moves off:        " + aOff[3]
	? "  three moves off:      " + aOff[4]
	? "  four moves or more:   " + aOff[5]
	? "  a win taken for a draw, or a draw for a win: " + nWrongKind

func percent nValue

	return chessPercent(nValue)

func padRight cText, nWidth

	cText = "" + cText
	if len(cText) >= nWidth
		return cText
	ok
	return cText + copy(" ",nWidth - len(cText))
