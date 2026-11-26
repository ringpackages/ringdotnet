# ML.NET with row classes that Ring defines while it runs: System.Reflection.Emit makes a type with the fields of the table (numbers, a text, a yes/no), the bridge finds the
# new type by its name, and the rest is the same as with a class in C#: List<T>, LoadFromEnumerable<T>, a pipeline, a prediction engine. No helper project is needed for the rows.
load "pkg.ring"
pkgUseProject("mlnet","helpers/MlHelpers",[["MlHelpers.dll",["MlHelpers"]],["Microsoft.ML.Data.dll",["Microsoft.ML","Microsoft.ML.Data"]],["Microsoft.ML.Core.dll",[]],["Microsoft.ML.StandardTrainers.dll",["Microsoft.ML.Trainers"]],["Microsoft.ML.Transforms.dll",[]],["Microsoft.ML.DataView.dll",[]],["Microsoft.ML.CpuMath.dll",[]],["Microsoft.ML.FastTree.dll",[]],["Microsoft.ML.KMeansClustering.dll",[]],["Microsoft.ML.PCA.dll",[]]])
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML")
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML.Data")
pkgImport("mlnet","Microsoft.ML.StandardTrainers.dll","Microsoft.ML.Trainers")

oMl = dnNew("Microsoft.ML.MLContext",[31])
oModule = dnStatic("System.Reflection.Emit.AssemblyBuilder","DefineDynamicAssembly",[dnNew("System.Reflection.AssemblyName",["RingRows"]),"Run"]).callMethod("DefineDynamicModule",["RingRows"])

# ---- a class with three numbers and a label, defined at run time
oSales = defineClass("SalesRow",[ ["Tv","System.Single"], ["Radio","System.Single"], ["Web","System.Single"], ["Label","System.Single"] ])
dnAssert("the class was made",oSales.FullName,"SalesRow")
dnAssert("it has four fields",len(oSales.GetFields(NULL).toList()),4)
oFirst = newRow(oSales,[1,2,3,4])
dnAssert("a field of an object of the new class",oSales.GetField("Radio").callMethod("GetValue",[oFirst]),2)
dnAssert("the bridge finds the new class by its name",dnType("SalesRow").typeName(),"SalesRow")

# the rows: Label = 3 * Tv + 2 * Radio + 0.5 * Web + 5
oRows = dnNew("System.Collections.Generic.List`1[[SalesRow]]",[])
for tv = 0 to 5
	for radio = 0 to 5
		for web = 0 to 3
			oRows.Add(newRow(oSales,[tv,radio,web,3 * tv + 2 * radio + 0.5 * web + 5]))
		next
	next
next
dnAssert("the rows",oRows.Count,144)
oData = oMl.Data.callGeneric("LoadFromEnumerable",["SalesRow"],[oRows])
dnAssert("four columns in the data",oData.getProp("Schema").getProp("Count"),4)
oChain = oMl.Transforms.callMethod("Concatenate",["Features",["Tv","Radio","Web"]]).callMethod("Append",[oMl.Regression.Trainers.callMethod("Sdca",["Label","Features"])])
oModel = oChain.Fit(oData)
dnAssert("a model trained on a class that was made at run time",oMl.Regression.Evaluate(oModel.Transform(oData)).RSquared > 0.99,1)
aWeights = oModel.LastTransformer.Model.Weights.toList()
dnAssert("the weight of Tv is near 3",fabs(aWeights[1] - 3) < 0.3,1)
dnAssert("the weight of Radio is near 2",fabs(aWeights[2] - 2) < 0.3,1)
dnAssert("the weight of Web is near 0.5",fabs(aWeights[3] - 0.5) < 0.3,1)

# a prediction engine needs a class for the answer: a second class with a field named Score (the name of the column)
oPrediction = defineClass("SalesPrediction",[ ["Score","System.Single"] ])
oEngine = oMl.Model.callGeneric("CreatePredictionEngine",["SalesRow","SalesPrediction"],[oModel])
oQuery = newRow(oSales,[4,1,2,0])
oAnswer = oEngine.callMethod("Predict",[oQuery])
dnAssert("the prediction for 4, 1, 2 (3*4 + 2*1 + 0.5*2 + 5 = 20)",fabs(oPrediction.GetField("Score").callMethod("GetValue",[oAnswer]) - 20) < 1.5,1)

# ---- a class that mixes a text, a number and a yes/no: the case that needed a C# class before
oMixed = defineClass("ReviewRow",[ ["Review","System.String"], ["City","System.String"], ["Stars","System.Single"], ["Label","System.Boolean"] ])
aGood = ["great","good","love","excellent","wonderful"]
aBad = ["bad","awful","hate","terrible","horrible"]
oReviews = dnNew("System.Collections.Generic.List`1[[ReviewRow]]",[])
for cThing in ["service","food","room","price","staff"]
	for n = 1 to 5
		oReviews.Add(newRow(oMixed,["the " + cThing + " was " + aGood[n],"Cairo",4 + n % 2,1]))
		oReviews.Add(newRow(oMixed,["the " + cThing + " was " + aBad[n],"Lima",1 + n % 2,0]))
	next
next
dnAssert("the reviews",oReviews.Count,50)
oReviewData = oMl.Data.callGeneric("LoadFromEnumerable",["ReviewRow"],[oReviews])
oPipeline = oMl.Transforms.Text.callMethod("FeaturizeText",["ReviewFeatures","Review"])
oPipeline = oPipeline.callMethod("Append",[oMl.Transforms.Categorical.callMethod("OneHotEncoding",["CityEncoded","City"])])
oPipeline = oPipeline.callMethod("Append",[oMl.Transforms.callMethod("Concatenate",["Features",["ReviewFeatures","CityEncoded","Stars"]])])
oReviewModel = oPipeline.callMethod("Append",[oMl.BinaryClassification.Trainers.callMethod("SdcaLogisticRegression",["Label","Features"])]).Fit(oReviewData)
oMetrics = oMl.BinaryClassification.Evaluate(oReviewModel.Transform(oReviewData))
dnAssert("the sentiment model learned from the class with a text, a number and a yes/no",oMetrics.Accuracy > 0.95,1)
oReviewAnswer = defineClass("ReviewAnswer",[ ["PredictedLabel","System.Boolean"], ["Probability","System.Single"] ])
oReviewEngine = oMl.Model.callGeneric("CreatePredictionEngine",["ReviewRow","ReviewAnswer"],[oReviewModel])
oPositive = oReviewEngine.callMethod("Predict",[newRow(oMixed,["the view was wonderful","Cairo",5,0])])
oNegative = oReviewEngine.callMethod("Predict",[newRow(oMixed,["the view was horrible","Lima",1,0])])
dnAssert("a wonderful review is positive",oReviewAnswer.GetField("PredictedLabel").callMethod("GetValue",[oPositive]),1)
dnAssert("a horrible review is negative",oReviewAnswer.GetField("PredictedLabel").callMethod("GetValue",[oNegative]),0)
dnAssert("the probability of the positive one",oReviewAnswer.GetField("Probability").callMethod("GetValue",[oPositive]) > 0.5,1)

# ---- a width that is decided while the program runs: the fields come from a list of names
aNames = ["a","b","c","d","e","f","g"]
aFields = []
for cName in aNames
	aFields + [cName,"System.Single"]
next
aFields + ["Label","System.Single"]
oWide = defineClass("WideRow",aFields)
dnAssert("a class of eight fields made from a list",len(oWide.GetFields(NULL).toList()),8)
oWideRows = dnNew("System.Collections.Generic.List`1[[WideRow]]",[])
nSeed = 7          # a small generator of numbers (the features must not depend on each other, or a straight line does not fit)
for n = 1 to 120
	aValues = []
	nLabel = 0
	for m = 1 to 7
		nSeed = (nSeed * 75 + 74) % 65537
		nValue = nSeed % 10
		aValues + nValue
		nLabel += m * nValue
	next
	aValues + nLabel
	oWideRows.Add(newRow(oWide,aValues))
next
oWideData = oMl.Data.callGeneric("LoadFromEnumerable",["WideRow"],[oWideRows])
oWideModel = oMl.Transforms.callMethod("Concatenate",["Features",aNames]).callMethod("Append",[oMl.Regression.Trainers.callMethod("Sdca",["Label","Features",dnNull(),dnNull(),dnNull(),1000])]).Fit(oWideData)
dnAssert("a model with seven features from a class made from a list",oMl.Regression.Evaluate(oWideModel.Transform(oWideData)).RSquared > 0.95,1)

# a type name that exists already is an error of .NET
cError = ""
try
	defineClass("SalesRow",[ ["X","System.Single"] ])
catch
	cError = cCatchError
done
dnAssert("a type name that exists is an error",len(cError) > 0,1)
dnTestSummary()

# a class of public fields; the type of each is given by its name
func defineClass cName, aFields

	oBuilder = oModule.callMethod("DefineType",[cName,"Public"])
	for aField in aFields
		oBuilder.callMethod("DefineField",[aField[1],dnStatic("System.Type","GetType",[aField[2]]),"Public"])
	next
	oBuilder.callMethod("DefineDefaultConstructor",["Public"])
	return oBuilder.callMethod("CreateType",[])

# an object of the class with the values in the order of the fields; a number is converted to the type of its field
func newRow oType, aValues

	oRow = dnStatic("System.Activator","CreateInstance",[oType])
	aFields = oType.GetFields(NULL).toList()
	for n = 1 to len(aValues)
		cType = aFields[n].FieldType.FullName
		xValue = aValues[n]
		if cType = "System.Single"
			xValue = dnBox("System.Single",xValue)
		but cType = "System.Boolean"
			xValue = dnBox("System.Boolean",xValue)
		ok
		aFields[n].callMethod("SetValue",[oRow,xValue])
	next
	return oRow
