# Parlot: parser combinators (Terms for numbers, strings and names; ZeroOrMany and Separated for lists), made from Ring and run on texts
load "pkg.ring"
pkgUse("parlot",[["Parlot","2.5.1"]],[["Parlot.dll",["Parlot","Parlot.Fluent"]]])
pkgImport("parlot","Parlot.dll","Parlot.Fluent")

# Terms is a static property of Parsers: the builder of the parsers that skip the white space before them
oParsers = dnType("Parlot.Fluent.Parsers")
oTerms = oParsers.getProp("Terms")

oInteger = oTerms.Integer(NULL)
dnAssert("an integer",oInteger.callMethod("Parse",["123"]),123)
dnAssert("the white space before a term is skipped",oInteger.callMethod("Parse",["   42"]),42)
dnAssert("a negative number",oInteger.callMethod("Parse",["-7"]),-7)

oDecimal = oTerms.Decimal(NULL)
dnAssert("a decimal number",oDecimal.callMethod("Parse",["3.25"]),3.25)

oString = oTerms.String(NULL)
dnAssert("a quoted string without its quotes",oString.callMethod("Parse",['"hello world"']).ToString(),"hello world")
oName = oTerms.Identifier(NULL)
dnAssert("a name",oName.callMethod("Parse",["total_1"]).ToString(),"total_1")

# an input that does not match gives the default value of the result type
dnAssert("text is not an integer: the default number",oInteger.callMethod("Parse",["abc"]),0)
dnAssert("a name cannot start with a digit: an empty text",oName.callMethod("Parse",["123abc"]).ToString(),"")

# lists: the same integer parser many times, and with a separator
oMany = oParsers.callGeneric("ZeroOrMany",["System.Int64"],[oInteger])
aNumbers = oMany.callMethod("Parse",["10 20 30 40"]).toList()
dnAssert("a list of numbers",len(aNumbers),4)
dnAssert("the last number",aNumbers[4],40)

oComma = oTerms.Char(",")
oSeparated = oParsers.callGeneric("Separated",["System.Char","System.Int64"],[oComma,oInteger])
aItems = oSeparated.callMethod("Parse",["1, 2,3 , 5"]).toList()
dnAssert("numbers with a separator",len(aItems),4)
dnAssert("the third number",aItems[3],3)

dnTestSummary()
