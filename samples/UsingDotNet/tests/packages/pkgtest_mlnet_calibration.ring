# ML.NET calibrators: a classifier that gives only a score (linear SVM, averaged perceptron) is followed by a calibrator (Platt, naive, isotonic) that turns the score into a probability
# that can be read as a probability: between 0 and 1, rising with the score, and above a half for the rows that the classifier calls positive
load "mlcommon.ring"
mlUse()

oMl = mlNew(29)

# rows of two numbers: the class is yes when F1 + F2 is above 10, with 10 percent of the rows given the other class (noise), so a good probability is not always 0 or 1
cCsv = "F1,F2,Label" + nl
nSeed = 13
for n = 1 to 400
	nSeed = (nSeed * 75 + 74) % 65537
	nF1 = nSeed % 100 / 10
	nSeed = (nSeed * 75 + 74) % 65537
	nF2 = nSeed % 100 / 10
	nSeed = (nSeed * 75 + 74) % 65537
	lYes = (nF1 + nF2 > 10)
	if nSeed % 100 < 10
		lYes = not lYes
	ok
	cCsv += "" + nF1 + "," + nF2 + "," + lYes + nl
next
oData = mlLoadCsv(oMl,mlWrite("calibration.csv",cCsv),mlColumns([["F1","Single"],["F2","Single"],["Label","Boolean"]]))
oFeatures = oMl.Transforms.callMethod("Concatenate",["Features",["F1","F2"]]).callMethod("Append",[oMl.Transforms.callMethod("NormalizeMeanVariance",["Features"])])

# a classifier without a probability: only a score
oSvm = oFeatures.callMethod("Append",[oMl.BinaryClassification.Trainers.callMethod("LinearSvm",["Label","Features",dnNull(),100])]).Fit(oData)
oPlain = oSvm.Transform(oData)
dnAssert("a linear SVM gives a score",len(mlColumn(oPlain,"System.Single","Score")),400)
cNames = ""
for oColumn in oPlain.getProp("Schema").toList()
	cNames += oColumn.getProp("Name") + ","
next
dnAssert("and no probability",substr(cNames,"Probability"),0)

# a calibrator after the classifier: it learns the score to probability map from the scores of the data
for cCalibrator in ["Platt","Naive","Isotonic"]
	oCalibrate = oMl.BinaryClassification.Calibrators.callMethod(cCalibrator,["Label"])
	oCalibrated = oCalibrate.callMethod("Fit",[oPlain]).callMethod("Transform",[oPlain])
	aProbability = mlColumn(oCalibrated,"System.Single","Probability")
	aScore = mlColumn(oCalibrated,"System.Single","Score")
	aLabel = mlColumn(oCalibrated,"System.Boolean","PredictedLabel")
	dnAssert(cCalibrator + ": a probability for each row",len(aProbability),400)
	lRange = 1
	for nValue in aProbability
		if nValue < 0 or nValue > 1
			lRange = 0
		ok
	next
	dnAssert(cCalibrator + ": every probability is between 0 and 1",lRange,1)

	# the probability rises with the score: a row with a higher score never has a lower probability (isotonic is a staircase, the others are smooth)
	nMaxScore = 1
	nMinScore = 1
	for n = 2 to 400
		if aScore[n] > aScore[nMaxScore]
			nMaxScore = n
		ok
		if aScore[n] < aScore[nMinScore]
			nMinScore = n
		ok
	next
	dnAssert(cCalibrator + ": the highest score has a high probability",aProbability[nMaxScore] > 0.7,1)
	dnAssert(cCalibrator + ": the lowest score has a low probability",aProbability[nMinScore] < 0.3,1)
	# the probability rises with the score: a row with a higher score never has a lower probability (Platt and isotonic are monotonic; the naive calibrator counts the rows
	# of each range of scores, so a range can be a little out of order)
	if cCalibrator != "Naive"
		lRising = 1
		for n = 1 to 400
			for m = 1 to 400 step 25
				if aScore[n] > aScore[m] and aProbability[n] < aProbability[m] - 0.000001
					lRising = 0
				ok
			next
		next
		dnAssert(cCalibrator + ": a higher score never gives a lower probability",lRising,1)
	ok

	# the rows of the positive class have a higher probability than the rows of the negative class
	aTrue = mlColumn(oData,"System.Boolean","Label")
	nPositiveSum = 0
	nPositiveCount = 0
	nNegativeSum = 0
	nNegativeCount = 0
	for n = 1 to 400
		if aTrue[n]
			nPositiveSum += aProbability[n]
			nPositiveCount++
		else
			nNegativeSum += aProbability[n]
			nNegativeCount++
		ok
	next
	dnAssert(cCalibrator + ": the mean probability of the positive rows is higher than that of the negative rows by more than 0.25",nPositiveSum / nPositiveCount - nNegativeSum / nNegativeCount > 0.25,1)

	# the metrics of a calibrated classifier: the log loss is only known when there is a probability
	oMetrics = oMl.BinaryClassification.callMethod("Evaluate",[oCalibrated,"Label"])
	dnAssert(cCalibrator + ": the accuracy",oMetrics.Accuracy > 0.7,1)
	dnAssert(cCalibrator + ": the log loss is a number that is not too large (the noise is 10 percent of the rows)",oMetrics.LogLoss > 0 and oMetrics.LogLoss < 1,1)
next

# a calibrator is made for a classifier in a pipeline: the probability of the whole pipeline
oPipeline = oFeatures.callMethod("Append",[oMl.BinaryClassification.Trainers.callMethod("AveragedPerceptron",["Label","Features"])])
oPipeline = oPipeline.callMethod("Append",[oMl.BinaryClassification.Calibrators.callMethod("Platt",["Label"])])
oWhole = oPipeline.Fit(oData)
aWholeProbability = mlColumn(oWhole.Transform(oData),"System.Single","Probability")
dnAssert("a perceptron and a calibrator in one pipeline give a probability",len(aWholeProbability),400)
nPositive = 0
for nValue in aWholeProbability
	if nValue > 0.5
		nPositive++
	ok
next
dnAssert("about half of the rows are positive (the class is yes when F1 + F2 is above 10)",nPositive > 120 and nPositive < 280,1)
dnTestSummary()
