# ML.NET: k-means clustering (two groups of points that are far apart) and principal components analysis (points on a line become one number)
load "pkg.ring"
pkgUseProject("mlnet","helpers/MlHelpers",[["MlHelpers.dll",["MlHelpers"]],["Microsoft.ML.Data.dll",["Microsoft.ML","Microsoft.ML.Data"]],["Microsoft.ML.Core.dll",[]],["Microsoft.ML.StandardTrainers.dll",["Microsoft.ML.Trainers"]],["Microsoft.ML.Transforms.dll",[]],["Microsoft.ML.DataView.dll",[]],["Microsoft.ML.CpuMath.dll",[]],["Microsoft.ML.FastTree.dll",[]],["Microsoft.ML.KMeansClustering.dll",[]],["Microsoft.ML.PCA.dll",[]]])
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML")
pkgImport("mlnet","Microsoft.ML.Data.dll","Microsoft.ML.Data")
pkgImport("mlnet","MlHelpers.dll","MlHelpers")

oMl = dnNew("Microsoft.ML.MLContext",[5])

# two groups: around (1, 1) and around (10, 10)
oPoints = dnNew("System.Collections.Generic.List`1[[MlHelpers.PointRow, MlHelpers]]",[])
for aCenter in [ [1,1], [10,10] ]
	for dx = -1 to 1
		for dy = -1 to 1
			oPoint = new PointRow()
			oPoint.F1 = aCenter[1] + dx * 0.5
			oPoint.F2 = aCenter[2] + dy * 0.5
			oPoints.Add(oPoint)
		next
	next
next
dnAssert("the points",oPoints.Count,18)
oData = oMl.Data.callGeneric("LoadFromEnumerable",["MlHelpers.PointRow"],[oPoints])
oPipeline = oMl.Transforms.callMethod("Concatenate",["Features",["F1","F2"]])
oTrainer = oMl.Clustering.Trainers.callMethod("KMeans",["Features",dnNull(),2])
oModel = oPipeline.callMethod("Append",[oTrainer]).Fit(oData)
oEngine = oMl.Model.callGeneric("CreatePredictionEngine",["MlHelpers.PointRow","MlHelpers.ClusterPrediction"],[oModel])
oNearA = new PointRow()
oNearA.F1 = 1.2
oNearA.F2 = 0.8
oNearB = new PointRow()
oNearB.F1 = 0.7
oNearB.F2 = 1.4
oFar = new PointRow()
oFar.F1 = 9.5
oFar.F2 = 10.3
nA = oEngine.callMethod("Predict",[oNearA]).PredictedLabel
nB = oEngine.callMethod("Predict",[oNearB]).PredictedLabel
nFar = oEngine.callMethod("Predict",[oFar]).PredictedLabel
dnAssert("two points of the first group are in one cluster",nA,nB)
dnAssert("a point of the second group is in the other cluster",nA != nFar,1)
dnAssert("the clusters are numbered from 1",nA >= 1 and nFar >= 1 and nA <= 2 and nFar <= 2,1)
aDistances = oEngine.callMethod("Predict",[oNearA]).Distances.toList()
dnAssert("a distance for each center",len(aDistances),2)
dnAssert("the point is much nearer to its center than to the other",min(aDistances) < max(aDistances) / 10,1)

# the metrics of the clustering: the groups are tight and far apart
oMetrics = oMl.Clustering.Evaluate(oModel.Transform(oData))
dnAssert("the average distance to the center is small",oMetrics.AverageDistance < 1,1)
dnAssert("the groups are far apart (a large Davies Bouldin gap is a small index)",oMetrics.DaviesBouldinIndex < 0.5,1)

# PCA: points near the line F2 = 2 * F1 (a small shift for the odd ones) have one main component
oLine = dnNew("System.Collections.Generic.List`1[[MlHelpers.PointRow, MlHelpers]]",[])
for x = 1 to 10
	oLinePoint = new PointRow()
	oLinePoint.F1 = x
	oLinePoint.F2 = 2 * x + (x % 2) * 0.2
	oLine.Add(oLinePoint)
next
oLineData = oMl.Data.callGeneric("LoadFromEnumerable",["MlHelpers.PointRow"],[oLine])
oPca = oMl.Transforms.callMethod("Concatenate",["Features",["F1","F2"]]).callMethod("Append",[oMl.Transforms.callMethod("ProjectToPrincipalComponents",["PCA","Features",dnNull(),1])])
oPcaModel = oPca.Fit(oLineData)
aComponents = oMl.Data.callGeneric("CreateEnumerable",["MlHelpers.PcaOutput"],[oPcaModel.Transform(oLineData),0]).toList()
dnAssert("one output for each point",len(aComponents),10)
dnAssert("one component for each point",len(aComponents[1].Components.toList()),1)
# the first component is spread along the line: the points are ordered by it (up or down), and the spread is the length of the line
nFirst = aComponents[1].Components.toList()[1]
nLast = aComponents[10].Components.toList()[1]
dnAssert("the ends of the line are far apart in the component",fabs(nLast - nFirst) > 15,1)
nMiddle = aComponents[5].Components.toList()[1]
dnAssert("the middle is between the ends",(nMiddle - nFirst) * (nMiddle - nLast) < 0,1)
dnTestSummary()
