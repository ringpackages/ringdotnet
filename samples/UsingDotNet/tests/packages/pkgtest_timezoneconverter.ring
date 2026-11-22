# TimeZoneConverter: IANA and Windows names, converted to TimeZoneInfo; offsets with and without daylight saving
load "pkg.ring"
pkgUse("tzc",[["TimeZoneConverter","7.0.0"]],[["TimeZoneConverter.dll",["TimeZoneConverter"]]])
pkgImport("tzc","TimeZoneConverter.dll","TimeZoneConverter")

oCairo = dnStatic("TimeZoneConverter.TZConvert","GetTimeZoneInfo",["Africa/Cairo"])
dnAssert("a zone from an IANA name",oCairo.Id != "",1)
oEastern = dnStatic("TimeZoneConverter.TZConvert","GetTimeZoneInfo",["Eastern Standard Time"])
oNewYork = dnStatic("TimeZoneConverter.TZConvert","GetTimeZoneInfo",["America/New_York"])
dnAssert("a Windows name and an IANA name are the same offset",oEastern.BaseUtcOffset.TotalHours,oNewYork.BaseUtcOffset.TotalHours)
dnAssert("New York is five hours behind",oNewYork.BaseUtcOffset.TotalHours,-5)

dnAssert("IANA to Windows",dnStatic("TimeZoneConverter.TZConvert","IanaToWindows",["America/New_York"]),"Eastern Standard Time")
dnAssert("Windows to IANA",dnStatic("TimeZoneConverter.TZConvert","WindowsToIana",["Eastern Standard Time"]),"America/New_York")
dnAssert("a known name",dnStatic("TimeZoneConverter.TZConvert","KnownIanaTimeZoneNames",[]).Count > 100,1)

# daylight saving: July in New York is four hours behind UTC
oJuly = dnNew("System.DateTime",[ :year = 2024, :month = 7, :day = 1, :hour = 12, :minute = 0, :second = 0, :kind = "Unspecified" ])
dnAssert("the offset in July",oNewYork.GetUtcOffset(oJuly).TotalHours,-4)
oJan = dnNew("System.DateTime",[ :year = 2024, :month = 1, :day = 1, :hour = 12, :minute = 0, :second = 0, :kind = "Unspecified" ])
dnAssert("the offset in January",oNewYork.GetUtcOffset(oJan).TotalHours,-5)

# an unknown name is an error
cError = ""
try
	dnStatic("TimeZoneConverter.TZConvert","GetTimeZoneInfo",["Nowhere/Land"])
catch
	cError = cCatchError
done
dnAssert("an unknown zone raises an error",len(cError) > 0,1)

dnTestSummary()
