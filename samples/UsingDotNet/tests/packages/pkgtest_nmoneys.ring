# NMoneys: money values with a currency (ISO 4217): amounts, arithmetic, formatting by currency, parsing, rounding and a currency that has no decimals
load "pkg.ring"
pkgUse("nmoneys",[["NMoneys","7.0.0"]],[["NMoneys.dll",["NMoneys"]]])
pkgImport("nmoneys","NMoneys.dll","NMoneys")

oMoney = new Money()
oTen = dnNew("NMoneys.Money",[10,"USD"])
dnAssert("the amount",oTen.Amount,10)
dnAssert("the currency code",oTen.CurrencyCode,"USD")
dnAssert("a whole amount has no decimals",oTen.HasDecimals,False)

oPrice = oMoney.ForMinor([ :amountMinor = 1999, :threeLetterIsoCode = "USD" ])
dnAssert("a price in cents: the amount",oPrice.Amount,19.99)
dnAssert("a price has decimals",oPrice.HasDecimals,True)
dnAssert("the major part",oPrice.MajorIntegralAmount,19)
dnAssert("the minor part",oPrice.MinorIntegralAmount,1999)

# arithmetic
oSum = oTen.Plus(oPrice)
dnAssert("a sum",oSum.Amount,29.99)
oDifference = oTen.Minus(oPrice)
dnAssert("a difference",oDifference.Amount,-9.99)
dnAssert("a negative value",oDifference.IsNegative(),True)
dnAssert("the absolute value",oDifference.Abs().Amount,9.99)
dnAssert("a positive value",oTen.IsPositive(),True)
dnAssert("a comparison",oTen.CompareTo(oPrice) < 0,True)
oThree = oTen.Times(3)
dnAssert("a multiple",oThree.Amount,30)
dnAssert("the zero of a currency",oMoney.Zero([ :threeLetterIsoCode = "USD" ]).IsZero(),True)

# rounding
oOdd = dnNew("NMoneys.Money",[12.345,"USD"])
dnAssert("a value with a third decimal",oOdd.Amount,12.345)
dnAssert("truncated to a whole number",oOdd.Truncate().Amount,12)
dnAssert("the floor of a value",oOdd.Floor().Amount,12)
dnAssert("the ceiling of a value",oOdd.Ceiling().Amount,13)

# a currency that has no decimals
oYen = dnNew("NMoneys.Money",[1500,"JPY"])
dnAssert("yen have no decimal digits",oYen.GetCurrency().SignificantDecimalDigits,0)
dnAssert("a yen amount",oYen.Amount,1500)

# the currency object
oCurrency = oTen.GetCurrency()
dnAssert("the English name",oCurrency.EnglishName,"US Dollar")
dnAssert("the symbol",oCurrency.Symbol,"$")
dnAssert("the number code",oCurrency.NumericCode,840)
dnAssert("the decimal digits",oCurrency.SignificantDecimalDigits,2)
dnAssert("euro symbol",oCurrency.Euro.Symbol,"€")

# money of two currencies cannot be added
lError = 0
try
	oTen.Plus(oYen)
catch
	lError = 1
done
dnAssert("another currency raises an error",lError,1)
dnAssert("the same currency check",oTen.HasSameCurrencyAs(oPrice),True)
dnAssert("another currency check",oTen.HasSameCurrencyAs(oYen),False)

dnTestSummary()
