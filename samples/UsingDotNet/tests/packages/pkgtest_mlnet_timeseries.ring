# ML.NET time series: spikes (the IID and the SSA detectors), a change of level (change point detection) and a forecast of the next values; the series is a column of a CSV file
# and the answers are columns of vectors that are read back as lists
load "pkg.ring"
pkgUseProject("mlnet","helpers/MlHelpers",[["MlHelpers.dll",["MlHelpers"]],["Microsoft.ML.Data.dll",["Microsoft.ML","Microsoft.ML.Data"]],["Microsoft.ML.Core.dll",[]],["Microsoft.ML.StandardTrainers.dll",["Microsoft.ML.Trainers"]],["Microsoft.ML.Transforms.dll",[]],["Microsoft.ML.DataView.dll",[]],["Microsoft.ML.CpuMath.dll",[]],["Microsoft.ML.FastTree.dll",[]],["Microsoft.ML.KMeansClustering.dll",[]],["Microsoft.ML.PCA.dll",[]],["Microsoft.ML.Mkl.Components.dll",[]],["Microsoft.ML.TimeSeries.dll",[]],["Microsoft.ML.LightGbm.dll",[]],["Microsoft.ML.Recommender.dll",[]]])
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML")
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML.Data")

oMl = dnNew("Microsoft.ML.MLContext",[61])
oColumns = dnType("Microsoft.ML.Data.ColumnCursorExtensions")
aOneColumn = [ dnNew("Microsoft.ML.Data.TextLoader+Column",["value","Single",0]) ]

# ---- a series around 10 with a small wave, and two spikes (at the places 40 and 80)
aSeries = []
for n = 1 to 100
	nValue = 10 + sin(n * 0.7) * 0.5
	aSeries + nValue
next
aSeries[40] = 30
aSeries[80] = -12
cSeries = "value" + nl
for nValue in aSeries
	cSeries += "" + nValue + nl
next
cSeriesFile = cPkgCache + "mlnet/series.csv"
write(cSeriesFile,cSeries)
oSeries = oMl.Data.callMethod("LoadFromTextFile",[cSeriesFile,aOneColumn,",",1])
dnAssert("100 values",len(oColumns.callGeneric("GetColumn",["System.Single"],[oSeries,"value"]).toList()),100)

# the detector gives a vector of three numbers for each value: an alert (0 or 1), the score and the p-value
# the SSA detectors and the forecast use the native MKL library (a Linux computer needs libiomp5 for it): without it they are left out, and the test says so
lMkl = mklAvailable()
if not lMkl
	? "NOTE: the MKL library is not available on this computer: the SSA checks are left out"
ok
aSpikeDetectors = ["DetectIidSpike"]
if lMkl
	aSpikeDetectors + "DetectSpikeBySsa"
ok
for cDetector in aSpikeDetectors
	if cDetector = "DetectIidSpike"
		oEstimator = oMl.Transforms.callMethod("DetectIidSpike",["Alert","value",95,20])
	else
		oEstimator = oMl.Transforms.callMethod("DetectSpikeBySsa",["Alert","value",95,20,50,10])
	ok
	oModel = oEstimator.callMethod("Fit",[oSeries])
	aAlerts = oColumns.callGeneric("GetColumn",["System.Double[]"],[oModel.callMethod("Transform",[oSeries]),"Alert"]).toList()
	dnAssert(cDetector + ": a vector for each value",len(aAlerts),100)
	dnAssert(cDetector + ": a vector of three numbers",len(aAlerts[1].toList()),3)
	dnAssert(cDetector + ": the first spike is an alert",aAlerts[40].toList()[1],1)
	dnAssert(cDetector + ": the second spike is an alert",aAlerts[80].toList()[1],1)
	nAlerts = 0
	for oAlert in aAlerts
		nAlerts += oAlert.toList()[1]
	next
	dnAssert(cDetector + ": only a few alerts in all",nAlerts >= 2 and nAlerts < 8,1)
next

# ---- a change of level: 10 for 50 values, then 20
cLevel = "value" + nl
for n = 1 to 100
	if n <= 50
		cLevel += "" + (10 + sin(n * 0.9) * 0.4) + nl
	else
		cLevel += "" + (20 + sin(n * 0.9) * 0.4) + nl
	ok
next
cLevelFile = cPkgCache + "mlnet/level.csv"
write(cLevelFile,cLevel)
oLevel = oMl.Data.callMethod("LoadFromTextFile",[cLevelFile,aOneColumn,",",1])
aChangeDetectors = ["DetectIidChangePoint"]
if lMkl
	aChangeDetectors + "DetectChangePointBySsa"
ok
for cDetector in aChangeDetectors
	if cDetector = "DetectChangePointBySsa"
		oEstimator = oMl.Transforms.callMethod(cDetector,["Change","value",95,10,40,10])
	else
		oEstimator = oMl.Transforms.callMethod(cDetector,["Change","value",95,10])
	ok
	oChange = oEstimator.callMethod("Fit",[oLevel])
	aChange = oColumns.callGeneric("GetColumn",["System.Double[]"],[oChange.callMethod("Transform",[oLevel]),"Change"]).toList()
	dnAssert(cDetector + ": a vector for each value",len(aChange),100)
	# the first alert after the start of the series (the detector may warn once while it starts)
	nFirst = 0
	for n = 30 to len(aChange)
		if aChange[n].toList()[1] = 1 and nFirst = 0
			nFirst = n
		ok
	next
	dnAssert(cDetector + ": the change of level is found",nFirst > 0,1)
	dnAssert(cDetector + ": it is found at the place where the level changes (value 51)",nFirst >= 50 and nFirst <= 55,1)
next

if lMkl
	# ---- a forecast: a wave with a period of 10 values and a rising line; the next 5 values continue the pattern
	cWave = "value" + nl
	for n = 1 to 120
		cWave += "" + (n * 0.5 + sin(n * 2 * 3.14159265 / 10) * 5) + nl
	next
	cWaveFile = cPkgCache + "mlnet/wave.csv"
	write(cWaveFile,cWave)
	oWave = oMl.Data.callMethod("LoadFromTextFile",[cWaveFile,aOneColumn,",",1])
	oForecaster = oMl.Forecasting.callMethod("ForecastBySsa",["Forecast","value",20,120,120,5])
	oForecastModel = oForecaster.callMethod("Fit",[oWave])
	aForecast = oColumns.callGeneric("GetColumn",["System.Single[]"],[oForecastModel.callMethod("Transform",[oWave]),"Forecast"]).toList()
	aNext = aForecast[len(aForecast)].toList()
	dnAssert("five values forecast",len(aNext),5)
	lClose = 1
	for n = 1 to 5
		nExpected = (120 + n) * 0.5 + sin((120 + n) * 2 * 3.14159265 / 10) * 5
		if fabs(aNext[n] - nExpected) > 3
			lClose = 0
		ok
	next
	dnAssert("the forecast follows the line and the wave",lClose,1)
ok
dnTestSummary()

# 1 when the native MKL library can be loaded: the SSA spike detector is fitted on a short series
func mklAvailable

	cTiny = "value" + nl
	for n = 1 to 40
		cTiny += "" + (10 + sin(n * 0.7)) + nl
	next
	cTinyFile = cPkgCache + "mlnet/tiny_series.csv"
	write(cTinyFile,cTiny)
	oTiny = oMl.Data.callMethod("LoadFromTextFile",[cTinyFile,aOneColumn,",",1])
	try
		oMl.Transforms.callMethod("DetectSpikeBySsa",["Alert","value",95,10,20,5]).callMethod("Fit",[oTiny])
	catch
		if substr(cCatchError,"MklImports") > 0 or substr(cCatchError,"MKL") > 0 or substr(cCatchError,"Mkl") > 0
			return 0
		ok
		raise(cCatchError)
	done
	return 1

