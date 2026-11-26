# ML.NET: more classifiers: linear SVM, averaged perceptron, SGD logistic regression and SDCA without calibration for a yes or no, and naive Bayes, maximum entropy and
# one-versus-all (a binary trainer made into a multiclass one) for several classes; the data is a CSV file read with columns made in Ring
load "pkg.ring"
pkgUseProject("mlnet","helpers/MlHelpers",[["MlHelpers.dll",["MlHelpers"]],["Microsoft.ML.Data.dll",["Microsoft.ML","Microsoft.ML.Data"]],["Microsoft.ML.Core.dll",[]],["Microsoft.ML.StandardTrainers.dll",["Microsoft.ML.Trainers"]],["Microsoft.ML.Transforms.dll",[]],["Microsoft.ML.DataView.dll",[]],["Microsoft.ML.CpuMath.dll",[]],["Microsoft.ML.FastTree.dll",[]],["Microsoft.ML.KMeansClustering.dll",[]],["Microsoft.ML.PCA.dll",[]],["Microsoft.ML.Mkl.Components.dll",[]],["Microsoft.ML.TimeSeries.dll",[]],["Microsoft.ML.LightGbm.dll",[]],["Microsoft.ML.Recommender.dll",[]]])
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML")
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML.Data")

oMl = dnNew("Microsoft.ML.MLContext",[41])
oColumns = dnType("Microsoft.ML.Data.ColumnCursorExtensions")

# ---- two classes: the class is yes when x + y is above 10 (a grid without the points on the line)
cBinary = "x,y,label" + nl
for x = 0 to 10
	for y = 0 to 10
		if x + y != 10
			cBinary += "" + x + "," + y + "," + (x + y > 10) + nl
		ok
	next
next
cBinaryFile = cPkgCache + "mlnet/binary.csv"
write(cBinaryFile,cBinary)
aBinaryColumns = []
aBinaryColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["x","Single",0])
aBinaryColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["y","Single",1])
aBinaryColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["label","Boolean",2])
oBinary = oMl.Data.callMethod("LoadFromTextFile",[cBinaryFile,aBinaryColumns,",",1])

# the trainers that give a probability (calibrated) and the ones that give only a score
for cTrainer in ["SgdCalibrated","SdcaLogisticRegression"]
	aArguments = ["label","Features"]
	if cTrainer = "SgdCalibrated"
		aArguments = ["label","Features",dnNull(),100]          # an online learner: it goes over the rows 100 times
	ok
	oModel = binaryPipeline().callMethod("Append",[oMl.BinaryClassification.Trainers.callMethod(cTrainer,aArguments)]).Fit(oBinary)
	oMetrics = oMl.BinaryClassification.callMethod("Evaluate",[oModel.Transform(oBinary),"label"])
	dnAssert(cTrainer + ": the accuracy",oMetrics.Accuracy > 0.9,1)
	aProbability = oColumns.callGeneric("GetColumn",["System.Single"],[oModel.Transform(oBinary),"Probability"]).toList()
	dnAssert(cTrainer + ": a probability for each row",len(aProbability),110)
next
for cTrainer in ["LinearSvm","AveragedPerceptron","SdcaNonCalibrated"]
	aArguments = ["label","Features"]
	if cTrainer = "LinearSvm"
		aArguments = ["label","Features",dnNull(),50]          # an online learner: it goes over the rows 50 times
	ok
	oModel = binaryPipeline().callMethod("Append",[oMl.BinaryClassification.Trainers.callMethod(cTrainer,aArguments)]).Fit(oBinary)
	oMetrics = oMl.BinaryClassification.callMethod("EvaluateNonCalibrated",[oModel.Transform(oBinary),"label"])
	dnAssert(cTrainer + ": the accuracy",oMetrics.Accuracy > 0.9,1)
	dnAssert(cTrainer + ": the area under the curve",oMetrics.AreaUnderRocCurve > 0.95,1)
	aScores = oColumns.callGeneric("GetColumn",["System.Single"],[oModel.Transform(oBinary),"Score"]).toList()
	aLabels = oColumns.callGeneric("GetColumn",["System.Boolean"],[oModel.Transform(oBinary),"label"]).toList()
	# the score is positive for the class yes: the sign of the score agrees with the label for most rows
	nAgree = 0
	for n = 1 to len(aScores)
		if (aScores[n] > 0) = aLabels[n]
			nAgree++
		ok
	next
	dnAssert(cTrainer + ": the sign of the score gives the class",nAgree / len(aScores) > 0.9,1)
next

# ---- three classes: groups of points around (0, 0), (6, 0) and (3, 6)
aCenters = [ ["red",0,0], ["green",6,0], ["blue",3,6] ]
cMulti = "x,y,group" + nl
for aCenter in aCenters
	for dx = -1 to 1
		for dy = -1 to 1
			cMulti += "" + (aCenter[2] + dx * 0.6) + "," + (aCenter[3] + dy * 0.6) + "," + aCenter[1] + nl
		next
	next
next
cMultiFile = cPkgCache + "mlnet/multi.csv"
write(cMultiFile,cMulti)
aMultiColumns = []
aMultiColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["x","Single",0])
aMultiColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["y","Single",1])
aMultiColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["group","String",2])
oMulti = oMl.Data.callMethod("LoadFromTextFile",[cMultiFile,aMultiColumns,",",1])
dnAssert("27 points",len(oColumns.callGeneric("GetColumn",["System.Single"],[oMulti,"x"]).toList()),27)

# a question: points near each center, written to a file with a placeholder group
cQuestions = "x,y,group" + nl + "0.2,0.1,?" + nl + "5.8,0.3,?" + nl + "3.1,5.9,?" + nl
cQuestionsFile = cPkgCache + "mlnet/multi_questions.csv"
write(cQuestionsFile,cQuestions)
oQuestions = oMl.Data.callMethod("LoadFromTextFile",[cQuestionsFile,aMultiColumns,",",1])

for cName in ["SdcaMaximumEntropy","LbfgsMaximumEntropy","OneVersusAll"]
	oPipeline = oMl.Transforms.Conversion.callMethod("MapValueToKey",["Label","group"]).callMethod("Append",[oMl.Transforms.callMethod("Concatenate",["Features",["x","y"]])])
	if cName = "OneVersusAll"
		# a binary trainer is made into a multiclass one
		oTrainer = oMl.MulticlassClassification.Trainers.callMethod("OneVersusAll",[oMl.BinaryClassification.Trainers.callMethod("SdcaLogisticRegression",["Label","Features"]),"Label"])
	else
		oTrainer = oMl.MulticlassClassification.Trainers.callMethod(cName,["Label","Features"])
	ok
	oModel = oPipeline.callMethod("Append",[oTrainer]).callMethod("Append",[oMl.Transforms.Conversion.callMethod("MapKeyToValue",["PredictedGroup","PredictedLabel"])]).Fit(oMulti)
	oMetrics = oMl.MulticlassClassification.callMethod("Evaluate",[oModel.Transform(oMulti)])
	dnAssert(cName + ": the accuracy over three classes",oMetrics.MicroAccuracy > 0.95,1)
	aGroups = oColumns.callGeneric("GetColumn",["System.String"],[oModel.Transform(oQuestions),"PredictedGroup"]).toList()
	dnAssert(cName + ": a point near the first center",aGroups[1],"red")
	dnAssert(cName + ": a point near the second center",aGroups[2],"green")
	dnAssert(cName + ": a point near the third center",aGroups[3],"blue")
next

# ---- naive Bayes works with features that are 0 or 1 (it counts how often each one is present in each class): three binary features and a class that depends on them
cBits = "f1,f2,f3,kind" + nl
for n = 1 to 6
	cBits += "1,0,0,first" + nl
	cBits += "0,1,0,second" + nl
	cBits += "0,0,1,third" + nl
next
cBits += "1,0,1,first" + nl + "0,1,1,second" + nl + "1,0,0,first" + nl
cBitsFile = cPkgCache + "mlnet/bits.csv"
write(cBitsFile,cBits)
aBitColumns = []
aBitColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["f1","Single",0])
aBitColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["f2","Single",1])
aBitColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["f3","Single",2])
aBitColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["kind","String",3])
oBits = oMl.Data.callMethod("LoadFromTextFile",[cBitsFile,aBitColumns,",",1])
oBayes = oMl.Transforms.Conversion.callMethod("MapValueToKey",["Label","kind"]).callMethod("Append",[oMl.Transforms.callMethod("Concatenate",["Features",["f1","f2","f3"]])]).callMethod("Append",[oMl.MulticlassClassification.Trainers.callMethod("NaiveBayes",["Label","Features"])]).Fit(oBits)
dnAssert("NaiveBayes: the accuracy on binary features",oMl.MulticlassClassification.callMethod("Evaluate",[oBayes.Transform(oBits)]).MicroAccuracy > 0.9,1)
dnTestSummary()

# the features of the binary data are joined and brought to the same scale
func binaryPipeline

	return oMl.Transforms.callMethod("Concatenate",["Features",["x","y"]]).callMethod("Append",[oMl.Transforms.callMethod("NormalizeMeanVariance",["Features"])])
