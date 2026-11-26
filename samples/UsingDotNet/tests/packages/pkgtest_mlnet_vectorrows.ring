# ML.NET with rows in memory and any number of features, with one row class for every dataset (VectorRow has a Features vector; its length is set by a SchemaDefinition
# that Ring makes), so a new table needs no new C# class
load "mlcommon.ring"
mlUse()

oMl = mlNew(13)

# a table of 4 features: label = 2 * a - b + 0.5 * c + 4 * d + 1
aTable4 = []
for a = 0 to 3
	for b = 0 to 3
		for c = 0 to 3
			for d = 0 to 2
				aTable4 + [ [a,b,c,d], 2 * a - b + 0.5 * c + 4 * d + 1 ]
			next
		next
	next
next
oModel4 = trainLine(aTable4,4)
dnAssert("a model with four features",oModel4[2].RSquared > 0.99,1)
aWeights = oModel4[1].Model.Weights.toList()
dnAssert("four weights",len(aWeights),4)
dnAssert("the weight of the last feature is near 4",fabs(aWeights[4] - 4) < 0.3,1)
dnAssert("the weight of the second is near -1",fabs(aWeights[2] + 1) < 0.3,1)

# the same classes with a table of 2 features
aTable2 = []
for a = 0 to 9
	for b = 0 to 9
		aTable2 + [ [a,b], 5 * a + b ]
	next
next
oModel2 = trainLine(aTable2,2)
dnAssert("a model with two features, from the same row class",oModel2[2].RSquared > 0.99,1)

# a prediction for a row that was not in the data: the engine gets the schema of the input
oSchema = vectorSchema(4)
oEngine = oMl.Model.callGeneric("CreatePredictionEngine",["MlHelpers.VectorRow","MlHelpers.VectorPrediction"],[oModel4[1],1,oSchema])
oNew = new VectorRow()
oNew.Features = [3,1,2,2]
dnAssert("the prediction of a row (2*3 - 1 + 0.5*2 + 4*2 + 1 = 15)",fabs(oEngine.callMethod("Predict",[oNew]).Score - 15) < 1.5,1)

# the features of a row are a list again when they are read
dnAssert("the features of a row are read back",oNew.Features.toList()[4],2)
dnAssert("a row with a feature of the wrong length is not accepted by the engine",rowLengthError(oEngine,[1,2]) != "",1)
dnTestSummary()

# the schema of a row class with a Features vector of n numbers
func vectorSchema nFeatures

	oSchema = dnStatic("Microsoft.ML.Data.SchemaDefinition","Create",[dnType("MlHelpers.VectorRow")])
	oSingle = dnStatic("Microsoft.ML.Data.NumberDataViewType","get_Single",[])
	oSchema.Item("Features").ColumnType = dnNew("Microsoft.ML.Data.VectorDataViewType",[oSingle,nFeatures])
	return oSchema

# a table is a list of [ [features...], label ]; the answer is [the model, its metrics]
func trainLine aTable, nFeatures

	oRows = dnNew("System.Collections.Generic.List`1[[MlHelpers.VectorRow, MlHelpers]]",[])
	for aItem in aTable
		oRow = new VectorRow()
		oRow.Features = aItem[1]
		oRow.Label = aItem[2]
		oRows.Add(oRow)
	next
	oData = oMl.Data.callGeneric("LoadFromEnumerable",["MlHelpers.VectorRow"],[oRows,vectorSchema(nFeatures)])
	oModel = oMl.Regression.Trainers.callMethod("Sdca",["Label","Features"])
	oFit = oModel.Fit(oData)
	oMetrics = oMl.Regression.Evaluate(oFit.Transform(oData))
	return [oFit,oMetrics]

func rowLengthError oEngine, aFeatures

	oRow = new VectorRow()
	oRow.Features = aFeatures
	cError = ""
	try
		oEngine.callMethod("Predict",[oRow])
	catch
		cError = cCatchError
	done
	return cError
