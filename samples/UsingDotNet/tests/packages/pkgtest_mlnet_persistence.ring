# ML.NET: a trained model saved to a file or to a stream and loaded again, also by another MLContext, gives the same predictions; the pipeline with a text column and a
# category is saved with its transforms; a file that is not a model, and a file that is not there, are errors
load "mlcommon.ring"
mlUse()
using { "System.IO" }

oMl = mlNew(91)

# ---- a regression: label = 3 * a + 2 * b + 1, with features that do not depend on each other
cCsv = "F1,F2,Label" + nl
nSeed = 3
for n = 1 to 150
	nSeed = (nSeed * 75 + 74) % 65537
	a = nSeed % 10
	nSeed = (nSeed * 75 + 74) % 65537
	b = nSeed % 10
	cCsv += "" + a + "," + b + "," + (3 * a + 2 * b + 1) + nl
next
cFile = mlWrite("persist_train.csv",cCsv)
aColumns = mlColumns([["F1","Single"],["F2","Single"],["Label","Single"]])
oData = mlLoadCsv(oMl,cFile,aColumns)
oModel = oMl.Transforms.callMethod("Concatenate",["Features",["F1","F2"]]).callMethod("Append",[oMl.Regression.Trainers.callMethod("Sdca",["Label","Features"])]).Fit(oData)

# rows that the model has not seen
cNew = "F1,F2,Label" + nl + "1,1,0" + nl + "9,0,0" + nl + "0,9,0" + nl + "5,5,0" + nl + "7,3,0" + nl
cNewFile = mlWrite("persist_new.csv",cNew)
oNew = mlLoadCsv(oMl,cNewFile,aColumns)
aBefore = mlColumn(oModel.Transform(oNew),"System.Single","Score")
dnAssert("the model predicts the new rows",len(aBefore),5)
dnAssert("a prediction of the trained model (3*9 + 2*0 + 1 = 28)",fabs(aBefore[2] - 28) < 2,1)

# ---- saved to a file with the schema of the data, and loaded again
cModelFile = mlFile("regression.zip")
if fexists(cModelFile)
	remove(cModelFile)
ok
oMl.Model.callMethod("Save",[oModel,oData.getProp("Schema"),cModelFile])
dnAssert("the model file was made",fexists(cModelFile),1)
dnAssert("the file has bytes (a zip file)",len(read(cModelFile)) > 100,1)
dnAssert("a model file is a zip archive",left(read(cModelFile),2),"PK")
aLoaded = oMl.Model.callMethod("Load",[cModelFile])
oLoaded = aLoaded[1]
oSchema = aLoaded[2]
dnAssert("the schema that came with the model has the columns of the data",oSchema.Count,3)
aAfter = mlColumn(oLoaded.Transform(oNew),"System.Single","Score")
dnAssert("the loaded model gives a prediction for each row",len(aAfter),5)
lSame = 1
for n = 1 to 5
	if aAfter[n] != aBefore[n]
		lSame = 0
	ok
next
dnAssert("the loaded model gives exactly the predictions of the trained one",lSame,1)

# another context loads the file too (a model does not belong to the context that trained it)
oOther = mlNew(7)
aOtherLoaded = oOther.Model.callMethod("Load",[cModelFile])
oNewForOther = mlLoadCsv(oOther,cNewFile,aColumns)
aOtherScores = mlColumn(aOtherLoaded[1].Transform(oNewForOther),"System.Single","Score")
dnAssert("another context gives the same predictions",aOtherScores[2],aBefore[2])

# ---- saved to a stream (a memory stream) and loaded from it
oStream = new MemoryStream()
oMl.Model.callMethod("Save",[oModel,oData.getProp("Schema"),oStream])
dnAssert("the stream has the model",oStream.Length > 100,1)
oStream.Position = 0
aFromStream = oMl.Model.callMethod("Load",[oStream])
aStreamScores = mlColumn(aFromStream[1].Transform(oNew),"System.Single","Score")
dnAssert("a model loaded from a stream gives the same predictions",aStreamScores[3],aBefore[3])

# ---- the loaded model in a prediction engine (the row classes of the helper project)
oEngine = oMl.Model.callGeneric("CreatePredictionEngine",["MlHelpers.RegressionRow","MlHelpers.RegressionPrediction"],[oLoaded])
oRow = new RegressionRow()
oRow.F1 = 9
oRow.F2 = 0
dnAssert("the engine of a loaded model answers",fabs(oEngine.callMethod("Predict",[oRow]).Score - 28) < 2,1)

# ---- a pipeline with a text and a category: the transforms are saved with the model
cReviews = "review,city,positive" + nl
aGood = ["great","good","love","excellent","wonderful"]
aBad = ["bad","awful","hate","terrible","horrible"]
for cThing in ["service","food","room","price"]
	for n = 1 to 5
		cReviews += "the " + cThing + " was " + aGood[n] + ",Cairo,1" + nl
		cReviews += "the " + cThing + " was " + aBad[n] + ",Lima,0" + nl
	next
next
cReviewsFile = mlWrite("persist_reviews.csv",cReviews)
aReviewColumns = mlColumns([["review","String"],["city","String"],["positive","Boolean"]])
oReviews = mlLoadCsv(oMl,cReviewsFile,aReviewColumns)
oPipeline = oMl.Transforms.Text.callMethod("FeaturizeText",["ReviewFeatures","review"])
oPipeline = oPipeline.callMethod("Append",[oMl.Transforms.Categorical.callMethod("OneHotEncoding",["CityEncoded","city"])])
oPipeline = oPipeline.callMethod("Append",[oMl.Transforms.callMethod("Concatenate",["Features",["ReviewFeatures","CityEncoded"]])])
oReviewModel = oPipeline.callMethod("Append",[oMl.BinaryClassification.Trainers.callMethod("SdcaLogisticRegression",["positive","Features"])]).Fit(oReviews)
cReviewFile = mlFile("reviews.zip")
oMl.Model.callMethod("Save",[oReviewModel,oReviews.getProp("Schema"),cReviewFile])
aReviewLoaded = oMl.Model.callMethod("Load",[cReviewFile])
cQuestions = "review,city,positive" + nl + "the view was wonderful,Cairo,0" + nl + "the view was horrible,Lima,0" + nl + "the room was great,Cairo,0" + nl
cQuestionsFile = mlWrite("persist_questions.csv",cQuestions)
oQuestions = mlLoadCsv(oMl,cQuestionsFile,aReviewColumns)
aProbabilityBefore = mlColumn(oReviewModel.Transform(oQuestions),"System.Single","Probability")
aProbabilityAfter = mlColumn(aReviewLoaded[1].Transform(oQuestions),"System.Single","Probability")
dnAssert("the loaded sentiment model gives a probability for each question",len(aProbabilityAfter),3)
lSame = 1
for n = 1 to 3
	if aProbabilityAfter[n] != aProbabilityBefore[n]
		lSame = 0
	ok
next
dnAssert("the text and the category are transformed as before: the same probabilities",lSame,1)
dnAssert("a wonderful review is positive and a horrible one is negative",aProbabilityAfter[1] > 0.5 and aProbabilityAfter[2] < 0.5,1)

# ---- errors: a file that is not there, and a file that is not a model
cError = ""
try
	oMl.Model.callMethod("Load",[mlFile("there_is_no_such_model.zip")])
catch
	cError = cCatchError
done
dnAssert("a model file that is not there is an error",len(cError) > 0,1)
cNotModel = mlWrite("not_a_model.zip","this is not a model")
cError = ""
try
	oMl.Model.callMethod("Load",[cNotModel])
catch
	cError = cCatchError
done
dnAssert("a file that is not a model is an error",len(cError) > 0,1)
dnTestSummary()
