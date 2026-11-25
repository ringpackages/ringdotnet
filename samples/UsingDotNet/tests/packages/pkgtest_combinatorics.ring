# Combinatorics: permutations, combinations and variations of a list; the generic classes are made with their type argument, and the results are lists of lists
load "pkg.ring"
pkgUse("combinatorics",[["Combinatorics","2.0.0"]],[["Combinatorics.dll",["Combinatorics.Collections"]]])
pkgImport("combinatorics","Combinatorics.dll","Combinatorics.Collections")

cList = "System.Collections.Generic.List`1[[System.Int32]]"
oItems = dnNew(cList,[])
oItems.Add(1)
oItems.Add(2)
oItems.Add(3)
oPermutations = dnNew("Combinatorics.Collections.Permutations`1[[System.Int32]]",[oItems])
dnAssert("3 items have 6 permutations (the count is a BigInteger)",oPermutations.Count.ToString(),"6")
aAll = oPermutations.toList()
dnAssert("the permutations as a list",len(aAll),6)
dnAssert("the first permutation keeps the order",aAll[1].toList()[1],1)
aLast = aAll[6].toList()
dnAssert("the last permutation is the items reversed",aLast[1] * 100 + aLast[2] * 10 + aLast[3],321)

# every permutation is different
aSeen = []
for oPermutation in aAll
	aItem = oPermutation.toList()
	cKey = "" + aItem[1] + "," + aItem[2] + "," + aItem[3]
	if find(aSeen,cKey) = 0
		aSeen + cKey
	ok
next
dnAssert("six different permutations",len(aSeen),6)

# combinations: 2 of 4 items, in order, with the lower index first
oFour = dnNew(cList,[])
for n = 10 to 40 step 10
	oFour.Add(n)
next
oCombinations = dnNew("Combinatorics.Collections.Combinations`1[[System.Int32]]",[oFour,2])
dnAssert("4 over 2 is 6",oCombinations.Count.ToString(),"6")
dnAssert("the size of a combination",oCombinations.LowerIndex,2)
aPairs = oCombinations.toList()
dnAssert("the first pair",aPairs[1].toList()[1] + aPairs[1].toList()[2],30)
dnAssert("the last pair",aPairs[6].toList()[1] + aPairs[6].toList()[2],70)

# variations with repetition: 3 items taken 2 at a time give 9
oVariations = dnNew("Combinatorics.Collections.Variations`1[[System.Int32]]",[oItems,2,"WithRepetition"])
dnAssert("3 items taken 2 at a time with repetition",oVariations.Count.ToString(),"9")
oWithout = dnNew("Combinatorics.Collections.Variations`1[[System.Int32]]",[oItems,2])
dnAssert("without repetition",oWithout.Count.ToString(),"6")

# the number of the permutations of a list that has equal items
oEqual = dnNew(cList,[])
oEqual.Add(1)
oEqual.Add(1)
oEqual.Add(2)
dnAssert("equal items make fewer permutations",dnNew("Combinatorics.Collections.Permutations`1[[System.Int32]]",[oEqual]).Count.ToString(),"3")
dnTestSummary()
