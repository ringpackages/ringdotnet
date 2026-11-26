# ML.NET: more classifiers: linear SVM, averaged perceptron, SGD logistic regression and SDCA without calibration for a yes or no, and naive Bayes, maximum entropy and
# one-versus-all (a binary trainer made into a multiclass one) for several classes; the data is a CSV file read with columns made in Ring
load "mlcommon.ring"
mlUse()

oMl = mlNew(41)

# ---- two classes: the class is yes when x + y is above 10 (a grid without the points on the line)
cBinary = "x,y,label" + nl
for x = 0 to 10
	for y = 0 to 10
		if x + y != 10
			cBinary += "" + x + "," + y + "," + (x + y > 10) + nl
		ok
	next
next
cBinaryFile = mlWrite("binary.csv",cBinary)
aBinaryColumns = mlColumns([["x","Single"],["y","Single"],["label","Boolean"]])
oBinary = mlLoadCsv(oMl,cBinaryFile,aBinaryColumns)

# the trainers that give a probability (calibrated) and the ones that give only a score
for cTrainer in ["SgdCalibrated","SdcaLogisticRegression"]
	aArguments = ["label","Features"]
	if cTrainer = "SgdCalibrated"
		aArguments = ["label","Features",dnNull(),100]          # an online learner: it goes over the rows 100 times
	ok
	oModel = binaryPipeline().callMethod("Append",[oMl.BinaryClassification.Trainers.callMethod(cTrainer,aArguments)]).Fit(oBinary)
	oMetrics = oMl.BinaryClassification.callMethod("Evaluate",[oModel.Transform(oBinary),"label"])
	dnAssert(cTrainer + ": the accuracy",oMetrics.Accuracy > 0.9,1)
	aProbability = mlColumn(oModel.Transform(oBinary),"System.Single","Probability")
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
	aScores = mlColumn(oModel.Transform(oBinary),"System.Single","Score")
	aLabels = mlColumn(oModel.Transform(oBinary),"System.Boolean","label")
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
cMultiFile = mlWrite("multi.csv",cMulti)
aMultiColumns = mlColumns([["x","Single"],["y","Single"],["group","String"]])
oMulti = mlLoadCsv(oMl,cMultiFile,aMultiColumns)
dnAssert("27 points",len(mlColumn(oMulti,"System.Single","x")),27)

# a question: points near each center, written to a file with a placeholder group
cQuestions = "x,y,group" + nl + "0.2,0.1,?" + nl + "5.8,0.3,?" + nl + "3.1,5.9,?" + nl
cQuestionsFile = mlWrite("multi_questions.csv",cQuestions)
oQuestions = mlLoadCsv(oMl,cQuestionsFile,aMultiColumns)

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
	aGroups = mlColumn(oModel.Transform(oQuestions),"System.String","PredictedGroup")
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
cBitsFile = mlWrite("bits.csv",cBits)
aBitColumns = mlColumns([["f1","Single"],["f2","Single"],["f3","Single"],["kind","String"]])
oBits = mlLoadCsv(oMl,cBitsFile,aBitColumns)
oBayes = oMl.Transforms.Conversion.callMethod("MapValueToKey",["Label","kind"]).callMethod("Append",[oMl.Transforms.callMethod("Concatenate",["Features",["f1","f2","f3"]])]).callMethod("Append",[oMl.MulticlassClassification.Trainers.callMethod("NaiveBayes",["Label","Features"])]).Fit(oBits)
dnAssert("NaiveBayes: the accuracy on binary features",oMl.MulticlassClassification.callMethod("Evaluate",[oBayes.Transform(oBits)]).MicroAccuracy > 0.9,1)
dnTestSummary()

# the features of the binary data are joined and brought to the same scale
func binaryPipeline

	return oMl.Transforms.callMethod("Concatenate",["Features",["x","y"]]).callMethod("Append",[oMl.Transforms.callMethod("NormalizeMeanVariance",["Features"])])
