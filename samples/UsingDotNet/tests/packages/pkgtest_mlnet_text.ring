# ML.NET with columns that are texts, read from a CSV file with column definitions made in Ring: a category is one-hot encoded, a free text is featurized into word
# counts, a text label is mapped to a class number and back; no C# class
load "pkg.ring"
pkgUseProject("mlnet","helpers/MlHelpers",[["MlHelpers.dll",["MlHelpers"]],["Microsoft.ML.Data.dll",["Microsoft.ML","Microsoft.ML.Data"]],["Microsoft.ML.Core.dll",[]],["Microsoft.ML.StandardTrainers.dll",["Microsoft.ML.Trainers"]],["Microsoft.ML.Transforms.dll",[]],["Microsoft.ML.DataView.dll",[]],["Microsoft.ML.CpuMath.dll",[]],["Microsoft.ML.FastTree.dll",[]],["Microsoft.ML.KMeansClustering.dll",[]],["Microsoft.ML.PCA.dll",[]]])
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML")
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML.Data")
pkgImport("mlnet","Microsoft.ML.StandardTrainers.dll","Microsoft.ML.Trainers")

oMl = dnNew("Microsoft.ML.MLContext",[21])

# reviews: a positive or a negative sentence, the city, a score, and the label (positive = 1)
aGood = ["great","good","love","excellent","wonderful","happy"]
aBad = ["bad","awful","hate","terrible","horrible","sad"]
aThings = ["service","food","room","price","staff","view"]
cCsv = "review,city,score,positive" + nl
nRows = 0
for nThing = 1 to len(aThings)
	for nWord = 1 to len(aGood)
		cCsv += "the " + aThings[nThing] + " was " + aGood[nWord] + ",Cairo," + (4 + nWord % 2) + ",1" + nl
		cCsv += "the " + aThings[nThing] + " was " + aBad[nWord] + ",Lima," + (1 + nWord % 2) + ",0" + nl
		nRows += 2
	next
next
cFile = cPkgCache + "mlnet/reviews.csv"
write(cFile,cCsv)
dnAssert("the rows that were written",nRows,72)

# the columns: two texts, a number and a yes/no
aColumns = []
aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["review","String",0])
aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["city","String",1])
aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["score","Single",2])
aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["positive","Boolean",3])
oData = oMl.Data.callMethod("LoadFromTextFile",[cFile,aColumns,",",1])
dnAssert("four columns",oData.getProp("Schema").getProp("Count"),4)

# the pipeline: the review becomes a vector of word counts, the city a one-hot vector, and the three are joined with the score
oPipeline = oMl.Transforms.Text.callMethod("FeaturizeText",["ReviewFeatures","review"])
oPipeline = oPipeline.callMethod("Append",[oMl.Transforms.Categorical.callMethod("OneHotEncoding",["CityEncoded","city"])])
oPipeline = oPipeline.callMethod("Append",[oMl.Transforms.callMethod("Concatenate",["Features",["ReviewFeatures","CityEncoded","score"]])])
oChain = oPipeline.callMethod("Append",[oMl.BinaryClassification.Trainers.callMethod("SdcaLogisticRegression",["positive","Features"])])
oModel = oChain.Fit(oData)
oMetrics = oMl.BinaryClassification.callMethod("Evaluate",[oModel.Transform(oData),"positive"])
dnAssert("the accuracy of the sentiment model",oMetrics.Accuracy > 0.95,1)
dnAssert("the area under the curve",oMetrics.AreaUnderRocCurve > 0.95,1)

# new reviews, with words that the model learned: written to a file, read with the same columns
cNew = "review,city,score,positive" + nl + "the view was wonderful,Cairo,5,0" + nl + "the staff was terrible,Lima,1,0" + nl + "the room was great,Cairo,4,0" + nl + "the food was awful,Lima,2,0" + nl
cNewFile = cPkgCache + "mlnet/new_reviews.csv"
write(cNewFile,cNew)
oNewData = oMl.Data.callMethod("LoadFromTextFile",[cNewFile,aColumns,",",1])
oScored = oModel.Transform(oNewData)
oColumns = dnType("Microsoft.ML.Data.ColumnCursorExtensions")
aPredicted = oColumns.callGeneric("GetColumn",["System.Boolean"],[oScored,"PredictedLabel"]).toList()
dnAssert("a prediction for each new review",len(aPredicted),4)
dnAssert("a wonderful review is positive",aPredicted[1],1)
dnAssert("a terrible review is negative",aPredicted[2],0)
dnAssert("a great review is positive",aPredicted[3],1)
dnAssert("an awful review is negative",aPredicted[4],0)
aProbability = oColumns.callGeneric("GetColumn",["System.Single"],[oScored,"Probability"]).toList()
dnAssert("a probability above a half for the positive ones",aProbability[1] > 0.5 and aProbability[3] > 0.5,1)
dnAssert("a probability below a half for the negative ones",aProbability[2] < 0.5 and aProbability[4] < 0.5,1)

# the text columns can be read back from the data
aReviews = oColumns.callGeneric("GetColumn",["System.String"],[oNewData,"review"]).toList()
dnAssert("the text of a review is read back",aReviews[1],"the view was wonderful")
dnAssert("the number of reviews",len(aReviews),4)

# a text label with three classes: the label is mapped to a class number for the trainer, and the prediction is mapped back to the text
aTopics = [ ["sports",["football","goal","match","player","team"]], ["music",["guitar","song","band","concert","melody"]], ["tech",["software","computer","network","code","server"]] ]
cTopics = "text,topic" + nl
for aTopic in aTopics
	for cWord in aTopic[2]
		for cOther in aTopic[2]
			cTopics += "about the " + cWord + " and the " + cOther + "," + aTopic[1] + nl
		next
	next
next
cTopicsFile = cPkgCache + "mlnet/topics.csv"
write(cTopicsFile,cTopics)
aTopicColumns = []
aTopicColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["text","String",0])
aTopicColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["topic","String",1])
oTopics = oMl.Data.callMethod("LoadFromTextFile",[cTopicsFile,aTopicColumns,",",1])
oTopicPipeline = oMl.Transforms.Conversion.callMethod("MapValueToKey",["Label","topic"])
oTopicPipeline = oTopicPipeline.callMethod("Append",[oMl.Transforms.Text.callMethod("FeaturizeText",["Features","text"])])
oTopicPipeline = oTopicPipeline.callMethod("Append",[oMl.MulticlassClassification.Trainers.callMethod("SdcaMaximumEntropy",["Label","Features"])])
oTopicPipeline = oTopicPipeline.callMethod("Append",[oMl.Transforms.Conversion.callMethod("MapKeyToValue",["PredictedTopic","PredictedLabel"])])
oTopicModel = oTopicPipeline.Fit(oTopics)
oTopicMetrics = oMl.MulticlassClassification.callMethod("Evaluate",[oTopicModel.Transform(oTopics)])
dnAssert("the accuracy over three classes",oTopicMetrics.MicroAccuracy > 0.95,1)
dnAssert("the macro accuracy",oTopicMetrics.MacroAccuracy > 0.95,1)

cQuestions = "text,topic" + nl + "about the goal and the team,x" + nl + "about the guitar and the melody,x" + nl + "about the code and the server,x" + nl
cQuestionsFile = cPkgCache + "mlnet/questions.csv"
write(cQuestionsFile,cQuestions)
oQuestions = oMl.Data.callMethod("LoadFromTextFile",[cQuestionsFile,aTopicColumns,",",1])
aTopicNames = oColumns.callGeneric("GetColumn",["System.String"],[oTopicModel.Transform(oQuestions),"PredictedTopic"]).toList()
dnAssert("a prediction is the text of the class",aTopicNames[1],"sports")
dnAssert("a music text",aTopicNames[2],"music")
dnAssert("a tech text",aTopicNames[3],"tech")

# texts with a comma inside (quoted), and letters that are not ASCII, are read as they are
cOdd = "text,topic" + nl + '"hello, world",a' + nl + "مرحبا بالعالم,b" + nl + "日本語のテキスト 🎉,c" + nl
cOddFile = cPkgCache + "mlnet/odd.csv"
write(cOddFile,cOdd)
oOdd = oMl.Data.callMethod("LoadFromTextFile",[cOddFile,aTopicColumns,",",1,1])
aOdd = oColumns.callGeneric("GetColumn",["System.String"],[oOdd,"text"]).toList()
dnAssert("a quoted text with a comma",aOdd[1],"hello, world")
dnAssert("an Arabic text",aOdd[2],"مرحبا بالعالم")
dnAssert("a Japanese text with an emoji",aOdd[3],"日本語のテキスト 🎉")
dnTestSummary()
