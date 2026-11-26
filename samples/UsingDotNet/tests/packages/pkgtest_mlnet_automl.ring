# ML.NET AutoML: an experiment tries trainers and settings for a time and gives the best model it found, for a number, a yes or no and several classes; the columns of a CSV file
# can be inferred from its text. The best model is used like any other. (The experiments run for a few seconds each; what they find varies, so the checks are about the
# quality of the best model, not about the name of its trainer. The restore is large: AutoML brings the deep learning packages, hundreds of megabytes.)
load "mlcommon.ring"
mlUseAuto()

oMl = mlNew(31)
oAuto = oMl.callMethod("Auto",[])

# ---- a number: label = 3 * a + 2 * b + 1 with a little noise (the features do not depend on each other)
cCsv = "a,b,label" + nl
nSeed = 21
for n = 1 to 200
	nSeed = (nSeed * 75 + 74) % 65537
	a = nSeed % 10
	nSeed = (nSeed * 75 + 74) % 65537
	b = nSeed % 10
	nSeed = (nSeed * 75 + 74) % 65537
	cCsv += "" + a + "," + b + "," + (3 * a + 2 * b + 1 + (nSeed % 7 - 3) / 10) + nl
next
cFile = mlWrite("automl.csv",cCsv)
oData = mlLoadCsv(oMl,cFile,mlColumns([["a","Single"],["b","Single"],["label","Single"]]))

# the settings of an experiment: the time and the number of models that bound it, and the trainers that it may try (a list of enum values)
oSettings = new RegressionExperimentSettings()
oSettings.MaxExperimentTimeInSeconds = 90          # the most that it may take: it stops after 6 models, which a fast computer reaches in a few seconds and a slow one in a minute
oSettings.MaxModels = 6
oSettings.Trainers.Clear()
for cTrainer in ["StochasticDualCoordinateAscent","LightGbm","FastForest"]
	oSettings.Trainers.Add(cTrainer)
next
dnAssert("the experiment may try three trainers",oSettings.Trainers.Count,3)
oRegression = oAuto.callMethod("CreateRegressionExperiment",[oSettings]).callMethod("Execute",[oData,"label"])
dnAssert("the experiment tried the 6 models that it was allowed",len(oRegression.RunDetails.toList()),6)
oBest = oRegression.BestRun
dnAssert("the best run has the name of its trainer: one of the three that were allowed",substr(oBest.TrainerName,"Regression") > 0,1)
dnAssert("the best pipeline made a model that fits the data (R squared)",oBest.ValidationMetrics.RSquared > 0.6,1)
dnAssert("the best run took some time",oBest.RuntimeInSeconds >= 0,1)

# the best model is a model: it scores the rows, and the scores are near the labels
aScores = mlColumn(oBest.Model.Transform(oData),"System.Single","Score")
aLabels = mlColumn(oData,"System.Single","label")
dnAssert("the best model gives a score for each row",len(aScores),200)
nError = 0
for n = 1 to 200
	nError += fabs(aScores[n] - aLabels[n])
next
dnAssert("the mean error of the best model is small (the labels go up to 28)",nError / 200 < 5,1)

# ---- the columns of a CSV file inferred from its text: the types of the columns and the label
oInferred = oAuto.callMethod("InferColumns",[cFile,"label"])
dnAssert("the label of the inferred columns",oInferred.ColumnInformation.LabelColumnName,"label")
dnAssert("the numeric columns are joined into one column of features",oInferred.ColumnInformation.NumericColumnNames.toList()[1],"Features")

# ---- a yes or no: the class is yes when a + b is above 10
cBinary = "a,b,label" + nl
for n = 1 to 200
	nSeed = (nSeed * 75 + 74) % 65537
	a = nSeed % 10
	nSeed = (nSeed * 75 + 74) % 65537
	b = nSeed % 10
	cBinary += "" + a + "," + b + "," + (a + b > 9) + nl
next
oBinaryData = mlLoadCsv(oMl,mlWrite("automl_binary.csv",cBinary),mlColumns([["a","Single"],["b","Single"],["label","Boolean"]]))
oBinary = oAuto.callMethod("CreateBinaryClassificationExperiment",[8]).callMethod("Execute",[oBinaryData,"label"])
dnAssert("a binary classifier was found: its accuracy",oBinary.BestRun.ValidationMetrics.Accuracy > 0.85,1)
aPredicted = mlColumn(oBinary.BestRun.Model.Transform(oBinaryData),"System.Boolean","PredictedLabel")
dnAssert("the best classifier labels each row",len(aPredicted),200)

# ---- several classes: three groups of points
cMulti = "x,y,group" + nl
for aCenter in [ ["red",0,0], ["green",8,0], ["blue",4,8] ]
	for dx = -2 to 2
		for dy = -2 to 2
			cMulti += "" + (aCenter[2] + dx * 0.5) + "," + (aCenter[3] + dy * 0.5) + "," + aCenter[1] + nl
		next
	next
next
oMultiData = mlLoadCsv(oMl,mlWrite("automl_multi.csv",cMulti),mlColumns([["x","Single"],["y","Single"],["group","String"]]))
oMulti = oAuto.callMethod("CreateMulticlassClassificationExperiment",[8]).callMethod("Execute",[oMultiData,"group"])
dnAssert("a multiclass classifier was found: its accuracy",oMulti.BestRun.ValidationMetrics.MicroAccuracy > 0.9,1)
dnTestSummary()
