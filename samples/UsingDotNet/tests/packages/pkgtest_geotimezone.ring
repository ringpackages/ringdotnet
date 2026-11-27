# GeoTimeZone: the IANA time zone of a place from its latitude and longitude (a static method that answers an object with the zone and its alternatives)
load "pkg.ring"
pkgUse("geotz",[["GeoTimeZone","7.0.0"]],[["GeoTimeZone.dll",["GeoTimeZone"]]])
pkgImport("geotz","GeoTimeZone.dll","GeoTimeZone")

oLookup = new TimeZoneLookup()
oParis = oLookup.GetTimeZone(48.8566,2.3522)
dnAssert("Paris",oParis.Result,"Europe/Paris")
oCairo = oLookup.GetTimeZone(30.0444,31.2357)
dnAssert("Cairo",oCairo.Result,"Africa/Cairo")
oTokyo = oLookup.GetTimeZone(35.6762,139.6503)
dnAssert("Tokyo",oTokyo.Result,"Asia/Tokyo")
oNewYork = oLookup.GetTimeZone(40.7128,-74.0060)
dnAssert("New York",oNewYork.Result,"America/New_York")
oSydney = oLookup.GetTimeZone(-33.8688,151.2093)
dnAssert("Sydney (south and east)",oSydney.Result,"Australia/Sydney")

# a place in the middle of the sea has a zone of the sea (Etc/GMT...), and the list of zones that a place has is a list
oSea = oLookup.GetTimeZone(0,-30)
dnAssert("the sea has an Etc zone",left(oSea.Result,4),"Etc/")

# one point near a border can have more than one zone
aZones = oParis.AlternativeResults.toList()
dnAssert("the alternatives are a list",isList(aZones),1)

# the time zone can be used with the .NET classes
oZone = new TimeZoneInfo().FindSystemTimeZoneById(oTokyo.Result)
dnAssert("Tokyo is 9 hours ahead of UTC",oZone.BaseUtcOffset.TotalHours,9)

dnTestSummary()
