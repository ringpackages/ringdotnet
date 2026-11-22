# VaderSharp2: sentiment scores of English text; a result object with Negative, Neutral, Positive and Compound as numbers
load "pkg.ring"
pkgUse("vader",[["VaderSharp2","3.3.2.1"]],[["VaderSharp2.dll",["VaderSharp2"]]])
pkgImport("vader","VaderSharp2.dll","VaderSharp2")

oAnalyzer = new SentimentIntensityAnalyzer()
oGood = oAnalyzer.PolarityScores("This is a great, wonderful library!")
oBad = oAnalyzer.PolarityScores("This is terrible and awful.")
oPlain = oAnalyzer.PolarityScores("The table is brown.")

dnAssert("a good text is positive",oGood.Compound > 0.5,1)
dnAssert("a bad text is negative",oBad.Compound < -0.5,1)
dnAssert("a plain text is neutral",oPlain.Compound,0)
dnAssert("the parts add up to one",fabs(oGood.Positive + oGood.Neutral + oGood.Negative - 1) < 0.01,1)
dnAssert("a good text has no negative part",oGood.Negative,0)
dnAssert("intensity grows with an exclamation",oAnalyzer.PolarityScores("Good!!!").Compound > oAnalyzer.PolarityScores("Good").Compound,1)
dnAssert("a negation turns it around",oAnalyzer.PolarityScores("This is not good").Compound < 0,1)

dnTestSummary()
