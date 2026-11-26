# Chess end game: create the models and save them.
#   cd samples/UsingDotNet/machinelearning/ChessEndgame
#   ring train.ring            all the algorithms (a few minutes); ring train.ring --quick tries three of them on a seventh of the data
#
# The data is data/chess.csv: a white king and a white rook against a black king, and the result of the game ("draw", or the moves that white needs to win). The positions are
# split in two: 70 percent to train the models and 30 percent to test them (data/train.csv and data/test.csv). Every algorithm learns from the training positions only,
# and its accuracy is measured on the test positions that it has not seen. Each model is saved in the folder models, and models/index.txt lists them with their accuracy,
# the best first, for evaluate.ring and predict.ring.
load "chesslib.ring"

func main

	lQuick = find(sysargv,"--quick") > 0
	chessSetup()
	oMl = chessContext(1)

	# 70 percent for training, 30 percent for testing
	aCounts = chessSplit(lQuick)
	? "positions to train the models: " + aCounts[1] + " (70%)"
	? "positions to test them:        " + aCounts[2] + " (30%)"
	oTrain = chessLoad(oMl,"data/train.csv")
	oTest = chessLoad(oMl,"data/test.csv")
	aActual = chessColumn(oTest,"System.String","GameResult")
	if not direxists("models")
		system("mkdir models")
	ok

	aResults = []
	? nl + padRight("algorithm",44) + padRight("features",12) + padRight("accuracy",10) + padRight("within 1",10) + "seconds"
	aAlgorithms = chessAlgorithms(lQuick)
	for aAlgorithm in aAlgorithms
		nStart = clock()
		oModel = chessPipeline(oMl,aAlgorithm).callMethod("Fit",[oTrain])
		nSeconds = (clock() - nStart) / clockspersecond()
		# the test: the model answers for the test positions, and the answers are compared with the real results
		aPredicted = chessColumn(oModel.Transform(oTest),"System.String","PredictedResult")
		aAccuracy = chessAccuracy(aActual,aPredicted)
		? padRight(aAlgorithm[2],44) + padRight(aAlgorithm[3],12) + padRight(percent(aAccuracy[1]),10) + padRight(percent(aAccuracy[2]),10) + (floor(nSeconds * 10) / 10)
		# the model is saved with the schema of the data that trained it
		oMl.Model.callMethod("Save",[oModel,oTrain.getProp("Schema"),currentdir() + "/" + chessModelFile(aAlgorithm)])
		aResults + [aAccuracy[1],aAccuracy[2],aAlgorithm,nSeconds]
	next

	# the best first
	aResults = sortByAccuracy(aResults)
	cIndex = ""
	? nl + "the ranking on the test positions (accuracy: the exact result; within 1: wrong by one move at most):"
	nPlace = 1
	for aResult in aResults
		? "  " + nPlace + ". " + padRight(aResult[3][2] + " [" + aResult[3][3] + "]",56) + percent(aResult[1]) + "   within 1: " + percent(aResult[2])
		cIndex += aResult[3][1] + "|" + aResult[3][2] + "|" + aResult[3][3] + "|" + floor(aResult[1] * 100000 + 0.5) + "|" + floor(aResult[2] * 100000 + 0.5) + nl          # the accuracies in hundred thousandths: a number written as text keeps two decimals
		nPlace++
	next
	write("models/index.txt",cIndex)
	? nl + "the models are saved in the folder models; the best one is " + aResults[1][3][2] + " [" + aResults[1][3][3] + "]"
	? "next: ring evaluate.ring   (the saved models on the test positions)   and   ring predict.ring a1 b3 c2   (the result of a position)"

func percent nValue

	return "" + (floor(nValue * 1000 + 0.5) / 10) + "%"

func padRight cText, nWidth

	if len(cText) >= nWidth
		return cText
	ok
	return cText + copy(" ",nWidth - len(cText))

# The results with the highest accuracy first (a result is [accuracy, accuracy within one move, the algorithm, the seconds])
func sortByAccuracy aResults

	aSorted = []
	nCount = len(aResults)
	for nTurn = 1 to nCount
		nBest = 1
		nItems = len(aResults)
		for nItem = 2 to nItems
			if aResults[nItem][1] > aResults[nBest][1]
				nBest = nItem
			ok
		next
		aSorted + aResults[nBest]
		del(aResults,nBest)
	next
	return aSorted
