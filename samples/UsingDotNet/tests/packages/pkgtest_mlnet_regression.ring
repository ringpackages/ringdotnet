# ML.NET: linear regression trained from rows made in Ring (the row classes are in a helper project); the pipeline, the trainer, the model and its metrics are
# .NET objects, and the generic methods (LoadFromEnumerable<T>, CreatePredictionEngine<TIn,TOut>) get their type arguments from Ring
load "mlcommon.ring"
mlUse()

oMl = mlNew(42)
dnAssert("a context with a seed",oMl.typeName(),"Microsoft.ML.MLContext")

# 40 rows of Label = 2 * F1 + 3 * F2 + 1
oRows = dnNew("System.Collections.Generic.List`1[[MlHelpers.RegressionRow, MlHelpers]]",[])
for x = 1 to 8
	for y = 1 to 5
		oRow = new RegressionRow()
		oRow.F1 = x
		oRow.F2 = y
		oRow.Label = 2 * x + 3 * y + 1
		oRows.Add(oRow)
	next
next
dnAssert("the rows",oRows.Count,40)
oData = oMl.Data.callGeneric("LoadFromEnumerable",["MlHelpers.RegressionRow"],[oRows])
dnAssert("the data has two columns of features and a label",oData.getProp("Schema").getProp("Count"),3)
oPipeline = oMl.Transforms.callMethod("Concatenate",["Features",["F1","F2"]])
oTrainer = oMl.Regression.Trainers.callMethod("Sdca",["Label","Features"])
oChain = oPipeline.callMethod("Append",[oTrainer])
oModel = oChain.Fit(oData)
dnAssert("the model was trained",oModel.typeName() != "",1)

# how well it fits the rows
oMetrics = oMl.Regression.Evaluate(oModel.Transform(oData))
dnAssert("R squared is close to 1",oMetrics.RSquared > 0.99,1)
dnAssert("the mean error is small",oMetrics.MeanAbsoluteError < 1,1)
dnAssert("the error of a model is not negative",oMetrics.RootMeanSquaredError >= 0,1)

# what it learned: the weights are near 2 and 3, and the bias near 1
oParameters = oModel.LastTransformer.Model
aWeights = oParameters.Weights.toList()
dnAssert("two weights",len(aWeights),2)
dnAssert("the weight of F1 is near 2",fabs(aWeights[1] - 2) < 0.2,1)
dnAssert("the weight of F2 is near 3",fabs(aWeights[2] - 3) < 0.2,1)
dnAssert("the bias is near 1",fabs(oParameters.Bias - 1) < 0.5,1)

# a prediction of a row that was not in the data (the engine is made with the types of the row and of the prediction)
oEngine = oMl.Model.callGeneric("CreatePredictionEngine",["MlHelpers.RegressionRow","MlHelpers.RegressionPrediction"],[oModel])
oNew = new RegressionRow()
oNew.F1 = 10
oNew.F2 = 4
dnAssert("the prediction for F1 = 10 and F2 = 4 is near 33",fabs(oEngine.callMethod("Predict",[oNew]).Score - 33) < 1.5,1)
oOther = new RegressionRow()
oOther.F1 = 0
oOther.F2 = 0
dnAssert("the prediction for zero is near the bias",fabs(oEngine.callMethod("Predict",[oOther]).Score - 1) < 1.5,1)

# the same model through the Transform of a data view made from new rows
oNewRows = dnNew("System.Collections.Generic.List`1[[MlHelpers.RegressionRow, MlHelpers]]",[])
oNewRows.Add(oNew)
oNewRows.Add(oOther)
oPredicted = oModel.Transform(oMl.Data.callGeneric("LoadFromEnumerable",["MlHelpers.RegressionRow"],[oNewRows]))
aScores = oMl.Data.callGeneric("CreateEnumerable",["MlHelpers.RegressionPrediction",],[oPredicted,0]).toList()
dnAssert("a score for each new row",len(aScores),2)
dnAssert("the first score",fabs(aScores[1].Score - 33) < 1.5,1)

# a model trained with another seed learns the same line
oOther2 = mlNew(7)
oData2 = oOther2.Data.callGeneric("LoadFromEnumerable",["MlHelpers.RegressionRow"],[oRows])
oModel2 = oOther2.Transforms.callMethod("Concatenate",["Features",["F1","F2"]]).callMethod("Append",[oOther2.Regression.Trainers.callMethod("Sdca",["Label","Features"])]).Fit(oData2)
dnAssert("another seed gives a model of the same quality",oOther2.Regression.Evaluate(oModel2.Transform(oData2)).RSquared > 0.99,1)

# a column that does not exist is an error
cError = ""
try
	oMl.Transforms.callMethod("Concatenate",["Features",["F1","Nope"]]).Fit(oData)
catch
	cError = cCatchError
done
dnAssert("a missing column is an error",len(cError) > 0,1)
dnTestSummary()
