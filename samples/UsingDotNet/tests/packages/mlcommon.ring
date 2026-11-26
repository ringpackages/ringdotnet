# The setup that the ML.NET tests share (pkgtest_mlnet_*.ring):
#   load "mlcommon.ring"
#   mlUse()                                   restore and load ML.NET and its helper project (the rows), and import the namespaces
#   oMl = mlNew(42)                           a context with a seed
#   aColumns = mlColumns([["x","Single"],["label","Boolean"],["name","String"]])    the columns of a CSV file, in the order of the file
#   cFile = mlWrite("data.csv",cCsv)          a file of the cache folder of the tests
#   oData = mlLoadCsv(oMl,cFile,aColumns)     a CSV file with a header, read as a data view
#   aScores = mlColumn(oScored,"System.Single","Score")     a column of a data view as a Ring list
load "pkg.ring"

# Restores ML.NET (a helper project references the packages: OLS, time series, LightGBM and recommendation too), wraps the DLLs and imports the namespaces
func mlUse

	pkgUseProject("mlnet","helpers/MlHelpers",[["MlHelpers.dll",["MlHelpers"]],["Microsoft.ML.Data.dll",["Microsoft.ML","Microsoft.ML.Data"]],["Microsoft.ML.Core.dll",[]],["Microsoft.ML.StandardTrainers.dll",["Microsoft.ML.Trainers"]],["Microsoft.ML.Transforms.dll",[]],["Microsoft.ML.DataView.dll",[]],["Microsoft.ML.CpuMath.dll",[]],["Microsoft.ML.FastTree.dll",[]],["Microsoft.ML.KMeansClustering.dll",[]],["Microsoft.ML.PCA.dll",[]],["Microsoft.ML.Mkl.Components.dll",[]],["Microsoft.ML.TimeSeries.dll",[]],["Microsoft.ML.LightGbm.dll",[]],["Microsoft.ML.Recommender.dll",[]]])
	pkgImport("mlnet","MlHelpers.dll","MlHelpers")
	pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML")
	pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML.Data")
	pkgImport("mlnet","Microsoft.ML.StandardTrainers.dll","Microsoft.ML.Trainers")

# Restores the ML.NET AutoML package in a cache folder of its own (it brings the deep learning packages: hundreds of megabytes), wraps the DLLs and imports the namespaces
func mlUseAuto

	pkgUseProject("mlnet_auto","helpers/MlAutoHelpers",[["Microsoft.ML.Data.dll",["Microsoft.ML","Microsoft.ML.Data"]],["Microsoft.ML.AutoML.dll",["Microsoft.ML.AutoML"]],["Microsoft.ML.Core.dll",[]],["Microsoft.ML.StandardTrainers.dll",["Microsoft.ML.Trainers"]],["Microsoft.ML.Transforms.dll",[]],["Microsoft.ML.DataView.dll",[]],["Microsoft.ML.CpuMath.dll",[]],["Microsoft.ML.FastTree.dll",[]],["Microsoft.ML.LightGbm.dll",[]],["Microsoft.ML.Mkl.Components.dll",[]],["Microsoft.ML.SearchSpace.dll",[]]])
	pkgImport("mlnet_auto","Microsoft.ML.Data.dll","Microsoft.ML")
	pkgImport("mlnet_auto","Microsoft.ML.Data.dll","Microsoft.ML.Data")
	pkgImport("mlnet_auto","Microsoft.ML.AutoML.dll","Microsoft.ML.AutoML")

# A context: the seed makes the random choices of the trainers the same each time (trainers that use several threads still vary a little)
func mlNew nSeed

	return dnNew("Microsoft.ML.MLContext",[nSeed])

# The path of a file in the folder of the ML.NET tests (in the cache: it is made when it is not there)
func mlFile cName

	cFolder = cPkgCache + "mltests/"
	if not direxists(cFolder)
		pkgMakeDir(cFolder)
	ok
	return cFolder + cName

# Write a file in that folder and answer its path
func mlWrite cName, cText

	write(mlFile(cName),cText)
	return mlFile(cName)

# The columns of a CSV file: [["name","Single"],["label","Boolean"]...] in the order of the file (Single, Double, Int32, Boolean, String ...)
func mlColumns aSpec

	aColumns = []
	nSpecs = len(aSpec)
	for nPlace = 1 to nSpecs
		aColumns + dnNew("Microsoft.ML.Data.TextLoader+Column",[aSpec[nPlace][1],aSpec[nPlace][2],nPlace - 1])
	next
	return aColumns

# A CSV file with a header line, separated by commas, as a data view
func mlLoadCsv oMl, cFile, aColumns

	return oMl.Data.callMethod("LoadFromTextFile",[cFile,aColumns,",",1])

# A column of a data view as a Ring list; cType is the .NET type of the values ("System.Single", "System.String", "System.Boolean", "System.Double[]" ...)
func mlColumn oData, cType, cName

	return dnType("Microsoft.ML.Data.ColumnCursorExtensions").callGeneric("GetColumn",[cType],[oData,cName]).toList()
