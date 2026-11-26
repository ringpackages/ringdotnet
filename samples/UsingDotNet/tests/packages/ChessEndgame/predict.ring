# Chess end game: use a saved model to predict the result of a game.
#   ring predict.ring                       a few positions of the test file, with the real result and the answer
#   ring predict.ring a1 b3 c2              one position: the white king on a1, the white rook on b3, the black king on c2
#   ring predict.ring a1 b3 c2  e4 e1 h8    more positions: three squares for each (white king, white rook, black king)
#   ring predict.ring --model=tree_engineered a1 b3 c2     another saved model than the best one (the name of its file in the folder models, without .zip)
# (ring train.ring makes the models first.) It is white's turn in the positions. The result is a draw, or the number of moves that white needs to win with the best play.
load "chesslib.ring"

func main

	if not fexists("models/index.txt")
		? "There are no models yet: run   ring train.ring   first."
		return
	ok
	# the arguments: the squares, and the model
	aSquares = []
	cModel = ""
	for cArg in sysargv
		if left(cArg,8) = "--model="
			cModel = substr(cArg,9)
		but len(cArg) = 2 and isdigit(right(cArg,1)) and find(["a","b","c","d","e","f","g","h"],lower(left(cArg,1))) > 0
			aSquares + cArg
		ok
	next
	if cModel = ""
		# the first line of models/index.txt is the best model
		aParts = str2list(substr(str2list(read("models/index.txt"))[1],"|",nl))
		cModel = aParts[1] + "_" + aParts[3]
		? "the model: " + aParts[2] + " [" + aParts[3] + "], the best of those that train.ring made"
	else
		? "the model: " + cModel
	ok
	chessSetup()
	oMl = chessContext(1)
	aLoaded = oMl.Model.callMethod("Load",[currentdir() + "/models/" + cModel + ".zip"])          # Load is a keyword of Ring

	if len(aSquares) = 0
		# the positions of the test file, with their real results
		aLines = str2list(read("data/test.csv"))
		cText = chessHeader() + nl
		aReal = []
		for nLine = 2 to 9
			cText += aLines[nLine * 40] + nl
			aParts = str2list(substr(aLines[nLine * 40],",",nl))
			aReal + aParts[len(aParts)]
		next
		write("data/positions.csv",cText)
		aPredicted = chessColumn(aLoaded[1].Transform(chessLoad(oMl,"data/positions.csv")),"System.String","PredictedResult")
		? nl + padRight("position (white king, rook, black king)",42) + padRight("real result",24) + "the model says"
		nPositions = len(aReal)
		for nPosition = 1 to nPositions
			aParts = str2list(substr(str2list(cText)[nPosition + 1],",",nl))
			cPosition = chessName(aParts[1],aParts[2]) + " " + chessName(aParts[3],aParts[4]) + " " + chessName(aParts[5],aParts[6])
			cMark = ""
			if aPredicted[nPosition] != aReal[nPosition]
				cMark = "   (wrong)"
			ok
			? padRight(cPosition,42) + padRight(chessSay(aReal[nPosition]),24) + chessSay(aPredicted[nPosition]) + cMark
		next
		? nl + "give your own positions: ring predict.ring a1 b3 c2   (the white king, the white rook and the black king)"
		return
	ok

	# the positions that were given: three squares for each
	nGiven = floor(len(aSquares) / 3)
	if nGiven = 0
		? "A position is three squares: the white king, the white rook and the black king, for example   ring predict.ring a1 b3 c2"
		return
	ok
	cText = chessHeader() + nl
	for nPosition = 1 to nGiven
		aKing = chessSquare(aSquares[nPosition * 3 - 2])
		aRook = chessSquare(aSquares[nPosition * 3 - 1])
		aBlack = chessSquare(aSquares[nPosition * 3])
		cText += chessLine(chessFeatures(aKing[1],aKing[2],aRook[1],aRook[2],aBlack[1],aBlack[2]),"draw") + nl          # the result is not known: the column is filled with a word
	next
	write("data/positions.csv",cText)
	aPredicted = chessColumn(aLoaded[1].Transform(chessLoad(oMl,"data/positions.csv")),"System.String","PredictedResult")
	for nPosition = 1 to nGiven
		aKing = chessSquare(aSquares[nPosition * 3 - 2])
		aRook = chessSquare(aSquares[nPosition * 3 - 1])
		aBlack = chessSquare(aSquares[nPosition * 3])
		? nl + "white king " + lower(aSquares[nPosition * 3 - 2]) + ", white rook " + lower(aSquares[nPosition * 3 - 1]) + ", black king " + lower(aSquares[nPosition * 3]) + ":"
		showBoard(aKing,aRook,aBlack)
		if (aKing[1] = aRook[1] and aKing[2] = aRook[2]) or (aKing[1] = aBlack[1] and aKing[2] = aBlack[2]) or (aRook[1] = aBlack[1] and aRook[2] = aBlack[2])
			? "  two pieces are on the same square: this is not a position"
		but chessDistance(aKing[1],aKing[2],aBlack[1],aBlack[2]) <= 1
			? "  the kings touch each other: this can not be a position of a game (the model answers anyway)"
		ok
		? "  the model says: " + chessSay(aPredicted[nPosition])
	next

# The name of a square from its file letter and its rank
func chessName nFile, nRank

	return char(96 + number(nFile)) + nRank

# The board as text: K the white king, R the white rook, k the black king
func showBoard aKing, aRook, aBlack

	for nRank = 8 to 1 step -1
		cLine = "  " + nRank + " "
		for nFile = 1 to 8
			cPiece = "."
			if aKing[1] = nFile and aKing[2] = nRank
				cPiece = "K"
			but aRook[1] = nFile and aRook[2] = nRank
				cPiece = "R"
			but aBlack[1] = nFile and aBlack[2] = nRank
				cPiece = "k"
			ok
			cLine += cPiece + " "
		next
		? cLine
	next
	? "    a b c d e f g h"

func padRight cText, nWidth

	cText = "" + cText
	if len(cText) >= nWidth
		return cText
	ok
	return cText + copy(" ",nWidth - len(cText))
