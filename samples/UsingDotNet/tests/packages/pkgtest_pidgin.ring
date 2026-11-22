# Pidgin: parser combinators with the input type and the result type as generic arguments (Parser<char, T>)
load "pkg.ring"
pkgUse("pidgin",[["Pidgin","3.3.0"]],[["Pidgin.dll",["Pidgin"]]])
pkgImport("pidgin","Pidgin.dll","Pidgin")

oDigit = dnStatic("Pidgin.Parser","Digit",[])
oDigits = oDigit.AtLeastOnceString()
dnAssert("digits",oDigits.ParseOrThrow("12345"),"12345")

oLetters = dnStatic("Pidgin.Parser","Letter",[]).ManyString()
dnAssert("letters",oLetters.ParseOrThrow("abc"),"abc")

dnAssert("a number",dnStatic("Pidgin.Parser","Num",[]).ParseOrThrow("42"),42)

cError = ""
try
	oDigits.ParseOrThrow("abc")
catch
	cError = cCatchError
done
dnAssert("a failed parse raises an error",len(cError) > 0,1)

dnTestSummary()
