# libphonenumber (PhoneNumbers; Parse and Format have several forms: the named list picks one): parse, validate and format phone numbers of many countries; the util is an object, numbers are objects, the formats are enums
load "pkg.ring"
pkgUse("phonenumbers",[["libphonenumber-csharp","9.0.43"]],[["PhoneNumbers.dll",["PhoneNumbers"]]])
pkgImport("phonenumbers","PhoneNumbers.dll","PhoneNumbers")

oUtil = dnStatic("PhoneNumbers.PhoneNumberUtil","GetInstance",[])
oNumber = parseNumber(oUtil,"+14155552671","ZZ")
dnAssert("the country code",oNumber.CountryCode,1)
dnAssert("the national number",oNumber.NationalNumber,4155552671)
dnAssert("the number is valid",oUtil.IsValidNumber(oNumber),1)

# a number written nationally, with the region
oNational = parseNumber(oUtil,"(415) 555-2671","US")
dnAssert("the same number from a national form",oNational.NationalNumber,4155552671)

# the formats
dnAssert("the E.164 format",oUtil.Format([ :number = oNumber, :numberFormat = dnStatic("PhoneNumbers.PhoneNumberFormat","E164",[]) ]),"+14155552671")
dnAssert("the international format",oUtil.Format([ :number = oNumber, :numberFormat = dnStatic("PhoneNumbers.PhoneNumberFormat","INTERNATIONAL",[]) ]),"+1 415-555-2671")
dnAssert("the national format",oUtil.Format([ :number = oNumber, :numberFormat = dnStatic("PhoneNumbers.PhoneNumberFormat","NATIONAL",[]) ]),"(415) 555-2671")

# the type and the region
dnAssert("the region of the number",oUtil.GetRegionCodeForNumber(oNumber),"US")

# an Egyptian mobile number
oEgypt = parseNumber(oUtil,"+201001234567","ZZ")
dnAssert("the region of an Egyptian number",oUtil.GetRegionCodeForNumber(oEgypt),"EG")
dnAssert("a mobile number",oUtil.GetNumberType(oEgypt),"MOBILE")
dnAssert("the Egyptian number is valid",oUtil.IsValidNumber(oEgypt),1)

# a number that is not valid, and a text that does not parse
dnAssert("a number with too few digits is not valid",oUtil.IsValidNumber(parseNumber(oUtil,"+1415555","ZZ")),0)
try
	parseNumber(oUtil,"not a number","US")
	dnAssert("a text that is not a number is an error",1,0)
catch
	dnAssert("a text that is not a number is an error",substr(cCatchError,"NumberParseException") > 0,1)
done

# the example number of a country
dnAssert("an example number of Germany",oUtil.IsValidNumber(oUtil.GetExampleNumber("DE")),1)

dnTestSummary()

func parseNumber oUtil, cText, cRegion

	return oUtil.Parse([ :numberToParse = cText, :defaultRegion = cRegion ])
