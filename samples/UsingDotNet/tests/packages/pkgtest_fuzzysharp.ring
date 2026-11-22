# FuzzySharp: fuzzy string matching; scores as integers, best match from a list, a tuple-like result object
load "pkg.ring"
pkgUse("fuzzysharp",[["FuzzySharp","2.0.2"]],[["FuzzySharp.dll",["FuzzySharp","FuzzySharp.Extractor"]]])
pkgImport("fuzzysharp","FuzzySharp.dll","FuzzySharp")
pkgImport("fuzzysharp","FuzzySharp.dll","FuzzySharp.Extractor")

dnAssert("identical texts score 100",dnStatic("FuzzySharp.Fuzz","Ratio",["ring","ring"]),100)
dnAssert("different texts score less",dnStatic("FuzzySharp.Fuzz","Ratio",["ring","rung"]) < 100,1)
dnAssert("nothing in common scores low",dnStatic("FuzzySharp.Fuzz","Ratio",["abc","xyz"]),0)
dnAssert("a partial ratio finds a part",dnStatic("FuzzySharp.Fuzz","PartialRatio",["ring","the ring language"]),100)
dnAssert("tokens in another order",dnStatic("FuzzySharp.Fuzz","TokenSortRatio",["new york mets","mets new york"]),100)
dnAssert("a set of tokens",dnStatic("FuzzySharp.Fuzz","TokenSetRatio",["a b c","c b a a"]),100)

aChoices = ["Atlanta Falcons","New York Jets","New York Giants","Dallas Cowboys"]
oBest = dnStatic("FuzzySharp.Process","ExtractOne",["cowboys",aChoices])
dnAssert("the best match",oBest.Value,"Dallas Cowboys")
dnAssert("its index",oBest.Index,3)
dnAssert("its score is high",oBest.Score > 80,1)

dnTestSummary()
