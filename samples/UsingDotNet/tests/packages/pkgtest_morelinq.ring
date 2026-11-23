# MoreLINQ: extra LINQ methods (Batch, Pairwise, Shuffle...) as static generic methods; Ring lists are the sources, callbacks are the selectors, the type arguments are the item types
load "pkg.ring"
pkgUse("morelinq",[["morelinq","4.4.0"]],[["MoreLinq.dll",[]]])
dnImport("System")

cMore = "MoreLinq.MoreEnumerable"
oMore = dnType(cMore)
aNumbers = [1,2,3,4,5,6,7]

# Batch: lists of three
aBatches = oMore.callGeneric("Batch",["System.Double"],[aNumbers,3]).toList()
dnAssert("seven items in batches of three",len(aBatches),3)

# the last batch has the rest
dnAssert("the last batch",len(aBatches[3].toList()),1)

# Pairwise with a result selector
aSums = oMore.callGeneric("Pairwise",["System.Double","System.Double"],[aNumbers,dnCallback("addPair")]).toList()
dnAssert("pairs of neighbours",len(aSums),6)
dnAssert("the sum of the first pair",aSums[1],3)

# the item with the most / least of a key
aMost = oMore.callGeneric("MaxBy",["System.Double","System.Double"],[aNumbers,dnCallback("negative")]).toList()          # MaxBy gives the items that have the greatest key
dnAssert("MaxBy of a negated key is the smallest item",aMost[1],1)

# Interleave, Zip... : Cartesian
aText = ["a","b"]
aCrossed = oMore.callGeneric("Cartesian",["System.String","System.String","System.String"],[aText,["x","y","z"],dnCallback("joinPair")]).toList()
dnAssert("the product of two lists",len(aCrossed),6)
dnAssert("the first pair",aCrossed[1],"ax")
dnAssert("the last pair",aCrossed[6],"bz")

# Index, and Scan (a running total)
aRunning = oMore.callGeneric("Scan",["System.Double"],[aNumbers,dnCallback("addPair")]).toList()
dnAssert("a running total",aRunning[7],28)

dnTestSummary()

func addPair aArgs

	return aArgs[1] + aArgs[2]

func negative aArgs

	return 0 - aArgs[1]

func joinPair aArgs

	return aArgs[1] + aArgs[2]
