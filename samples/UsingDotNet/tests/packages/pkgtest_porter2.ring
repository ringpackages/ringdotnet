# Porter2Stemmer: English words reduced to their stems (a stemmer object that returns a result with Value)
load "pkg.ring"
pkgUse("porter2",[["Porter2Stemmer","1.0.0"]],[["Porter2Stemmer.dll",["Porter2Stemmer"]]])
pkgImport("porter2","Porter2Stemmer.dll","Porter2Stemmer")

oStemmer = new EnglishPorter2Stemmer()
dnAssert("running",oStemmer.Stem("running").Value,"run")
dnAssert("happiness",oStemmer.Stem("happiness").Value,"happi")
dnAssert("connection",oStemmer.Stem("connection").Value,"connect")
dnAssert("a plural",oStemmer.Stem("languages").Value,"languag")
dnAssert("caresses",oStemmer.Stem("caresses").Value,"caress")
dnAssert("an unchanged word",oStemmer.Stem("ring").Value,"ring")

aWords = ["connect","connected","connecting","connection","connections"]
for cWord in aWords
	if oStemmer.Stem(cWord).Value != "connect"
		dnAssert("a form of connect: " + cWord,0,1)
	ok
next
dnAssert("five forms, one stem",1,1)

dnTestSummary()
