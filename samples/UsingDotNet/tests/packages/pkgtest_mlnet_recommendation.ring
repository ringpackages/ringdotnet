# ML.NET recommendation: matrix factorization (the native LIBMF library) learns what each user likes from ratings; users and items are texts that are mapped to keys, and
# the model scores a pair of a user and an item that it has not seen
load "mlcommon.ring"
mlUse()

oMl = mlNew(71)

# two groups of users: the first likes the items 1 to 4 and dislikes 5 to 8, the second the other way round; some pairs are left out to be asked about
aLeftOut = [ ["ann","i4"], ["bob","i2"], ["cy","i7"], ["dee","i5"] ]
cRatings = "user,item,rating" + nl
for cUser in ["ann","bob","eve"]
	for n = 1 to 8
		cItem = "i" + n
		if not isLeftOut(cUser,cItem)
			if n <= 4
				cRatings += cUser + "," + cItem + ",5" + nl
			else
				cRatings += cUser + "," + cItem + ",1" + nl
			ok
		ok
	next
next
for cUser in ["cy","dee","fay"]
	for n = 1 to 8
		cItem = "i" + n
		if not isLeftOut(cUser,cItem)
			if n <= 4
				cRatings += cUser + "," + cItem + ",1" + nl
			else
				cRatings += cUser + "," + cItem + ",5" + nl
			ok
		ok
	next
next
cFile = mlWrite("ratings.csv",cRatings)
aColumns = mlColumns([["user","String"],["item","String"],["rating","Single"]])
oData = mlLoadCsv(oMl,cFile,aColumns)
dnAssert("the ratings",len(mlColumn(oData,"System.Single","rating")),44)

# users and items become keys, and the trainer learns a vector for each of them
oRecommendation = oMl.callMethod("Recommendation",[])
oOptions = dnNew("Microsoft.ML.Trainers.MatrixFactorizationTrainer+Options",[])
oOptions.setProp("LabelColumnName","rating")
oOptions.setProp("MatrixColumnIndexColumnName","userKey")
oOptions.setProp("MatrixRowIndexColumnName","itemKey")
oOptions.setProp("ApproximationRank",8)
oOptions.setProp("LearningRate",0.1)
oOptions.setProp("NumberOfIterations",40)
oOptions.setProp("Quiet",1)          # the native library prints its progress to the console unless it is told to be quiet
oTrainer = oRecommendation.getProp("Trainers").callMethod("MatrixFactorization",[oOptions])
oPipeline = oMl.Transforms.Conversion.callMethod("MapValueToKey",["userKey","user"]).callMethod("Append",[oMl.Transforms.Conversion.callMethod("MapValueToKey",["itemKey","item"])])
oModel = oPipeline.callMethod("Append",[oTrainer]).Fit(oData)
oMetrics = oMl.Regression.callMethod("Evaluate",[oModel.Transform(oData),"rating"])
dnAssert("the model fits the ratings it was trained on",oMetrics.RSquared > 0.8,1)

# the pairs that were left out: a score for each, read as a column
cAsk = "user,item,rating" + nl
for aPair in aLeftOut
	cAsk += aPair[1] + "," + aPair[2] + ",0" + nl
next
cAskFile = mlWrite("ratings_ask.csv",cAsk)
oAsk = mlLoadCsv(oMl,cAskFile,aColumns)
aScores = mlColumn(oModel.Transform(oAsk),"System.Single","Score")
dnAssert("a score for each pair",len(aScores),4)
dnAssert("ann likes the item 4 (the first group likes 1 to 4)",aScores[1] > 3,1)
dnAssert("bob likes the item 2",aScores[2] > 3,1)
dnAssert("cy likes the item 7 (the second group likes 5 to 8)",aScores[3] > 3,1)
dnAssert("dee likes the item 5",aScores[4] > 3,1)

# a pair of the other taste gets a low score
cOpposite = "user,item,rating" + nl + "ann,i7,0" + nl + "cy,i2,0" + nl
cOppositeFile = mlWrite("ratings_opposite.csv",cOpposite)
oOpposite = mlLoadCsv(oMl,cOppositeFile,aColumns)
aLow = mlColumn(oModel.Transform(oOpposite),"System.Single","Score")
dnAssert("ann is not expected to like the item 7",aLow[1] < 3,1)
dnAssert("cy is not expected to like the item 2",aLow[2] < 3,1)
dnTestSummary()

# a pair that is left out of the ratings
func isLeftOut cUser, cItem

	for aPair in aLeftOut
		if aPair[1] = cUser and aPair[2] = cItem
			return 1
		ok
	next
	return 0
