# Superpower: parser combinators over text; the parsers are generic objects (TextParser<T>) made by static properties and methods, and combined with
# extension methods (Many, Then, Or, Between). The answer of TryParse is a struct of a generic type: it is read with getProp and callMethod.
load "pkg.ring"
pkgUse("superpower",[["Superpower","3.1.0"]],[["Superpower.dll",["Superpower","Superpower.Parsers"]]])
pkgImport("superpower","Superpower.dll","Superpower")
pkgImport("superpower","Superpower.dll","Superpower.Parsers")

oInteger = dnStatic("Superpower.Parsers.Numerics","get_Integer",[])
oResult = oInteger.TryParse("123 rest")
dnAssert("an integer is parsed",oResult.getProp("HasValue"),1)
dnAssert("the text of the integer",oResult.getProp("Value").callMethod("ToStringValue",[]),"123")
dnAssert("the rest of the input",oResult.getProp("Remainder").callMethod("ToStringValue",[])," rest")
dnAssert("text that is not an integer",oInteger.TryParse("abc").getProp("HasValue"),0)
dnAssert("the error of a parser that failed",len(oInteger.TryParse("abc").ToString()) > 0,1)

# the letters, repeated: Many gives a parser of an array of characters
oLetter = dnStatic("Superpower.Parsers.Character","get_Letter",[])
oLetters = dnStatic("Superpower.Combinators","Many",[oLetter])
oMany = oLetters.TryParse("abc123")
dnAssert("Many parses the letters",oMany.getProp("HasValue"),1)
dnAssert("the letters that were found",len(oMany.getProp("Value").toList()),3)
dnAssert("the first letter",oMany.getProp("Value").toList()[1],"a")

# an exact text, and a choice between two of them
oHello = dnStatic("Superpower.Parsers.Span","EqualTo",["hello"])
oWorld = dnStatic("Superpower.Parsers.Span","EqualTo",["world"])
oEither = dnStatic("Superpower.Combinators","Or",[oHello,oWorld])
dnAssert("the first choice",oEither.TryParse("hello").getProp("HasValue"),1)
dnAssert("the second choice",oEither.TryParse("world").getProp("HasValue"),1)
dnAssert("neither of them",oEither.TryParse("other").getProp("HasValue"),0)

# Select turns the parsed text into another value with a Ring callback (Func<TextSpan,int>); the type arguments are given
oCombinators = dnType("Superpower.Combinators")
oNumber = oCombinators.callGeneric("Select",["Superpower.Model.TextSpan","System.Int32"],[oInteger,dnCallback("spanToNumber")])
dnAssert("the number made by the callback",oNumber.TryParse("42").getProp("Value"),84)
# two numbers with a comma between them: Then runs the second parser after the first and keeps the second value
oComma = dnStatic("Superpower.Parsers.Character","EqualTo",[","])
oAfterComma = oCombinators.callGeneric("IgnoreThen",["System.Char","Superpower.Model.TextSpan"],[oComma,oInteger])
dnAssert("a comma and then an integer",oAfterComma.TryParse(",7").getProp("Value").callMethod("ToStringValue",[]),"7")
dnAssert("without the comma it fails",oAfterComma.TryParse("7").getProp("HasValue"),0)

dnTestSummary()

func spanToNumber aArgs

	return number(aArgs[1].callMethod("ToStringValue",[])) * 2
