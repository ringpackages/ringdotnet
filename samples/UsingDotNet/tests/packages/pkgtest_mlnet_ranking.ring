# ML.NET ranking: documents of a query get a relevance (0 to 3) and a few numbers; FastTree and LightGBM learn to give the relevant documents the higher scores inside each query,
# and the ranking metrics (DCG and NDCG) measure the order that the scores give
load "mlcommon.ring"
mlUse()

oMl = mlNew(23)

# 30 queries of 8 documents each. The relevance of a document grows with F1 (and a little with F2): relevance = 0 to 3 from F1 * 3 + F2, with the numbers that a small generator gives
cCsv = "query,relevance,F1,F2,F3" + nl
nSeed = 5
for nQuery = 1 to 30
	for nDocument = 1 to 8
		nSeed = (nSeed * 75 + 74) % 65537
		nF1 = nSeed % 10 / 10
		nSeed = (nSeed * 75 + 74) % 65537
		nF2 = nSeed % 10 / 10
		nSeed = (nSeed * 75 + 74) % 65537
		nF3 = nSeed % 10 / 10
		nRelevance = floor(nF1 * 3 + nF2 * 0.9)
		if nRelevance > 3
			nRelevance = 3
		ok
		cCsv += "q" + nQuery + "," + nRelevance + "," + nF1 + "," + nF2 + "," + nF3 + nl
	next
next
aColumns = mlColumns([["query","String"],["relevance","Single"],["F1","Single"],["F2","Single"],["F3","Single"]])
oData = mlLoadCsv(oMl,mlWrite("ranking.csv",cCsv),aColumns)
dnAssert("240 documents",len(mlColumn(oData,"System.Single","relevance")),240)

# the query must be a key, and so must the relevance that is the label of the ranker (a higher key is a more relevant document)
oPrepare = oMl.Transforms.Conversion.callMethod("MapValueToKey",["queryKey","query"])
oPrepare = oPrepare.callMethod("Append",[oMl.Transforms.Conversion.callMethod("MapValueToKey",["Label","relevance",1000000,"ByValue"])])          # keys in the order of the values, not of their first appearance
oPrepare = oPrepare.callMethod("Append",[oMl.Transforms.callMethod("Concatenate",["Features",["F1","F2","F3"]])])

for cTrainer in ["FastTree","LightGbm"]
	oRanker = oMl.Ranking.Trainers.callMethod(cTrainer,["Label","Features","queryKey"])
	oModel = oPrepare.callMethod("Append",[oRanker]).Fit(oData)
	oScored = oModel.Transform(oData)
	oMetrics = oMl.Ranking.callMethod("Evaluate",[oScored,"Label","queryKey"])
	aNdcg = oMetrics.getProp("NormalizedDiscountedCumulativeGains").toList()
	dnAssert(cTrainer + ": the metrics have a value for each position",len(aNdcg) >= 3,1)
	dnAssert(cTrainer + ": NDCG at the first place is high",aNdcg[1] > 0.85,1)
	dnAssert(cTrainer + ": NDCG at the third place is high",aNdcg[3] > 0.85,1)
	dnAssert(cTrainer + ": the discounted gains are known",len(oMetrics.getProp("DiscountedCumulativeGains").toList()) >= 3,1)

	# inside a query the scores follow the relevance: the best document of the first query is among the first two by score
	aScores = mlColumn(oScored,"System.Single","Score")
	aRelevance = mlColumn(oScored,"System.Single","relevance")
	dnAssert(cTrainer + ": a score for each document",len(aScores),240)
	nBestPlace = 1
	nBestRelevance = -1
	for n = 1 to 8
		if aRelevance[n] > nBestRelevance
			nBestRelevance = aRelevance[n]
			nBestPlace = n
		ok
	next
	nHigher = 0
	for n = 1 to 8
		if aScores[n] > aScores[nBestPlace]
			nHigher++
		ok
	next
	dnAssert(cTrainer + ": the most relevant document of the first query has one of the two highest scores",nHigher <= 1,1)

	# over all the queries: the mean relevance of the top document by score is higher than the mean relevance of the documents
	nTopSum = 0
	nAllSum = 0
	for nQuery = 0 to 29
		nTop = 1 + nQuery * 8
		for n = 1 to 8
			nAt = n + nQuery * 8
			nAllSum += aRelevance[nAt]
			if aScores[nAt] > aScores[nTop]
				nTop = nAt
			ok
		next
		nTopSum += aRelevance[nTop]
	next
	dnAssert(cTrainer + ": the top document of a query is more relevant than the average one",nTopSum / 30 > nAllSum / 240 + 0.5,1)
next
dnTestSummary()
