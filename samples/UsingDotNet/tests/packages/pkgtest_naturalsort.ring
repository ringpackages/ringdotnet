# NaturalSort.Extension: a string comparer that sorts numbers inside text by their value (file2 before file10), made from a StringComparison
load "pkg.ring"
pkgUse("naturalsort",[["NaturalSort.Extension","4.4.1"]],[["NaturalSort.Extension.dll",["NaturalSort.Extension"]]])
pkgImport("naturalsort","NaturalSort.Extension.dll","NaturalSort.Extension")

# the comparer is made from a StringComparison (an enum: its name is a text in Ring)
oComparer = new NaturalSortComparer("OrdinalIgnoreCase")
dnAssert("a comparer is an object",classname(oComparer),"naturalsortcomparer")

dnAssert("2 is before 10 (a plain text sort puts 10 first)",oComparer.Compare("file2","file10") < 0,1)
dnAssert("10 is after 2",oComparer.Compare("file10","file2") > 0,1)
dnAssert("equal texts",oComparer.Compare("file7","file7"),0)
dnAssert("the case is ignored with OrdinalIgnoreCase",oComparer.Compare("File7","file7"),0)
dnAssert("a number in the middle",oComparer.Compare("a1b20","a1b3") > 0,1)
dnAssert("the order of other text is kept",oComparer.Compare("apple","banana") < 0,1)
dnAssert("zeros before a number do not change its value",oComparer.Compare("v007","v8") < 0,1)

# sorting a list with the comparer: the comparer is called for each pair
aNames = ["img12","img10","img2","img1"]
nMax = len(aNames)
for nPass = 1 to nMax
	for nItem = 1 to nMax - 1
		if oComparer.Compare(aNames[nItem],aNames[nItem + 1]) > 0
			cTemp = aNames[nItem]
			aNames[nItem] = aNames[nItem + 1]
			aNames[nItem + 1] = cTemp
		ok
	next
next
dnAssert("a list sorted with the comparer",aNames[1] + " " + aNames[2] + " " + aNames[3] + " " + aNames[4],"img1 img2 img10 img12")

# the same strings with the case taken in
oStrict = new NaturalSortComparer("Ordinal")
dnAssert("Ordinal tells the case apart",oStrict.Compare("File7","file7") != 0,1)

dnTestSummary()
