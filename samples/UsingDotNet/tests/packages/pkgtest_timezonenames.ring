# TimeZoneNames: localized names of time zones, abbreviations, the zones of a country and the names of countries, from the CLDR data inside the package
load "pkg.ring"
pkgUse("timezonenames",[["TimeZoneNames","7.0.0"]],[["TimeZoneNames.dll",["TimeZoneNames"]]])
pkgImport("timezonenames","TimeZoneNames.dll","TimeZoneNames")

oNames = new TZNames()

# the zones of a country
aEgypt = oNames.GetTimeZoneIdsForCountry("EG").toList()
dnAssert("Egypt has one zone",len(aEgypt),1)
dnAssert("the zone of Egypt",aEgypt[1],"Africa/Cairo")
aUs = oNames.GetTimeZoneIdsForCountry("US").toList()
dnAssert("the United States have many zones",len(aUs) > 5,True)
dnAssert("New York is one of them",find(aUs,"America/New_York") > 0,True)

# the names of a zone, in English and in other languages
oEnglish = oNames.GetNamesForTimeZone("America/New_York","en-US")
dnAssert("the generic name",oEnglish.Generic,"Eastern Time")
dnAssert("the standard name",oEnglish.Standard,"Eastern Standard Time")
dnAssert("the daylight name",oEnglish.Daylight,"Eastern Daylight Time")
oGerman = oNames.GetNamesForTimeZone("Europe/Berlin","de-DE")
dnAssert("the German standard name",oGerman.Standard,"Mitteleuropäische Normalzeit")
oArabic = oNames.GetNamesForTimeZone("Africa/Cairo","ar")
dnAssert("the Arabic name is not empty",len(oArabic.Generic) > 0,True)

# abbreviations
oAbbreviations = oNames.GetAbbreviationsForTimeZone("America/New_York","en-US")
dnAssert("the standard abbreviation",oAbbreviations.Standard,"EST")
dnAssert("the daylight abbreviation",oAbbreviations.Daylight,"EDT")

# the display name that a list of zones would show
cDisplay = oNames.GetDisplayNameForTimeZone("America/New_York","en-US")
dnAssert("the display name",cDisplay,"(UTC-05:00) Eastern Time (US & Canada)")

# the names of countries
oCountries = oNames.GetCountryNames("en-US")
dnAssert("Egypt in English",oCountries.callMethod("get_Item",["EG"]),"Egypt")
dnAssert("Japan in English",oCountries.callMethod("get_Item",["JP"]),"Japan")
oCountriesFr = oNames.GetCountryNames("fr-FR")
dnAssert("Germany in French",oCountriesFr.callMethod("get_Item",["DE"]),"Allemagne")

dnAssert("a list of countries has many names",oCountries.getProp("Count") > 200,True)

dnTestSummary()
