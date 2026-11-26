# ML.NET data transforms, each one read back as a column: scaling (min-max, mean-variance, binning), missing values replaced, rows filtered, columns chosen and dropped, hashing,
# words and word bags from a text, and the keys of a category
load "pkg.ring"
pkgUseProject("mlnet","helpers/MlHelpers",[["MlHelpers.dll",["MlHelpers"]],["Microsoft.ML.Data.dll",["Microsoft.ML","Microsoft.ML.Data"]],["Microsoft.ML.Core.dll",[]],["Microsoft.ML.StandardTrainers.dll",["Microsoft.ML.Trainers"]],["Microsoft.ML.Transforms.dll",[]],["Microsoft.ML.DataView.dll",[]],["Microsoft.ML.CpuMath.dll",[]],["Microsoft.ML.FastTree.dll",[]],["Microsoft.ML.KMeansClustering.dll",[]],["Microsoft.ML.PCA.dll",[]],["Microsoft.ML.Mkl.Components.dll",[]],["Microsoft.ML.TimeSeries.dll",[]],["Microsoft.ML.LightGbm.dll",[]],["Microsoft.ML.Recommender.dll",[]]])
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML")
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML.Data")

oMl = dnNew("Microsoft.ML.MLContext",[81])
oColumns = dnType("Microsoft.ML.Data.ColumnCursorExtensions")

# a small table: a number, a number with missing values, a category and a sentence
cTable = "size,weight,color,note" + nl + "10,2.5,red,the cat sat" + nl + "20,NaN,blue,the dog ran" + nl + "30,4.5,red,a cat ran away" + nl + "40,NaN,green,the dog sat down" + nl + "50,6.5,blue,a bird flew" + nl
cFile = cPkgCache + "mlnet/table.csv"
write(cFile,cTable)
aColumns = []
aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["size","Single",0])
aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["weight","Single",1])
aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["color","String",2])
aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",["note","String",3])
oData = oMl.Data.callMethod("LoadFromTextFile",[cFile,aColumns,",",1])

# a transform is fitted on the data and applied to it; the answer is read as a column (the scalers get fixZero = 0, or they keep the zero of the numbers where it is)
oScaled = oMl.Transforms.callMethod("NormalizeMinMax",["sizeScaled","size",1000000,0]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aScaled = oColumns.callGeneric("GetColumn",["System.Single"],[oScaled,"sizeScaled"]).toList()
dnAssert("min-max: the smallest value is 0",aScaled[1],0)
dnAssert("min-max: the largest value is 1",aScaled[5],1)
dnAssert("min-max: a value in the middle",fabs(aScaled[3] - 0.5) < 0.001,1)

oStandard = oMl.Transforms.callMethod("NormalizeMeanVariance",["sizeStandard","size",1000000,0]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aStandard = oColumns.callGeneric("GetColumn",["System.Single"],[oStandard,"sizeStandard"]).toList()
nSum = 0
for nValue in aStandard
	nSum += nValue
next
dnAssert("mean-variance: the values add up to about 0",fabs(nSum) < 0.001,1)
dnAssert("mean-variance: the middle value is 0",fabs(aStandard[3]) < 0.001,1)
dnAssert("mean-variance: the values keep their order",aStandard[1] < aStandard[2] and aStandard[4] < aStandard[5],1)

oBinned = oMl.Transforms.callMethod("NormalizeBinning",["sizeBinned","size",5]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aBinned = oColumns.callGeneric("GetColumn",["System.Single"],[oBinned,"sizeBinned"]).toList()
dnAssert("binning: five values give five different bins",aBinned[1] < aBinned[2] and aBinned[2] < aBinned[3] and aBinned[3] < aBinned[4] and aBinned[4] < aBinned[5],1)

# the missing values (written as NaN: not a number) are replaced by the mean
aWeights = oColumns.callGeneric("GetColumn",["System.Single"],[oData,"weight"]).toList()
lMissing = 0
for nWeight in aWeights
	if "" + nWeight = "nan"
		lMissing++
	ok
next
dnAssert("two weights are missing",lMissing,2)
oFilled = oMl.Transforms.callMethod("ReplaceMissingValues",["weightFilled","weight","Mean"]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aFilled = oColumns.callGeneric("GetColumn",["System.Single"],[oFilled,"weightFilled"]).toList()
dnAssert("a missing weight is replaced by the mean of the others (4.5)",fabs(aFilled[2] - 4.5) < 0.001,1)
dnAssert("a weight that was there is kept",aFilled[1],2.5)

# rows that pass a range, and the columns that are kept
oRows = oMl.Data.callMethod("FilterRowsByColumn",[oData,"size",20,45])
aKept = oColumns.callGeneric("GetColumn",["System.Single"],[oRows,"size"]).toList()
dnAssert("three rows have a size from 20 to 45",len(aKept),3)
dnAssert("the first of them",aKept[1],20)
oSelected = oMl.Transforms.callMethod("SelectColumns",[["size","color"]]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
dnAssert("two columns are kept",oSelected.getProp("Schema").getProp("Count"),2)
oDropped = oMl.Transforms.callMethod("DropColumns",[["note","weight"]]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
dnAssert("two columns are dropped",oDropped.getProp("Schema").getProp("Count"),2)

# a category: the keys that stand for its values, and the one-hot vectors
oKeys = oMl.Transforms.Conversion.callMethod("MapValueToKey",["colorKey","color"]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aKeys = oColumns.callGeneric("GetColumn",["System.UInt32"],[oKeys,"colorKey"]).toList()
dnAssert("the same color has the same key",aKeys[1],aKeys[3])
dnAssert("another color has another key",aKeys[1] != aKeys[2],1)
dnAssert("the keys start at 1",aKeys[1] >= 1,1)
oHot = oMl.Transforms.Categorical.callMethod("OneHotEncoding",["colorHot","color"]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aHot = oColumns.callGeneric("GetColumn",["System.Single[]"],[oHot,"colorHot"]).toList()
dnAssert("a one-hot vector for each color has a place for each of the three colors",len(aHot[1].toList()),3)
dnAssert("exactly one place is set",aHot[1].toList()[1] + aHot[1].toList()[2] + aHot[1].toList()[3],1)
oHashed = oMl.Transforms.Conversion.callMethod("Hash",["colorHash","color"]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aHashed = oColumns.callGeneric("GetColumn",["System.UInt32"],[oHashed,"colorHash"]).toList()
dnAssert("hashing: the same text gives the same number",aHashed[1],aHashed[3])
dnAssert("hashing: other texts give other numbers",aHashed[1] != aHashed[2],1)

# words and word bags from a sentence
oWords = oMl.Transforms.Text.callMethod("TokenizeIntoWords",["words","note"]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aWords = oColumns.callGeneric("GetColumn",["System.String[]"],[oWords,"words"]).toList()
dnAssert("the first sentence has three words",len(aWords[1].toList()),3)
dnAssert("the second word",aWords[1].toList()[2],"cat")
dnAssert("the third sentence has four words",len(aWords[3].toList()),4)
oBags = oMl.Transforms.Text.callMethod("TokenizeIntoWords",["tokens","note"]).callMethod("Append",[oMl.Transforms.Conversion.callMethod("MapValueToKey",["tokenKeys","tokens"])]).callMethod("Append",[oMl.Transforms.Text.callMethod("ProduceWordBags",["bag","tokens",1])])
oBagData = oBags.callMethod("Fit",[oData]).callMethod("Transform",[oData])
aBag = oColumns.callGeneric("GetColumn",["System.Single[]"],[oBagData,"bag"]).toList()
dnAssert("a bag of words has a place for each word",len(aBag[1].toList()) > 5,1)
nCounted = 0
for nCount in aBag[1].toList()
	nCounted += nCount
next
dnAssert("the counts of the first sentence add up to its three words",nCounted,3)
dnTestSummary()
