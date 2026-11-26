# ML.NET with any number of columns and no C# class for the dataset: a CSV file is read with column definitions made in Ring (TextLoader.Column), and the scores
# are read as a column of the scored data
load "mlcommon.ring"
mlUse()

oMl = mlNew(11)

# a CSV file with five numbers and a label: label = x1 + 2 * x2 - x3 + 0.5 * x4 + 3 * x5 + 2
cFile = mlFile("columns.csv")
cCsv = "x1,x2,x3,x4,x5,label" + nl
for a = 0 to 3
	for b = 0 to 3
		for c = 0 to 2
			for d = 0 to 2
				for e = 0 to 2
					cCsv += "" + a + "," + b + "," + c + "," + d + "," + e + "," + (a + 2 * b - c + 0.5 * d + 3 * e + 2) + nl
				next
			next
		next
	next
next
write(cFile,cCsv)

# the columns: a name, the kind of the number and the place in the line
aColumns = []
cNames = ["x1","x2","x3","x4","x5","label"]
for nColumn = 1 to len(cNames)
	aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",[cNames[nColumn],"Single",nColumn - 1])
next
oData = mlLoadCsv(oMl,cFile,aColumns)
dnAssert("the file was read",oData.getProp("Schema").getProp("Count"),6)

# the same pipeline as with classes, with five features
oPipeline = oMl.Transforms.callMethod("Concatenate",["Features",["x1","x2","x3","x4","x5"]])
oTrainer = oMl.Regression.Trainers.callMethod("Sdca",["label","Features"])
oModel = oPipeline.callMethod("Append",[oTrainer]).Fit(oData)
oScored = oModel.Transform(oData)
oMetrics = oMl.Regression.callMethod("Evaluate",[oScored,"label"])
dnAssert("R squared of the model",oMetrics.RSquared > 0.99,1)

# what the model learned: five weights
aWeights = oModel.LastTransformer.Model.Weights.toList()
dnAssert("five weights",len(aWeights),5)
aExpected = [1,2,-1,0.5,3]
lClose = 1
for n = 1 to 5
	if fabs(aWeights[n] - aExpected[n]) > 0.2
		lClose = 0
	ok
next
dnAssert("the weights are near 1, 2, -1, 0.5 and 3",lClose,1)

# the scores and the labels as columns, without a class
aScores = mlColumn(oScored,"System.Single","Score")
aLabels = mlColumn(oScored,"System.Single","label")
dnAssert("a score for each row",len(aScores),432)
dnAssert("a label for each row",len(aLabels),432)
nWorst = 0
for n = 1 to len(aScores)
	if fabs(aScores[n] - aLabels[n]) > nWorst
		nWorst = fabs(aScores[n] - aLabels[n])
	ok
next
dnAssert("the worst error is small",nWorst < 1,1)
dnTestSummary()
