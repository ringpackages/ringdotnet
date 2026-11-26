# Chess end game: create the models and save them.
#   cd samples/UsingDotNet/applications/ChessEndgame
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
	if not direxists("models")
		system("mkdir models")
	ok

	? nl + padRight("algorithm",50) + padRight("features",12) + padRight("accuracy",10) + padRight("within 1",10) + "seconds"
	aResults = chessTrainAll(oMl,lQuick,"showResult")          # train, test, save; showResult() prints a line after each algorithm

	# the best first
	? nl + "the ranking on the test positions (accuracy: the exact result; within 1: wrong by one move at most):"
	nPlace = 1
	for aResult in aResults
		? "  " + nPlace + ". " + padRight(aResult[3][2] + " [" + aResult[3][3] + "]",62) + percent(aResult[1]) + "   within 1: " + percent(aResult[2])
		nPlace++
	next
	? nl + "the models are saved in the folder models; the best one is " + aResults[1][3][2] + " [" + aResults[1][3][3] + "]"
	? "next: ring evaluate.ring   (the saved models on the test positions)   and   ring predict.ring a1 b3 c2   (the result of a position)"

func percent nValue

	return chessPercent(nValue)

func padRight cText, nWidth

	if len(cText) >= nWidth
		return cText
	ok
	return cText + copy(" ",nWidth - len(cText))

# One line for an algorithm that was trained and tested
func showResult nAlgorithm, nAlgorithms, aAlgorithm, nExact, nNear, nSeconds

	? padRight(aAlgorithm[2],50) + padRight(aAlgorithm[3],12) + padRight(percent(nExact),10) + padRight(percent(nNear),10) + (floor(nSeconds * 10) / 10)
