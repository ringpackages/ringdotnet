# ML.NET recommendation: matrix factorization (the native LIBMF library) learns what each user likes from ratings; users and items are texts that are mapped to keys, and
# the model scores a pair of a user and an item that it has not seen
load "pkg.ring"
pkgUseProject("mlnet","helpers/MlHelpers",[["MlHelpers.dll",["MlHelpers"]],["Microsoft.ML.Data.dll",["Microsoft.ML","Microsoft.ML.Data"]],["Microsoft.ML.Core.dll",[]],["Microsoft.ML.StandardTrainers.dll",["Microsoft.ML.Trainers"]],["Microsoft.ML.Transforms.dll",[]],["Microsoft.ML.DataView.dll",[]],["Microsoft.ML.CpuMath.dll",[]],["Microsoft.ML.FastTree.dll",[]],["Microsoft.ML.KMeansClustering.dll",[]],["Microsoft.ML.PCA.dll",[]],["Microsoft.ML.Mkl.Components.dll",[]],["Microsoft.ML.TimeSeries.dll",[]],["Microsoft.ML.LightGbm.dll",[]],["Microsoft.ML.Recommender.dll",[]]])
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML")
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML.Data")

oMl = dnNew("Microsoft.ML.MLContext",[71])
oColumns = dnType("Microsoft.ML.Data.ColumnCursorExtensions")

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
cFile = cPkgCache + "mlnet/ratings.csv"
write(cFile,cRatings)
aColumns = []
aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["user","String",0])
aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["item","String",1])
aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["rating","Single",2])
oData = oMl.Data.callMethod("LoadFromTextFile",[cFile,aColumns,",",1])
dnAssert("the ratings",len(oColumns.callGeneric("GetColumn",["System.Single"],[oData,"rating"]).toList()),44)

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
cAskFile = cPkgCache + "mlnet/ratings_ask.csv"
write(cAskFile,cAsk)
oAsk = oMl.Data.callMethod("LoadFromTextFile",[cAskFile,aColumns,",",1])
aScores = oColumns.callGeneric("GetColumn",["System.Single"],[oModel.Transform(oAsk),"Score"]).toList()
dnAssert("a score for each pair",len(aScores),4)
dnAssert("ann likes the item 4 (the first group likes 1 to 4)",aScores[1] > 3,1)
dnAssert("bob likes the item 2",aScores[2] > 3,1)
dnAssert("cy likes the item 7 (the second group likes 5 to 8)",aScores[3] > 3,1)
dnAssert("dee likes the item 5",aScores[4] > 3,1)

# a pair of the other taste gets a low score
cOpposite = "user,item,rating" + nl + "ann,i7,0" + nl + "cy,i2,0" + nl
cOppositeFile = cPkgCache + "mlnet/ratings_opposite.csv"
write(cOppositeFile,cOpposite)
oOpposite = oMl.Data.callMethod("LoadFromTextFile",[cOppositeFile,aColumns,",",1])
aLow = oColumns.callGeneric("GetColumn",["System.Single"],[oModel.Transform(oOpposite),"Score"]).toList()
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
