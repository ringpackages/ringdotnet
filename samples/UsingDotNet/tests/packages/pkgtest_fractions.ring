# Fractions: exact fractions as structs with operators (+ - * / < > =), parsing, reduction and conversion to text and numbers
load "pkg.ring"
pkgUse("fractions",[["Fractions","8.2.0"]],[["Fractions.dll",["Fractions"]]])
pkgImport("fractions","Fractions.dll","Fractions")

oHalf = dnStatic("Fractions.Fraction","FromString",["1/2"])
oThird = dnStatic("Fractions.Fraction","FromString",["1/3"])
dnAssert("a sum is exact",(oHalf + oThird).ToString(),"5/6")
dnAssert("a difference",(oHalf - oThird).ToString(),"1/6")
dnAssert("a product",(oHalf * oThird).ToString(),"1/6")
dnAssert("a quotient",(oHalf / oThird).ToString(),"3/2")
dnAssert("a comparison",oHalf > oThird,1)
dnAssert("an equality of reduced forms",dnStatic("Fractions.Fraction","FromString",["2/4"]) = oHalf,1)

dnAssert("reduction",dnStatic("Fractions.Fraction","FromString",["6/8"]).ToString(),"3/4")
dnAssert("a whole number",dnStatic("Fractions.Fraction","FromString",["4/2"]).ToString(),"2")
dnAssert("a decimal as a fraction",dnStatic("Fractions.Fraction","FromDouble",[0.75]).ToString(),"3/4")
dnAssert("a double from a fraction",oHalf.ToDouble(),0.5)
dnAssert("the numerator",oThird.Numerator.ToString(),"1")
dnAssert("the denominator",oThird.Denominator.ToString(),"3")
dnAssert("a negative fraction",(oThird - oHalf).ToString(),"-1/6")

dnTestSummary()
