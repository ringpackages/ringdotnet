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
	# the classes of the namespaces that the example uses (the generator is a Ring program of this package: tools/dotnettools/wrapassembly.ring). The assemblies that belong together
	# are wrapped in one run: the extension methods of the trainers (LightGbm, FastTree) join the classes of the catalogs of Microsoft.ML.Data, and the result of a call is wrapped
	# by its real type (an estimator has Fit).
	cStamp = chessStamp(cHere)
	if not fexists(cClasses + "/Microsoft.ML.Trainers.LightGbm.classes.ring") or not fexists(cClasses + "/.generator") or read(cClasses + "/.generator") != cStamp
		? "Making the Ring classes of ML.NET (the first time only, and when the generator changed) ..."
		cDlls = ""
		for cDll in ["Microsoft.ML.Data","Microsoft.ML.DataView","Microsoft.ML.Transforms","Microsoft.ML.StandardTrainers","Microsoft.ML.FastTree","Microsoft.ML.LightGbm"]
			cDlls += cLibs + "/" + cDll + ".dll;"
		next
		chdir("../../../../../tools/dotnettools")
		system(exefilename() + ' wrapassembly.ring "' + left(cDlls,len(cDlls) - 1) + '" "' + cClasses + '" Microsoft.ML Microsoft.ML.Data Microsoft.ML.Transforms Microsoft.ML.Trainers Microsoft.ML.Trainers.FastTree Microsoft.ML.Trainers.LightGbm' + chessQuiet())
		chdir(cHere)
		write(cClasses + "/.generator",cStamp)
	ok
	for cDll in ["Microsoft.ML.Data","Microsoft.ML.Core","Microsoft.ML.StandardTrainers","Microsoft.ML.Transforms","Microsoft.ML.DataView","Microsoft.ML.CpuMath","Microsoft.ML.FastTree","Microsoft.ML.LightGbm"]
		dnLoad(cLibs + "/" + cDll + ".dll")
	next
	for cNamespace in ["Microsoft.ML","Microsoft.ML.Data","Microsoft.ML.Transforms","Microsoft.ML.Trainers","Microsoft.ML.Trainers.FastTree","Microsoft.ML.Trainers.LightGbm"]
		dnImportFrom(cClasses + "/",cNamespace)
	next

# A text that changes when the generator, the bridge or the generated library changes: the classes of the folder are made again then (they would show an old generator)
func chessStamp cHere

	cText = ""
	for cFile in ["tools/dotnettools/gendotnetcore.ring","tools/dotnettools/wrapassembly.ring","bin/RingDotNet.Bridge.dll","libraries/dotnetlib/generated/classindex.ring"]
		cText += left(dnStatic("System.Convert","ToHexString",[dnStatic("System.Security.Cryptography.SHA256","HashData",[read(cHere + "/../../../../../" + cFile)])]),16) + ";"
	next
	return cText

func chessQuiet

	if iswindows()
		return " > nul"
	ok
	return " > /dev/null 2>&1"

# A context: the seed makes the random choices of the trainers the same each time (the trainers that use several threads still vary a little)
func chessContext nSeed

	return new MLContext().@New([ :seed = nSeed ])

# ---------------------------------------------------------------- the data

# The features of a position. The six numbers are the squares of the pieces (the files a to h are 1 to 8, the ranks are 1 to 8); the others are what a player sees at a glance:
# how far the two kings are from each other, how near the black king is to the edge (0 on the edge), how far the rook is from each king, whether the white king
# guards the rook, whether the black king can take the rook, and whether the rook is on the file or the rank of the black king.
func chessFeatures nWkFile, nWkRank, nWrFile, nWrRank, nBkFile, nBkRank

	# the position in the way that the data has it (the white king in the lower left triangle)
	aCanonical = chessCanonical(nWkFile,nWkRank,nWrFile,nWrRank,nBkFile,nBkRank)
	nWkFile = aCanonical[1]
	nWkRank = aCanonical[2]
	nWrFile = aCanonical[3]
	nWrRank = aCanonical[4]
	nBkFile = aCanonical[5]
	nBkRank = aCanonical[6]
	nKings = chessDistance(nWkFile,nWkRank,nBkFile,nBkRank)
	nEdge = chessMin4(nBkFile - 1,8 - nBkFile,nBkRank - 1,8 - nBkRank)
	nRookToWhite = chessDistance(nWrFile,nWrRank,nWkFile,nWkRank)
	nRookToBlack = chessDistance(nWrFile,nWrRank,nBkFile,nBkRank)
	nGuarded = (nRookToWhite <= 1)
	nAttacked = (nRookToBlack <= 1 and not nGuarded)
	nAligned = (nWrFile = nBkFile or nWrRank = nBkRank)
	return [nWkFile,nWkRank,nWrFile,nWrRank,nBkFile,nBkRank,nKings,nEdge,nRookToWhite,nRookToBlack,nGuarded,nAttacked,nAligned]

# The position turned and mirrored the way that the data has it. The board can be turned and mirrored (8 ways) without changing the result of the game, and the data keeps
# one way for each position: the white king in the lower left triangle (a1 b1 c1 d1 b2 c2 d2 c3 d3 d4). A position that is anywhere else is changed to that way before a model
# sees it, or the model would be asked about positions that it never learned from. (When two ways put the king there, the one with the smaller numbers is used.)
func chessCanonical nWkFile, nWkRank, nWrFile, nWrRank, nBkFile, nBkRank

	aBest = []
	aPieces = [nWkFile - 1,nWkRank - 1,nWrFile - 1,nWrRank - 1,nBkFile - 1,nBkRank - 1]
	for nWay = 1 to 8
		aCandidate = []
		for nPiece = 1 to 3
			nX = aPieces[nPiece * 2 - 1]
			nY = aPieces[nPiece * 2]
			switch nWay
			on 1
				aCandidate + nX
				aCandidate + nY
			on 2
				aCandidate + (7 - nX)
				aCandidate + nY
			on 3
				aCandidate + nX
				aCandidate + (7 - nY)
			on 4
				aCandidate + (7 - nX)
				aCandidate + (7 - nY)
			on 5
				aCandidate + nY
				aCandidate + nX
			on 6
				aCandidate + (7 - nY)
				aCandidate + nX
			on 7
				aCandidate + nY
				aCandidate + (7 - nX)
			on 8
				aCandidate + (7 - nY)
				aCandidate + (7 - nX)
			off
		next
		# the data has the white king in the lower left triangle only (a1 b1 c1 d1 b2 c2 d2 c3 d3 d4): the ways that put it there are the candidates
		if aCandidate[1] <= 3 and aCandidate[2] <= aCandidate[1]
			if len(aBest) = 0 or chessSmaller(aCandidate,aBest)
				aBest = aCandidate
			ok
		ok
	next
	return [aBest[1] + 1,aBest[2] + 1,aBest[3] + 1,aBest[4] + 1,aBest[5] + 1,aBest[6] + 1]

# 1 when the list of numbers aFirst comes before aSecond (the first number that is different decides)
func chessSmaller aFirst, aSecond

	nNumbers = len(aFirst)
	for nNumber = 1 to nNumbers
		if aFirst[nNumber] < aSecond[nNumber]
			return 1
		but aFirst[nNumber] > aSecond[nNumber]
			return 0
		ok
	next
	return 0

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
		aColumns + new TextLoaderColumn().@New([ :name = cName, :dataKind = "Single", :index = nPlace ])
		nPlace++
	next
	aColumns + new TextLoaderColumn().@New([ :name = "GameResult", :dataKind = "String", :index = nPlace ])
	return aColumns

# A file of the example as a data view
func chessLoad oMl, cFile

	return oMl.Data.LoadFromTextFile([ :path = cFile, :columns = chessColumns(), :separatorChar = ",", :hasHeader = true ])

# A column of a data view as a Ring list
func chessColumn oData, cType, cName

	oCursors = new ColumnCursorExtensions()
	return oCursors.GetColumn([ :typeArguments = [cType], :data = oData, :columnName = cName ]).toList()          # the type of the column is only in the result: :typeArguments

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
		return oMl.Transforms.Concatenate("Features",["WhiteKingFile","WhiteKingRank","WhiteRookFile","WhiteRookRank","BlackKingFile","BlackKingRank"])
	on "onehot"
		aNames = ["WhiteKingFile","WhiteKingRank","WhiteRookFile","WhiteRookRank","BlackKingFile","BlackKingRank"]
		aHot = []
		for cName in aNames
			oOne = oMl.Transforms.Categorical.OneHotEncoding([ :outputColumnName = cName + "Hot", :inputColumnName = cName ])
			if isstring(oChain)
				oChain = oOne
			else
				oChain = oChain.Append(oOne)
			ok
			aHot + (cName + "Hot")
		next
		return oChain.Append(oMl.Transforms.Concatenate("Features",aHot))
	off
	return oMl.Transforms.Concatenate("Features",chessColumnNames())

# The trainer of an algorithm (the label is the key of the result, the features are in the column Features). The binary trainers are made into trainers of many classes
# with OneVersusAll: one model for each result, and the model with the highest score answers.
func chessTrainer oMl, cKey

	oBinary = oMl.BinaryClassification.Trainers
	oMulti = oMl.MulticlassClassification.Trainers
	aColumns = [ :labelColumnName = "Label", :featureColumnName = "Features" ]          # the arguments that the methods have names for: a call with names finds the overload
	switch cKey
	on "logistic"
		return oMulti.SdcaMaximumEntropy(aColumns)
	on "lbfgs"
		return oMulti.LbfgsMaximumEntropy(aColumns)
	on "sdca"
		return oMulti.SdcaNonCalibrated(aColumns)
	on "naive"
		return oMulti.NaiveBayes(aColumns)
	on "perceptron"
		return oMulti.OneVersusAll([ :binaryEstimator = oBinary.AveragedPerceptron(aColumns), :labelColumnName = "Label" ])
	on "svm"
		return oMulti.OneVersusAll([ :binaryEstimator = oBinary.LinearSvm(aColumns), :labelColumnName = "Label" ])
	on "forest-tuned"
		# trees with more leaves that may hold two positions: 200 trees of 200 leaves
		return oMulti.OneVersusAll([ :binaryEstimator = oBinary.FastForest([ :labelColumnName = "Label", :featureColumnName = "Features", :numberOfLeaves = 200, :numberOfTrees = 200, :minimumExampleCountPerLeaf = 2 ]), :labelColumnName = "Label" ])
	on "fasttree-tuned"
		# the number of leaves, the number of trees, the least positions of a leaf and the learning rate
		return oMulti.OneVersusAll([ :binaryEstimator = oBinary.FastTree([ :labelColumnName = "Label", :featureColumnName = "Features", :numberOfLeaves = 127, :numberOfTrees = 200, :minimumExampleCountPerLeaf = 2, :learningRate = 0.15 ]), :labelColumnName = "Label" ])
	on "lightgbm-tuned"
		# the options of LightGBM are an object: 127 leaves, 300 rounds of trees, a learning rate of 0.1, and leaves that may hold two positions
		oOptions = new LightGbmMulticlassTrainerOptions()
		oOptions {
			LabelColumnName = "Label"
			FeatureColumnName = "Features"
			NumberOfLeaves = 127
			NumberOfIterations = 300
			LearningRate = 0.1
			MinimumExampleCountPerLeaf = 2
		}
		return oMulti.LightGbm(oOptions)
	on "tree"
		# a single decision tree for each result: a forest of one tree, with many leaves
		return oMulti.OneVersusAll([ :binaryEstimator = oBinary.FastForest([ :labelColumnName = "Label", :featureColumnName = "Features", :numberOfLeaves = 200, :numberOfTrees = 1, :minimumExampleCountPerLeaf = 2 ]), :labelColumnName = "Label" ])
	on "forest"
		return oMulti.OneVersusAll([ :binaryEstimator = oBinary.FastForest(aColumns), :labelColumnName = "Label" ])
	on "fasttree"
		return oMulti.OneVersusAll([ :binaryEstimator = oBinary.FastTree(aColumns), :labelColumnName = "Label" ])
	on "lightgbm"
		return oMulti.LightGbm(aColumns)
	off
	raise("The algorithm is not known: " + cKey)

# The algorithms of the example: [key, name, feature set]. The linear algorithms read the one-hot squares (a line can not tell much from the number of a rank), the trees read the squares
# and the other features. The "tuned" ones have settings that are not the defaults (more and larger trees). A quick run (for a test) tries three.
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
		["forest-tuned","Random forest, tuned (one versus all)","engineered"],
		["fasttree","Boosted trees: FastTree (one versus all)","engineered"],
		["fasttree-tuned","Boosted trees: FastTree, tuned (one versus all)","engineered"],
		["lightgbm","LightGBM (boosted trees)","squares"],
		["lightgbm","LightGBM (boosted trees)","engineered"],
		["lightgbm-tuned","LightGBM, tuned (boosted trees)","engineered"]
	]

# The name of the file of a model
func chessModelFile aAlgorithm

	return "models/" + aAlgorithm[1] + "_" + aAlgorithm[3] + ".zip"

# The whole pipeline of an algorithm: the label as a key, the features, the trainer, and the key of the answer as the text of the result
func chessPipeline oMl, aAlgorithm

	oPipeline = oMl.Transforms.Conversion.MapValueToKey([ :outputColumnName = "Label", :inputColumnName = "GameResult" ])
	oPipeline = oPipeline.Append(chessFeaturePipeline(oMl,aAlgorithm[3]))
	oPipeline = oPipeline.Append(chessTrainer(oMl,aAlgorithm[1]))
	return oPipeline.Append(oMl.Transforms.Conversion.MapKeyToValue([ :outputColumnName = "PredictedResult", :inputColumnName = "PredictedLabel" ]))

# ---------------------------------------------------------------- training and answers

# Train every algorithm of chessAlgorithms() on data/train.csv, test it on data/test.csv, save it in models, and write models/index.txt (the best first, a line is
# key|name|features|accuracy|accuracy within 1, the accuracies in hundred thousandths). After each algorithm the function cEach is called with
# (the number of the algorithm, how many there are, the algorithm, the accuracy and the one within 1, the seconds). The answer is the list of the results, the best first:
# [accuracy, accuracy within 1, the algorithm, the seconds]
func chessTrainAll oMl, lQuick, cEach
	
	oTrain = chessLoad(oMl,"data/train.csv")
	oTest = chessLoad(oMl,"data/test.csv")
	aActual = chessColumn(oTest,"System.String","GameResult")
	if not direxists("models")
		system("mkdir models")
	ok
	aResults = []
	aAlgorithms = chessAlgorithms(lQuick)
	nAlgorithms = len(aAlgorithms)
	for nAlgorithm = 1 to nAlgorithms
		aAlgorithm = aAlgorithms[nAlgorithm]
		nStart = clock()
		oModel = chessPipeline(oMl,aAlgorithm).Fit(oTrain)
		nSeconds = (clock() - nStart) / clockspersecond()
		# the test: the model answers for the test positions, and the answers are compared with the real results
		aPredicted = chessColumn(oModel.Transform(oTest),"System.String","PredictedResult")
		aAccuracy = chessAccuracy(aActual,aPredicted)
		# the model is saved with the schema of the data that trained it
		oMl.Model.Save(oModel,oTrain.Schema,currentdir() + "/" + chessModelFile(aAlgorithm))
		aResults + [aAccuracy[1],aAccuracy[2],aAlgorithm,nSeconds]
		if cEach != ""
			call cEach(nAlgorithm,nAlgorithms,aAlgorithm,aAccuracy[1],aAccuracy[2],nSeconds)
		ok
	next
	aResults = chessSort(aResults)
	cIndex = ""
	for aResult in aResults
		cIndex += aResult[3][1] + "|" + aResult[3][2] + "|" + aResult[3][3] + "|" + floor(aResult[1] * 100000 + 0.5) + "|" + floor(aResult[2] * 100000 + 0.5) + nl          # the accuracies in hundred thousandths: a number written as text keeps two decimals
	next
	write("models/index.txt",cIndex)
	return aResults

# The results with the highest accuracy first (a result is [accuracy, accuracy within one move, the algorithm, the seconds])
func chessSort aResults

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

# The models of models/index.txt, the best first: a list of [key, name, features, accuracy, accuracy within 1] (the accuracies as numbers from 0 to 1); empty without models
func chessModels

	aModels = []
	if not fexists("models/index.txt")
		return aModels
	ok
	aLines = str2list(read("models/index.txt"))
	for cLine in aLines
		if len(cLine) > 5
			aParts = str2list(substr(cLine,"|",nl))
			aModels + [aParts[1],aParts[2],aParts[3],number(aParts[4]) / 100000,number(aParts[5]) / 100000]
		ok
	next
	return aModels

# A saved model: the model of the file models/<key>_<features>.zip
func chessLoadModel oMl, aModel

	oCatalog = oMl.Model
	aLoaded = oCatalog.@Load(currentdir() + "/models/" + aModel[1] + "_" + aModel[3] + ".zip")          # Load is a keyword of Ring: it is @Load; the answer is the model and its schema
	return aLoaded[1]

# The answer of a model for one position (the squares as file and rank numbers 1 to 8): the word of the result. The position is turned to the way of the data first
# (chessFeatures), and written as the only line of data/positions.csv, which the model reads.
func chessPredictOne oMl, oModel, aKing, aRook, aBlack

	write("data/positions.csv",chessHeader() + nl + chessLine(chessFeatures(aKing[1],aKing[2],aRook[1],aRook[2],aBlack[1],aBlack[2]),"draw") + nl)          # the result is not known: the column is filled with a word
	return chessColumn(oModel.Transform(chessLoad(oMl,"data/positions.csv")),"System.String","PredictedResult")[1]

# The percent of a number from 0 to 1, with one decimal: 0.8213 is 82.1%, and 0.61 is 61.0%
func chessPercent nValue

	nTenths = floor(nValue * 1000 + 0.5)
	return "" + floor(nTenths / 10) + "." + (nTenths % 10) + "%"
