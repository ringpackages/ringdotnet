# ML.NET anomaly detection: RandomizedPca learns what normal rows look like from rows that are almost all normal (no labels); a row that is far from the normal ones gets a high
# score and the label "anomaly". The labels of the test rows are used only to measure the detector.
load "mlcommon.ring"
mlUse()

oMl = mlNew(17)

# normal rows: points near the line F2 = 2 * F1 (with a small shift), 120 of them; the rows to test: 20 normal ones and 6 far from the line
cTrain = "F1,F2,F3" + nl
nSeed = 9
for n = 1 to 120
	nSeed = (nSeed * 75 + 74) % 65537
	nT = nSeed % 100 / 10
	nSeed = (nSeed * 75 + 74) % 65537
	nNoise = (nSeed % 21 - 10) / 20
	cTrain += "" + nT + "," + (2 * nT + nNoise) + "," + (nT + nNoise) + nl
next
cTrainFile = mlWrite("anomaly_train.csv",cTrain)
oTrain = mlLoadCsv(oMl,cTrainFile,mlColumns([["F1","Single"],["F2","Single"],["F3","Single"]]))

cTest = "F1,F2,F3,Label" + nl
for n = 1 to 20
	nSeed = (nSeed * 75 + 74) % 65537
	nT = nSeed % 100 / 10
	nSeed = (nSeed * 75 + 74) % 65537
	nNoise = (nSeed % 21 - 10) / 20
	cTest += "" + nT + "," + (2 * nT + nNoise) + "," + (nT + nNoise) + ",0" + nl
next
aOutliers = [ [5,0,9], [2,20,0], [9,1,1], [0,0,15], [7,30,2], [1,-10,8] ]
for aPoint in aOutliers
	cTest += "" + aPoint[1] + "," + aPoint[2] + "," + aPoint[3] + ",1" + nl
next
aTestColumns = mlColumns([["F1","Single"],["F2","Single"],["F3","Single"],["Label","Single"]])
oTest = mlLoadCsv(oMl,mlWrite("anomaly_test.csv",cTest),aTestColumns)

# the detector: the features are joined, and the trainer keeps 2 components of the rows
oPipeline = oMl.Transforms.callMethod("Concatenate",["Features",["F1","F2","F3"]])
oTrainer = oMl.AnomalyDetection.Trainers.callMethod("RandomizedPca",["Features",dnNull(),2])
oModel = oPipeline.callMethod("Append",[oTrainer]).Fit(oTrain)
oScored = oModel.Transform(oTest)
aScores = mlColumn(oScored,"System.Single","Score")
dnAssert("a score for each row",len(aScores),26)

# the outliers (the last 6 rows) score higher than every normal row
nHighestNormal = 0
for n = 1 to 20
	if aScores[n] > nHighestNormal
		nHighestNormal = aScores[n]
	ok
next
nLowestOutlier = aScores[21]
for n = 21 to 26
	if aScores[n] < nLowestOutlier
		nLowestOutlier = aScores[n]
	ok
next
dnAssert("every outlier scores higher than every normal row",nLowestOutlier > nHighestNormal,1)

# the labels that the detector gives (true for an anomaly): the outliers are found
aPredicted = mlColumn(oScored,"System.Boolean","PredictedLabel")
nFound = 0
for n = 21 to 26
	nFound += aPredicted[n]
next
dnAssert("most of the outliers get the label of an anomaly",nFound >= 4,1)
nFalse = 0
for n = 1 to 20
	nFalse += aPredicted[n]
next
dnAssert("few normal rows are called anomalies",nFalse <= 4,1)

# the metrics of the detector, measured with the labels of the test rows
oMetrics = oMl.AnomalyDetection.callMethod("Evaluate",[oScored,"Label"])
dnAssert("the area under the curve is near 1",oMetrics.AreaUnderRocCurve > 0.95,1)
dnAssert("the detection rate at the first false positives",oMetrics.DetectionRateAtFalsePositiveCount >= 0.5,1)

# the same detector with another number of components, and the same scores with the same data
oOne = oPipeline.callMethod("Append",[oMl.AnomalyDetection.Trainers.callMethod("RandomizedPca",["Features",dnNull(),1])]).Fit(oTrain)
aOneScores = mlColumn(oOne.Transform(oTest),"System.Single","Score")
dnAssert("a detector with one component also scores every row",len(aOneScores),26)
dnAssert("and also puts the outliers above the normal rows",aOneScores[22] > aOneScores[5],1)
dnTestSummary()
