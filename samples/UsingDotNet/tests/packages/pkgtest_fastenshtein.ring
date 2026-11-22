# Fastenshtein: the Levenshtein distance between texts, as a static method and as an object that keeps the first text
load "pkg.ring"
pkgUse("fastenshtein",[["Fastenshtein","1.1.1"]],[["Fastenshtein.dll",["Fastenshtein"]]])
pkgImport("fastenshtein","Fastenshtein.dll","Fastenshtein")

dnAssert("kitten to sitting",dnStatic("Fastenshtein.Levenshtein","Distance",["kitten","sitting"]),3)
dnAssert("equal texts",dnStatic("Fastenshtein.Levenshtein","Distance",["ring","ring"]),0)
dnAssert("an empty text",dnStatic("Fastenshtein.Levenshtein","Distance",["","abc"]),3)
dnAssert("one substitution",dnStatic("Fastenshtein.Levenshtein","Distance",["flaw","flax"]),1)

# an object that compares many texts with the first one
oCompare = new Levenshtein("kitten")
dnAssert("the object compares with a text",oCompare.DistanceFrom("sitting"),3)
dnAssert("and with another",oCompare.DistanceFrom("mitten"),1)
dnAssert("and with itself",oCompare.DistanceFrom("kitten"),0)

# the best match in a list
aWords = ["apple","apply","ample","maple","ape"]
oApple = new Levenshtein("appel")
nBest = 100
cBest = ""
for cWord in aWords
	nDistance = oApple.DistanceFrom(cWord)
	if nDistance < nBest
		nBest = nDistance
		cBest = cWord
	ok
next
dnAssert("the closest word",cBest,"apple")
dnAssert("its distance",nBest,2)

dnTestSummary()
