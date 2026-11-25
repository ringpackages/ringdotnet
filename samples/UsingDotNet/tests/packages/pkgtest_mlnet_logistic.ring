# ML.NET: logistic regression (a yes or no from two numbers) with two trainers, the metrics of a binary classifier, and the probability that a row gets
load "pkg.ring"
pkgUseProject("mlnet","helpers/MlHelpers",[["MlHelpers.dll",["MlHelpers"]],["Microsoft.ML.Data.dll",["Microsoft.ML","Microsoft.ML.Data"]],["Microsoft.ML.Core.dll",[]],["Microsoft.ML.StandardTrainers.dll",["Microsoft.ML.Trainers"]],["Microsoft.ML.Transforms.dll",[]],["Microsoft.ML.DataView.dll",[]],["Microsoft.ML.CpuMath.dll",[]],["Microsoft.ML.FastTree.dll",[]],["Microsoft.ML.KMeansClustering.dll",[]],["Microsoft.ML.PCA.dll",[]]])
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML")
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML.Data")
pkgImport("mlnet","MlHelpers.dll","MlHelpers")
pkgImport("mlnet","Microsoft.ML.StandardTrainers.dll","Microsoft.ML.Trainers")

oMl = dnNew("Microsoft.ML.MLContext",[1])

# the class is yes when F1 + F2 is above 10; the rows are on a grid, so the classes are separated by a line
oRows = dnNew("System.Collections.Generic.List`1[[MlHelpers.ClassRow, MlHelpers]]",[])
for x = 0 to 10
	for y = 0 to 10
		if x + y != 10
			oRow = new ClassRow()
			oRow.F1 = x
			oRow.F2 = y
			oRow.Label = (x + y > 10)
			oRows.Add(oRow)
		ok
	next
next
dnAssert("the rows (the grid without the points on the line)",oRows.Count,110)
oData = oMl.Data.callGeneric("LoadFromEnumerable",["MlHelpers.ClassRow"],[oRows])

for cTrainer in ["SdcaLogisticRegression","LbfgsLogisticRegression"]
	oPipeline = oMl.Transforms.callMethod("Concatenate",["Features",["F1","F2"]])
	oTrainer = oMl.BinaryClassification.Trainers.callMethod(cTrainer,["Label","Features"])
	oModel = oPipeline.callMethod("Append",[oTrainer]).Fit(oData)
	oMetrics = oMl.BinaryClassification.Evaluate(oModel.Transform(oData))
	dnAssert(cTrainer + ": the accuracy is high",oMetrics.Accuracy > 0.9,1)
	dnAssert(cTrainer + ": the area under the curve is near 1",oMetrics.AreaUnderRocCurve > 0.97,1)
	dnAssert(cTrainer + ": the F1 score",oMetrics.F1Score > 0.9,1)
	dnAssert(cTrainer + ": the precision and the recall",oMetrics.PositivePrecision > 0.85 and oMetrics.PositiveRecall > 0.85,1)

	oEngine = oMl.Model.callGeneric("CreatePredictionEngine",["MlHelpers.ClassRow","MlHelpers.ClassPrediction"],[oModel])
	oHigh = new ClassRow()
	oHigh.F1 = 9
	oHigh.F2 = 9
	oLow = new ClassRow()
	oLow.F1 = 1
	oLow.F2 = 2
	oYes = oEngine.callMethod("Predict",[oHigh])
	oNo = oEngine.callMethod("Predict",[oLow])
	dnAssert(cTrainer + ": a high row is yes",oYes.PredictedLabel,1)
	dnAssert(cTrainer + ": a low row is no",oNo.PredictedLabel,0)
	dnAssert(cTrainer + ": a probability above a half for yes",oYes.Probability > 0.9,1)
	dnAssert(cTrainer + ": a probability below a half for no",oNo.Probability < 0.1,1)
	dnAssert(cTrainer + ": the probability is between 0 and 1",oYes.Probability <= 1 and oNo.Probability >= 0,1)
next

# the confusion matrix of the last model: the counts of the four cases add up to the number of rows
oMatrix = oMetrics.ConfusionMatrix
dnAssert("the counts of the matrix add up to the rows",oMatrix.Counts.toList()[1].toList()[1] + oMatrix.Counts.toList()[1].toList()[2] + oMatrix.Counts.toList()[2].toList()[1] + oMatrix.Counts.toList()[2].toList()[2],110)
dnTestSummary()
