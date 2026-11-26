# ML.NET data transforms, each one read back as a column: scaling (min-max, mean-variance, binning), missing values replaced, rows filtered, columns chosen and dropped, hashing,
# words and word bags from a text, and the keys of a category
load "mlcommon.ring"
mlUse()

oMl = mlNew(81)

# a small table: a number, a number with missing values, a category and a sentence
cTable = "size,weight,color,note" + nl + "10,2.5,red,the cat sat" + nl + "20,NaN,blue,the dog ran" + nl + "30,4.5,red,a cat ran away" + nl + "40,NaN,green,the dog sat down" + nl + "50,6.5,blue,a bird flew" + nl
cFile = mlWrite("table.csv",cTable)
aColumns = mlColumns([["size","Single"],["weight","Single"],["color","String"],["note","String"]])
oData = mlLoadCsv(oMl,cFile,aColumns)

# a transform is fitted on the data and applied to it; the answer is read as a column (the scalers get fixZero = 0, or they keep the zero of the numbers where it is)
oScaled = oMl.Transforms.callMethod("NormalizeMinMax",["sizeScaled","size",1000000,0]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aScaled = mlColumn(oScaled,"System.Single","sizeScaled")
dnAssert("min-max: the smallest value is 0",aScaled[1],0)
dnAssert("min-max: the largest value is 1",aScaled[5],1)
dnAssert("min-max: a value in the middle",fabs(aScaled[3] - 0.5) < 0.001,1)

oStandard = oMl.Transforms.callMethod("NormalizeMeanVariance",["sizeStandard","size",1000000,0]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aStandard = mlColumn(oStandard,"System.Single","sizeStandard")
nSum = 0
for nValue in aStandard
	nSum += nValue
next
dnAssert("mean-variance: the values add up to about 0",fabs(nSum) < 0.001,1)
dnAssert("mean-variance: the middle value is 0",fabs(aStandard[3]) < 0.001,1)
dnAssert("mean-variance: the values keep their order",aStandard[1] < aStandard[2] and aStandard[4] < aStandard[5],1)

oBinned = oMl.Transforms.callMethod("NormalizeBinning",["sizeBinned","size",5]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aBinned = mlColumn(oBinned,"System.Single","sizeBinned")
dnAssert("binning: five values give five different bins",aBinned[1] < aBinned[2] and aBinned[2] < aBinned[3] and aBinned[3] < aBinned[4] and aBinned[4] < aBinned[5],1)

# the missing values (written as NaN: not a number) are replaced by the mean
aWeights = mlColumn(oData,"System.Single","weight")
lMissing = 0
for nWeight in aWeights
	if "" + nWeight = "nan"
		lMissing++
	ok
next
dnAssert("two weights are missing",lMissing,2)
oFilled = oMl.Transforms.callMethod("ReplaceMissingValues",["weightFilled","weight","Mean"]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aFilled = mlColumn(oFilled,"System.Single","weightFilled")
dnAssert("a missing weight is replaced by the mean of the others (4.5)",fabs(aFilled[2] - 4.5) < 0.001,1)
dnAssert("a weight that was there is kept",aFilled[1],2.5)

# rows that pass a range, and the columns that are kept
oRows = oMl.Data.callMethod("FilterRowsByColumn",[oData,"size",20,45])
aKept = mlColumn(oRows,"System.Single","size")
dnAssert("three rows have a size from 20 to 45",len(aKept),3)
dnAssert("the first of them",aKept[1],20)
oSelected = oMl.Transforms.callMethod("SelectColumns",[["size","color"]]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
dnAssert("two columns are kept",oSelected.getProp("Schema").getProp("Count"),2)
oDropped = oMl.Transforms.callMethod("DropColumns",[["note","weight"]]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
dnAssert("two columns are dropped",oDropped.getProp("Schema").getProp("Count"),2)

# a category: the keys that stand for its values, and the one-hot vectors
oKeys = oMl.Transforms.Conversion.callMethod("MapValueToKey",["colorKey","color"]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aKeys = mlColumn(oKeys,"System.UInt32","colorKey")
dnAssert("the same color has the same key",aKeys[1],aKeys[3])
dnAssert("another color has another key",aKeys[1] != aKeys[2],1)
dnAssert("the keys start at 1",aKeys[1] >= 1,1)
oHot = oMl.Transforms.Categorical.callMethod("OneHotEncoding",["colorHot","color"]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aHot = mlColumn(oHot,"System.Single[]","colorHot")
dnAssert("a one-hot vector for each color has a place for each of the three colors",len(aHot[1].toList()),3)
dnAssert("exactly one place is set",aHot[1].toList()[1] + aHot[1].toList()[2] + aHot[1].toList()[3],1)
oHashed = oMl.Transforms.Conversion.callMethod("Hash",["colorHash","color"]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aHashed = mlColumn(oHashed,"System.UInt32","colorHash")
dnAssert("hashing: the same text gives the same number",aHashed[1],aHashed[3])
dnAssert("hashing: other texts give other numbers",aHashed[1] != aHashed[2],1)

# words and word bags from a sentence
oWords = oMl.Transforms.Text.callMethod("TokenizeIntoWords",["words","note"]).callMethod("Fit",[oData]).callMethod("Transform",[oData])
aWords = mlColumn(oWords,"System.String[]","words")
dnAssert("the first sentence has three words",len(aWords[1].toList()),3)
dnAssert("the second word",aWords[1].toList()[2],"cat")
dnAssert("the third sentence has four words",len(aWords[3].toList()),4)
oBags = oMl.Transforms.Text.callMethod("TokenizeIntoWords",["tokens","note"]).callMethod("Append",[oMl.Transforms.Conversion.callMethod("MapValueToKey",["tokenKeys","tokens"])]).callMethod("Append",[oMl.Transforms.Text.callMethod("ProduceWordBags",["bag","tokens",1])])
oBagData = oBags.callMethod("Fit",[oData]).callMethod("Transform",[oData])
aBag = mlColumn(oBagData,"System.Single[]","bag")
dnAssert("a bag of words has a place for each word",len(aBag[1].toList()) > 5,1)
nCounted = 0
for nCount in aBag[1].toList()
	nCounted += nCount
next
dnAssert("the counts of the first sentence add up to its three words",nCounted,3)
dnTestSummary()
