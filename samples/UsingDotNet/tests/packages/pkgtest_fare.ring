# Fare: random text from a regular expression (Xeger); the result must match the expression
load "pkg.ring"
pkgUse("fare",[["Fare","2.2.1"]],[["Fare.dll",["Fare"]]])
pkgImport("fare","Fare.dll","Fare")
dnImport("System.Text.RegularExpressions")

cPattern = "[a-z]{3}-[0-9]{2}"
oXeger = new Xeger(cPattern)
oRegex = new Regex("^" + cPattern + "$")
for i = 1 to 20
	cText = oXeger.Generate()
	if not oRegex.IsMatch(cText)
		dnAssert("a generated text matches " + cText,0,1)
	ok
next
dnAssert("20 generated texts all matched",1,1)
dnAssert("the length is fixed by the expression",len(oXeger.Generate()),6)

oFixed = new Xeger("ab(c|d)")
cOne = oFixed.Generate()
dnAssert("an alternation",cOne = "abc" or cOne = "abd",1)

dnTestSummary()
