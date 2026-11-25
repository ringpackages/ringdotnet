# ML.NET: decision trees (FastTree and FastForest) for a number and for a yes or no; a tree learns a step that a straight line can not: the label is 10 when F1
# is below 5 and 20 when it is not
load "pkg.ring"
pkgUseProject("mlnet","helpers/MlHelpers",[["MlHelpers.dll",["MlHelpers"]],["Microsoft.ML.Data.dll",["Microsoft.ML","Microsoft.ML.Data"]],["Microsoft.ML.Core.dll",[]],["Microsoft.ML.StandardTrainers.dll",["Microsoft.ML.Trainers"]],["Microsoft.ML.Transforms.dll",[]],["Microsoft.ML.DataView.dll",[]],["Microsoft.ML.CpuMath.dll",[]],["Microsoft.ML.FastTree.dll",[]],["Microsoft.ML.KMeansClustering.dll",[]],["Microsoft.ML.PCA.dll",[]]])
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML")
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML.Data")
pkgImport("mlnet","MlHelpers.dll","MlHelpers")

oMl = dnNew("Microsoft.ML.MLContext",[3])
oRows = dnNew("System.Collections.Generic.List`1[[MlHelpers.RegressionRow, MlHelpers]]",[])
for x = 0 to 9
	for y = 0 to 5
		oRow = new RegressionRow()
		oRow.F1 = x
		oRow.F2 = y
		if x < 5
			oRow.Label = 10
		else
			oRow.Label = 20
		ok
		oRows.Add(oRow)
	next
next
oData = oMl.Data.callGeneric("LoadFromEnumerable",["MlHelpers.RegressionRow"],[oRows])

for cTrainer in ["FastTree","FastForest"]
	oChain = oMl.Transforms.callMethod("Concatenate",["Features",["F1","F2"]]).callMethod("Append",[oMl.Regression.Trainers.callMethod(cTrainer,["Label","Features"])])
	oModel = oChain.Fit(oData)
	oEngine = oMl.Model.callGeneric("CreatePredictionEngine",["MlHelpers.RegressionRow","MlHelpers.RegressionPrediction"],[oModel])
	oLow = new RegressionRow()
	oLow.F1 = 1
	oLow.F2 = 3
	oHigh = new RegressionRow()
	oHigh.F1 = 8
	oHigh.F2 = 3
	nLow = oEngine.callMethod("Predict",[oLow]).Score
	nHigh = oEngine.callMethod("Predict",[oHigh]).Score
	dnAssert(cTrainer + ": a row below the step is near 10",fabs(nLow - 10) < 2,1)
	dnAssert(cTrainer + ": a row above the step is near 20",fabs(nHigh - 20) < 2,1)
	dnAssert(cTrainer + ": the metrics say the step was learned",oMl.Regression.Evaluate(oModel.Transform(oData)).RSquared > 0.9,1)
next

# a straight line can not learn the step as well as the tree does
oLine = oMl.Transforms.callMethod("Concatenate",["Features",["F1","F2"]]).callMethod("Append",[oMl.Regression.Trainers.callMethod("Sdca",["Label","Features"])]).Fit(oData)
nLineR2 = oMl.Regression.Evaluate(oLine.Transform(oData)).RSquared
dnAssert("the line fits the step worse than the tree",nLineR2 < 0.95,1)

# classification trees: the class is yes when F1 is 5 or more and F2 is 3 or more (a rule of two splits)
oClassRows = dnNew("System.Collections.Generic.List`1[[MlHelpers.ClassRow, MlHelpers]]",[])
for x = 0 to 9
	for y = 0 to 5
		oClassRow = new ClassRow()
		oClassRow.F1 = x
		oClassRow.F2 = y
		oClassRow.Label = (x >= 5 and y >= 3)
		oClassRows.Add(oClassRow)
	next
next
oClassData = oMl.Data.callGeneric("LoadFromEnumerable",["MlHelpers.ClassRow"],[oClassRows])
oClassModel = oMl.Transforms.callMethod("Concatenate",["Features",["F1","F2"]]).callMethod("Append",[oMl.BinaryClassification.Trainers.callMethod("FastTree",["Label","Features"])]).Fit(oClassData)
oMetrics = oMl.BinaryClassification.Evaluate(oClassModel.Transform(oClassData))
dnAssert("the tree learns a rule of two splits",oMetrics.Accuracy > 0.95,1)
oClassEngine = oMl.Model.callGeneric("CreatePredictionEngine",["MlHelpers.ClassRow","MlHelpers.ClassPrediction"],[oClassModel])
oYes = new ClassRow()
oYes.F1 = 8
oYes.F2 = 5
oNoLeft = new ClassRow()
oNoLeft.F1 = 2
oNoLeft.F2 = 5
oNoBelow = new ClassRow()
oNoBelow.F1 = 8
oNoBelow.F2 = 1
dnAssert("both conditions give yes",oClassEngine.callMethod("Predict",[oYes]).PredictedLabel,1)
dnAssert("F1 below 5 gives no",oClassEngine.callMethod("Predict",[oNoLeft]).PredictedLabel,0)
dnAssert("F2 below 3 gives no",oClassEngine.callMethod("Predict",[oNoBelow]).PredictedLabel,0)
dnTestSummary()
