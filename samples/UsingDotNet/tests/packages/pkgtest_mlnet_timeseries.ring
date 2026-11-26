# ML.NET time series: spikes (the IID and the SSA detectors), a change of level (change point detection) and a forecast of the next values; the series is a column of a CSV file
# and the answers are columns of vectors that are read back as lists
load "mlcommon.ring"
mlUse()

oMl = mlNew(61)
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
cSeriesFile = mlWrite("series.csv",cSeries)
oSeries = mlLoadCsv(oMl,cSeriesFile,aOneColumn)
dnAssert("100 values",len(mlColumn(oSeries,"System.Single","value")),100)

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
	aAlerts = mlColumn(oModel.callMethod("Transform",[oSeries]),"System.Double[]","Alert")
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
cLevelFile = mlWrite("level.csv",cLevel)
oLevel = mlLoadCsv(oMl,cLevelFile,aOneColumn)
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
	aChange = mlColumn(oChange.callMethod("Transform",[oLevel]),"System.Double[]","Change")
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
	cWaveFile = mlFile("wave.csv")
	write(cWaveFile,cWave)
	oWave = mlLoadCsv(oMl,cWaveFile,aOneColumn)
	oForecaster = oMl.Forecasting.callMethod("ForecastBySsa",["Forecast","value",20,120,120,5])
	oForecastModel = oForecaster.callMethod("Fit",[oWave])
	aForecast = mlColumn(oForecastModel.callMethod("Transform",[oWave]),"System.Single[]","Forecast")
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
	cTinyFile = mlFile("tiny_series.csv")
	write(cTinyFile,cTiny)
	oTiny = mlLoadCsv(oMl,cTinyFile,aOneColumn)
	try
		oMl.Transforms.callMethod("DetectSpikeBySsa",["Alert","value",95,10,20,5]).callMethod("Fit",[oTiny])
	catch
		if substr(cCatchError,"MklImports") > 0 or substr(cCatchError,"MKL") > 0 or substr(cCatchError,"Mkl") > 0
			return 0
		ok
		raise(cCatchError)
	done
	return 1

