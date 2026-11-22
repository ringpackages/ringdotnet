# Sprache: a parser built from combinators. Parser<T> is a delegate type, so the combinators are called as static methods (Parse.AtLeastOnce(parser))
load "pkg.ring"
pkgUse("sprache",[["Sprache","2.3.1"]],[["Sprache.dll",["Sprache"]]])
pkgImport("sprache","Sprache.dll","Sprache")

oDigit = sp("Digit",[])
oDigits = sp("Text",[sp("AtLeastOnce",[oDigit])])
dnAssert("digits",spRun(oDigits,"12345"),"12345")

oLetters = sp("Text",[sp("Many",[sp("Letter",[])])])
dnAssert("letters",spRun(oLetters,"abc"),"abc")

oIdentifier = sp("Identifier",[sp("Letter",[]),sp("LetterOrDigit",[])])
dnAssert("an identifier",spRun(oIdentifier,"name42"),"name42")

dnAssert("a decimal number",spRun(sp("Decimal",[]),"3.5"),"3.5")

# a failure is an exception that names the position
cError = ""
try
	spRun(oDigits,"abc")
catch
	cError = cCatchError
done
dnAssert("a failed parse raises an error",len(cError) > 0,1)

# TryParse returns a result object
oResult = spTry(oDigits,"99")
dnAssert("TryParse: was successful",oResult.WasSuccessful,1)
dnAssert("TryParse: the value",oResult.Value,"99")
dnAssert("TryParse on bad input",spTry(oDigits,"x").WasSuccessful,0)

dnTestSummary()

func sp cName, aArgs
	return dnType("Sprache.Parse").callMethod(cName,aArgs)

func spRun oParser, cInput
	return dnType("Sprache.ParserExtensions").callMethod("Parse",[oParser,cInput])

func spTry oParser, cInput
	return dnType("Sprache.ParserExtensions").callMethod("TryParse",[oParser,cInput])
