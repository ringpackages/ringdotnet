# The shared part of the chess end game example: getting ML.NET, splitting the data, the features of a position, and the algorithms.
# The data is the end game of a white king and a white rook against a black king (28056 positions). The result of a position is "draw", or the number of moves that white
# needs to win ("zero" to "sixteen").
load "dotnet.ring"

# ---------------------------------------------------------------- ML.NET

# Get ML.NET (dotnet publish copies the DLLs of the packages that ChessEndgame.csproj names into the folder libs), make the Ring classes of its DLLs, and load them.
# The first time needs the internet (the packages come from nuget.org); the next times only load what is there.
func chessSetup

	cHere = currentdir()
	cLibs = cHere + "/libs"
	cClasses = cHere + "/classes"
	cMain = cLibs + "/Microsoft.ML.Data.dll"
	if not fexists(cMain)
		? "Getting ML.NET (the first time only; the packages come from nuget.org) ..."
		system("dotnet publish ChessEndgame.csproj -c Release -o libs -nologo -v q" + chessQuiet())
	ok
	if not fexists(cMain)
		? "ML.NET could not be restored: the computer needs the internet once."
		bye
	ok
	# the classes of the namespaces that the example uses (the generator is a Ring program of this package: tools/dotnettools/wrapassembly.ring)
	if not fexists(cClasses + "/Microsoft.ML.classes.ring")
		? "Making the Ring classes of ML.NET (the first time only) ..."
		chdir("../../../../tools/dotnettools")
		system(exefilename() + ' wrapassembly.ring "' + cMain + '" "' + cClasses + '" Microsoft.ML Microsoft.ML.Data' + chessQuiet())
		system(exefilename() + ' wrapassembly.ring "' + cLibs + '/Microsoft.ML.StandardTrainers.dll" "' + cClasses + '" Microsoft.ML.Trainers' + chessQuiet())
		chdir(cHere)
	ok
	for cDll in ["Microsoft.ML.Data","Microsoft.ML.Core","Microsoft.ML.StandardTrainers","Microsoft.ML.Transforms","Microsoft.ML.DataView","Microsoft.ML.CpuMath","Microsoft.ML.FastTree","Microsoft.ML.LightGbm"]
		dnLoad(cLibs + "/" + cDll + ".dll")
	next
	dnImportFrom(cClasses + "/","Microsoft.ML")
	dnImportFrom(cClasses + "/","Microsoft.ML.Data")
	dnImportFrom(cClasses + "/","Microsoft.ML.Trainers")

func chessQuiet

	if iswindows()
		return " > nul"
	ok
	return " > /dev/null 2>&1"

# A context: the seed makes the random choices of the trainers the same each time (the trainers that use several threads still vary a little)
func chessContext nSeed

	return dnNew("Microsoft.ML.MLContext",[nSeed])

# ---------------------------------------------------------------- the data

# The features of a position. The six numbers are the squares of the pieces (the files a to h are 1 to 8, the ranks are 1 to 8); the others are what a player sees at a glance:
# how far the two kings are from each other, how near the black king is to the edge (0 on the edge), how far the rook is from each king, whether the white king
# guards the rook, whether the black king can take the rook, and whether the rook is on the file or the rank of the black king.
func chessFeatures nWkFile, nWkRank, nWrFile, nWrRank, nBkFile, nBkRank

	nKings = chessDistance(nWkFile,nWkRank,nBkFile,nBkRank)
	nEdge = chessMin4(nBkFile - 1,8 - nBkFile,nBkRank - 1,8 - nBkRank)
	nRookToWhite = chessDistance(nWrFile,nWrRank,nWkFile,nWkRank)
	nRookToBlack = chessDistance(nWrFile,nWrRank,nBkFile,nBkRank)
	nGuarded = (nRookToWhite <= 1)
	nAttacked = (nRookToBlack <= 1 and not nGuarded)
	nAligned = (nWrFile = nBkFile or nWrRank = nBkRank)
	return [nWkFile,nWkRank,nWrFile,nWrRank,nBkFile,nBkRank,nKings,nEdge,nRookToWhite,nRookToBlack,nGuarded,nAttacked,nAligned]

# The distance in moves of a king between two squares
func chessDistance nFile1, nRank1, nFile2, nRank2

	nFiles = fabs(nFile1 - nFile2)
	nRanks = fabs(nRank1 - nRank2)
	if nFiles > nRanks
		return nFiles
	ok
	return nRanks

func chessMin4 a, b, c, d

	nMin = a
	if b < nMin  nMin = b  ok
	if c < nMin  nMin = c  ok
	if d < nMin  nMin = d  ok
	return nMin

# The names of the columns of the files that the example writes: the features, then the result
func chessColumnNames

	return ["WhiteKingFile","WhiteKingRank","WhiteRookFile","WhiteRookRank","BlackKingFile","BlackKingRank","KingsDistance","BlackKingEdge","RookToWhiteKing","RookToBlackKing","RookGuarded","RookAttacked","RookAligned"]

# The line of a CSV file for a position: the features and the result
func chessLine aFeatures, cResult

	cLine = ""
	nFeatures = len(aFeatures)
	for nFeature = 1 to nFeatures
		cLine += "" + aFeatures[nFeature] + ","
	next
	return cLine + cResult

# The header of the files that the example writes
func chessHeader

	cHeader = ""
	for cName in chessColumnNames()
		cHeader += cName + ","
	next
	return cHeader + "GameResult"

# The number of a square written as a1 to h8: [file, rank]
func chessSquare cSquare

	return [ascii(lower(left(cSquare,1))) - 96,number(substr(cSquare,2,1))]

# Split data/chess.csv into data/train.csv (70 percent of the positions) and data/test.csv (30 percent). The positions are shuffled first, with a generator of numbers that
# is the same on every computer, so the split is the same each time. lQuick takes only 1/7 of the positions (for a quick test).
func chessSplit lQuick

	cText = read("data/chess.csv")
	aLines = str2list(cText)
	nLines = len(aLines)
	aRows = []
	for nLine = 2 to nLines
		cLine = aLines[nLine]
		if len(cLine) > 5
			aRows + cLine
		ok
	next
	nRows = len(aRows)
	# a shuffle (Fisher and Yates) with a generator that does not depend on the system: seed * 16807 mod 2147483647
	nSeed = 42
	for nPlace = nRows to 2 step -1
		nSeed = (nSeed * 16807) % 2147483647
		nOther = 1 + floor(nSeed / 2147483647 * nPlace)
		cSwap = aRows[nPlace]
		aRows[nPlace] = aRows[nOther]
		aRows[nOther] = cSwap
	next
	if lQuick
		nRows = floor(nRows / 7)
	ok
	nTrain = floor(nRows * 0.7)
	cTrain = chessHeader() + nl
	cTest = chessHeader() + nl
	for nRow = 1 to nRows
		aParts = str2list(substr(aRows[nRow],",",nl))
		aSquare1 = chessSquare(aParts[1] + aParts[2])
		aSquare2 = chessSquare(aParts[3] + aParts[4])
		aSquare3 = chessSquare(aParts[5] + aParts[6])
		cLine = chessLine(chessFeatures(aSquare1[1],aSquare1[2],aSquare2[1],aSquare2[2],aSquare3[1],aSquare3[2]),aParts[7]) + nl
		if nRow <= nTrain
			cTrain += cLine
		else
			cTest += cLine
		ok
	next
	write("data/train.csv",cTrain)
	write("data/test.csv",cTest)
	return [nTrain,nRows - nTrain]

# The columns of data/train.csv and data/test.csv for the text loader of ML.NET
func chessColumns

	aColumns = []
	nPlace = 0
	for cName in chessColumnNames()
		aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",[cName,"Single",nPlace])
		nPlace++
	next
	aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["GameResult","String",nPlace])
	return aColumns

# A file of the example as a data view
func chessLoad oMl, cFile

	return oMl.Data.callMethod("LoadFromTextFile",[cFile,chessColumns(),",",1])

# A column of a data view as a Ring list
func chessColumn oData, cType, cName

	return dnType("Microsoft.ML.Data.ColumnCursorExtensions").callGeneric("GetColumn",[cType],[oData,cName]).toList()

# ---------------------------------------------------------------- the results

# The result of a game as a number: "draw" is -1, "zero" to "sixteen" are the moves that white needs to win (0 to 16)
func chessDepth cResult

	nPlace = find(["zero","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen"],cResult)
	return nPlace - 1

# The result in words
func chessSay cResult

	if cResult = "draw"
		return "a draw"
	ok
	nMoves = chessDepth(cResult)
	if nMoves = 1
		return "white wins in 1 move"
	ok
	return "white wins in " + nMoves + " moves"

# The accuracy of the answers of a model: how many are exactly right, and how many are wrong by one move at most (a draw is only right when it is a draw).
# aActual and aPredicted are the lists of the results as texts.
func chessAccuracy aActual, aPredicted

	nTotal = len(aActual)
	nExact = 0
	nNear = 0
	for nPlace = 1 to nTotal
		if aActual[nPlace] = aPredicted[nPlace]
			nExact++
			nNear++
		but aActual[nPlace] != "draw" and aPredicted[nPlace] != "draw"
			if fabs(chessDepth(aActual[nPlace]) - chessDepth(aPredicted[nPlace])) <= 1
				nNear++
			ok
		ok
	next
	return [nExact / nTotal,nNear / nTotal]

# ---------------------------------------------------------------- the algorithms

# The feature sets: the numbers of the six squares, the squares as one-hot vectors (a 0 or a 1 for each square: 48 numbers), and the squares with the other features
func chessFeaturePipeline oMl, cSet

	oChain = ""
	switch cSet
	on "squares"
		return oMl.Transforms.callMethod("Concatenate",["Features",["WhiteKingFile","WhiteKingRank","WhiteRookFile","WhiteRookRank","BlackKingFile","BlackKingRank"]])
	on "onehot"
		aNames = ["WhiteKingFile","WhiteKingRank","WhiteRookFile","WhiteRookRank","BlackKingFile","BlackKingRank"]
		aHot = []
		for cName in aNames
			oOne = oMl.Transforms.Categorical.callMethod("OneHotEncoding",[cName + "Hot",cName])
			if isstring(oChain)
				oChain = oOne
			else
				oChain = oChain.callMethod("Append",[oOne])
			ok
			aHot + (cName + "Hot")
		next
		return oChain.callMethod("Append",[oMl.Transforms.callMethod("Concatenate",["Features",aHot])])
	off
	return oMl.Transforms.callMethod("Concatenate",["Features",chessColumnNames()])

# The trainer of an algorithm (the label is the key of the result, the features are in the column Features). The binary trainers are made into trainers of many classes
# with OneVersusAll: one model for each result, and the model with the highest score answers.
func chessTrainer oMl, cKey

	oBinary = oMl.BinaryClassification.Trainers
	oMulti = oMl.MulticlassClassification.Trainers
	switch cKey
	on "logistic"
		return oMulti.callMethod("SdcaMaximumEntropy",["Label","Features"])
	on "lbfgs"
		return oMulti.callMethod("LbfgsMaximumEntropy",["Label","Features"])
	on "sdca"
		return oMulti.callMethod("SdcaNonCalibrated",["Label","Features"])
	on "naive"
		return oMulti.callMethod("NaiveBayes",["Label","Features"])
	on "perceptron"
		return oMulti.callMethod("OneVersusAll",[oBinary.callMethod("AveragedPerceptron",["Label","Features"]),"Label"])
	on "svm"
		return oMulti.callMethod("OneVersusAll",[oBinary.callMethod("LinearSvm",["Label","Features"]),"Label"])
	on "tree"
		# a single decision tree for each result: a forest of one tree, with many leaves
		return oMulti.callMethod("OneVersusAll",[oBinary.callMethod("FastForest",["Label","Features",dnNull(),200,1,2]),"Label"])
	on "forest"
		return oMulti.callMethod("OneVersusAll",[oBinary.callMethod("FastForest",["Label","Features"]),"Label"])
	on "fasttree"
		return oMulti.callMethod("OneVersusAll",[oBinary.callMethod("FastTree",["Label","Features"]),"Label"])
	on "lightgbm"
		return oMulti.callMethod("LightGbm",["Label","Features"])
	off
	raise("The algorithm is not known: " + cKey)

# The algorithms of the example: [key, name, feature set]. The linear algorithms read the one-hot squares (a line can not tell much from the number of a rank), the trees read the squares
# and the other features. A quick run (for a test) tries three.
func chessAlgorithms lQuick

	if lQuick
		return [ ["logistic","Logistic regression (SDCA)","onehot"], ["tree","Decision tree (one versus all)","engineered"], ["lightgbm","LightGBM (boosted trees)","engineered"] ]
	ok
	return [
		["logistic","Logistic regression (SDCA)","onehot"],
		["lbfgs","Logistic regression (L-BFGS)","onehot"],
		["sdca","Linear model (SDCA, no calibration)","onehot"],
		["naive","Naive Bayes","onehot"],
		["perceptron","Averaged perceptron (one versus all)","onehot"],
		["svm","Linear SVM (one versus all)","onehot"],
		["tree","Decision tree (one versus all)","squares"],
		["tree","Decision tree (one versus all)","engineered"],
		["forest","Random forest (one versus all)","engineered"],
		["fasttree","Boosted trees: FastTree (one versus all)","engineered"],
		["lightgbm","LightGBM (boosted trees)","squares"],
		["lightgbm","LightGBM (boosted trees)","engineered"]
	]

# The name of the file of a model
func chessModelFile aAlgorithm

	return "models/" + aAlgorithm[1] + "_" + aAlgorithm[3] + ".zip"

# The whole pipeline of an algorithm: the label as a key, the features, the trainer, and the key of the answer as the text of the result
func chessPipeline oMl, aAlgorithm

	oPipeline = oMl.Transforms.Conversion.callMethod("MapValueToKey",["Label","GameResult"])
	oPipeline = oPipeline.callMethod("Append",[chessFeaturePipeline(oMl,aAlgorithm[3])])
	oPipeline = oPipeline.callMethod("Append",[chessTrainer(oMl,aAlgorithm[1])])
	return oPipeline.callMethod("Append",[oMl.Transforms.Conversion.callMethod("MapKeyToValue",["PredictedResult","PredictedLabel"])])
