# Sprache: a parser built from combinators. Parser<T> is a delegate type that extension methods extend, so a parser is an object with methods
# (oParser.AtLeastOnce().Text()) and the static form (Parse.AtLeastOnce(parser)) works too.
load "pkg.ring"
pkgUse("sprache",[["Sprache","2.3.1"]],[["Sprache.dll",["Sprache"]]])
pkgImport("sprache","Sprache.dll","Sprache")

oDigits = dnStatic("Sprache.Parse","Digit",[]).AtLeastOnce().Text()
dnAssert("digits",oDigits.Parse("12345"),"12345")

oLetters = dnStatic("Sprache.Parse","Letter",[]).Many().Text()
dnAssert("letters",oLetters.Parse("abc"),"abc")

oIdentifier = dnStatic("Sprache.Parse","Identifier",[dnStatic("Sprache.Parse","Letter",[]),dnStatic("Sprache.Parse","LetterOrDigit",[])])
dnAssert("an identifier",oIdentifier.Parse("name42"),"name42")

dnAssert("a decimal number",dnStatic("Sprache.Parse","Decimal",[]).Parse("3.5"),"3.5")

# the static form of an extension method
dnAssert("the static form gives the same parser",dnType("Sprache.ParserExtensions").callMethod("Parse",[oDigits,"7"]),"7")

# a failure is an exception that names the position
cError = ""
try
	oDigits.Parse("abc")
catch
	cError = cCatchError
done
dnAssert("a failed parse raises an error",len(cError) > 0,1)

# TryParse returns a result object
oResult = oDigits.TryParse("99")
dnAssert("TryParse: was successful",oResult.WasSuccessful,1)
dnAssert("TryParse: the value",oResult.Value,"99")
dnAssert("TryParse on bad input",oDigits.TryParse("x").WasSuccessful,0)

dnTestSummary()
