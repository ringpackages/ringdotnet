# ML.NET: more regression trainers (ordinary least squares with the native MKL library, online gradient descent, Poisson regression, tweedie, additive models, gradient boosted
# trees), and the tools around them: a split into a train set and a test set, cross validation, and the importance of each feature; the data is a CSV file with three features
load "mlcommon.ring"
mlUse()

oMl = mlNew(51)

# 200 rows: label = 4 * a + 2 * b + 0.5 * c + 3, with features that do not depend on each other (a small number generator)
cCsv = "a,b,c,label" + nl
nSeed = 11
for n = 1 to 200
	nSeed = (nSeed * 75 + 74) % 65537
	a = nSeed % 10
	nSeed = (nSeed * 75 + 74) % 65537
	b = nSeed % 10
	nSeed = (nSeed * 75 + 74) % 65537
	c = nSeed % 10
	cCsv += "" + a + "," + b + "," + c + "," + (4 * a + 2 * b + 0.5 * c + 3) + nl
next
cFile = mlWrite("regressors.csv",cCsv)
aColumns = []
for n = 1 to 3
	aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",[char(96 + n),"Single",n - 1])
next
aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["label","Single",3])
oData = mlLoadCsv(oMl,cFile,aColumns)

# the features are joined; every trainer gets the same pipeline start
# the native MKL library (a Linux computer needs libiomp5 for it) is used by OLS: without it those checks are left out, and the test says so
lMkl = mklAvailable()
aTrainers = ["OnlineGradientDescent","FastTree","FastForest","Gam","LightGbm"]
if lMkl
	aTrainers + "Ols"
else
	? "NOTE: the MKL library is not available on this computer: the OLS checks are left out"
ok
for cTrainer in aTrainers
	aArguments = ["label","Features"]
	if cTrainer = "OnlineGradientDescent"
		aArguments = ["label","Features",dnNull(),0.1,1,0,50]          # the loss, the learning rate, decrease it, L2, the passes over the rows
	ok
	oChain = oMl.Transforms.callMethod("Concatenate",["Features",["a","b","c"]]).callMethod("Append",[oMl.Transforms.callMethod("NormalizeMeanVariance",["Features"])])
	oModel = oChain.callMethod("Append",[oMl.Regression.Trainers.callMethod(cTrainer,aArguments)]).Fit(oData)
	oMetrics = oMl.Regression.callMethod("Evaluate",[oModel.Transform(oData),"label"])
	dnAssert(cTrainer + ": R squared",oMetrics.RSquared > 0.9,1)
	dnAssert(cTrainer + ": the mean error is below the spread of the label",oMetrics.MeanAbsoluteError < 6,1)
next

if lMkl
	# ordinary least squares finds the exact line when the data is exact: the weights of the model on the original features
	oOls = oMl.Transforms.callMethod("Concatenate",["Features",["a","b","c"]]).callMethod("Append",[oMl.Regression.Trainers.callMethod("Ols",["label","Features"])]).Fit(oData)
	aWeights = oOls.LastTransformer.Model.Weights.toList()
	dnAssert("OLS: the weight of a is 4",fabs(aWeights[1] - 4) < 0.01,1)
	dnAssert("OLS: the weight of b is 2",fabs(aWeights[2] - 2) < 0.01,1)
	dnAssert("OLS: the weight of c is 0.5",fabs(aWeights[3] - 0.5) < 0.01,1)
	dnAssert("OLS: the bias is 3",fabs(oOls.LastTransformer.Model.Bias - 3) < 0.01,1)
	dnAssert("OLS: R squared is 1",oMl.Regression.callMethod("Evaluate",[oOls.Transform(oData),"label"]).RSquared > 0.9999,1)
ok

# a count that goes up with the features: Poisson regression
cCounts = "a,b,c,label" + nl
nSeed = 5
for n = 1 to 200
	nSeed = (nSeed * 75 + 74) % 65537
	a = nSeed % 5
	nSeed = (nSeed * 75 + 74) % 65537
	b = nSeed % 5
	cCounts += "" + a + "," + b + ",0," + (a + 2 * b) + nl
next
cCountsFile = mlWrite("counts.csv",cCounts)
oCounts = mlLoadCsv(oMl,cCountsFile,aColumns)
oPoisson = oMl.Transforms.callMethod("Concatenate",["Features",["a","b","c"]]).callMethod("Append",[oMl.Regression.Trainers.callMethod("LbfgsPoissonRegression",["label","Features"])]).Fit(oCounts)
dnAssert("Poisson regression: R squared for counts",oMl.Regression.callMethod("Evaluate",[oPoisson.Transform(oCounts),"label"]).RSquared > 0.8,1)
oTweedie = oMl.Transforms.callMethod("Concatenate",["Features",["a","b","c"]]).callMethod("Append",[oMl.Regression.Trainers.callMethod("FastTreeTweedie",["label","Features"])]).Fit(oCounts)
dnAssert("Tweedie trees: R squared for counts",oMl.Regression.callMethod("Evaluate",[oTweedie.Transform(oCounts),"label"]).RSquared > 0.8,1)

# a train set and a test set: the model is measured on rows it has not seen
oSplit = oMl.Data.callMethod("TrainTestSplit",[oData,0.25])
nTrain = len(mlColumn(oSplit.TrainSet,"System.Single","a"))
nTest = len(mlColumn(oSplit.TestSet,"System.Single","a"))
dnAssert("the two sets together are all the rows",nTrain + nTest,200)
dnAssert("the test set is about a quarter of them",nTest > 30 and nTest < 70,1)
oPipeline = oMl.Transforms.callMethod("Concatenate",["Features",["a","b","c"]])
oOnTrain = oPipeline.callMethod("Append",[oMl.Regression.Trainers.callMethod("FastTree",["label","Features"])]).Fit(oSplit.TrainSet)
dnAssert("the model fits rows it has not seen",oMl.Regression.callMethod("Evaluate",[oOnTrain.Transform(oSplit.TestSet),"label"]).RSquared > 0.9,1)

# cross validation: a model for each fold, and the metrics of each
aFolds = oMl.Regression.callMethod("CrossValidate",[oData,oPipeline.callMethod("Append",[oMl.Regression.Trainers.callMethod("FastTree",["label","Features"])]),4,"label"]).toList()
dnAssert("a result for each fold",len(aFolds),4)
lGood = 1
for oFold in aFolds
	if oFold.Metrics.RSquared < 0.9
		lGood = 0
	ok
next
dnAssert("every fold fits",lGood,1)

# the importance of each feature: shuffling a feature that matters costs more than shuffling one that matters less
oNormalized = oMl.Transforms.callMethod("Concatenate",["Features",["a","b","c"]]).callMethod("Fit",[oData])
oFeatureData = oNormalized.Transform(oData)
oLinear = oMl.Regression.Trainers.callMethod("FastTree",["label","Features"]).callMethod("Fit",[oFeatureData])
aImportance = oMl.Regression.callMethod("PermutationFeatureImportance",[oLinear,oFeatureData,"label",0,dnNull(),3]).toList()
aNames = []
aDrop = []
for oPair in aImportance
	aNames + oPair.Key
	aDrop + oPair.Value.getProp("RSquared").getProp("Mean")
next
dnAssert("an importance for each feature",len(aNames),3)
nA = aDrop[find(aNames,"a")]
nB = aDrop[find(aNames,"b")]
nC = aDrop[find(aNames,"c")]
dnAssert("the feature a (weight 4) matters more than b (weight 2): R squared falls lower when it is shuffled",nA < nB,1)
dnAssert("the feature b matters more than c (weight 0.5)",nB < nC,1)
dnTestSummary()

# 1 when the native MKL library can be loaded: OLS is fitted on a few rows
func mklAvailable

	cTiny = "a,b,c,label" + nl + "1,2,3,10" + nl + "2,1,0,7" + nl + "3,5,2,24" + nl + "4,2,1,18" + nl + "5,0,4,20" + nl + "0,3,3,11" + nl
	cTinyFile = mlFile("tiny.csv")
	write(cTinyFile,cTiny)
	aTiny = []
	for n = 1 to 3
		aTiny + dnNew("Microsoft.ML.Data.TextLoader+Column",[char(96 + n),"Single",n - 1])
	next
	aTiny + dnNew("Microsoft.ML.Data.TextLoader+Column",["label","Single",3])
	oTiny = mlLoadCsv(oMl,cTinyFile,aTiny)
	try
		oMl.Transforms.callMethod("Concatenate",["Features",["a","b","c"]]).callMethod("Append",[oMl.Regression.Trainers.callMethod("Ols",["label","Features"])]).Fit(oTiny)
	catch
		if substr(cCatchError,"MKL") > 0 or substr(cCatchError,"Mkl") > 0
			return 0
		ok
		raise(cCatchError)
	done
	return 1

