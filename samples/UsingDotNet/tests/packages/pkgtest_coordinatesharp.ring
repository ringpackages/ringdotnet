# CoordinateSharp: geographic coordinates (degrees, UTM, MGRS), the distance between two places, and the position of the sun for a date
load "pkg.ring"
pkgUse("coordsharp",[["CoordinateSharp","3.5.1.1"]],[["CoordinateSharp.dll",["CoordinateSharp"]]])
pkgImport("coordsharp","CoordinateSharp.dll","CoordinateSharp")

using {
	"System"
}

# the Eiffel Tower
oEiffel = (new Coordinate).@New([ :lat = 48.8584, :longi = 2.2945 ])
oLatitude = oEiffel.Latitude
oLongitude = oEiffel.Longitude
dnAssert("the latitude as a number",floor(oLatitude.ToDouble() * 10000),488584)
dnAssert("the degrees of the latitude",oLatitude.Degrees,48)
dnAssert("the minutes of the latitude",oLatitude.Minutes,51)
dnAssert("the position of the latitude",oLatitude.Position,"N")
dnAssert("the longitude is east",oLongitude.Position,"E")

# UTM: the zone and the metres
oUtm = oEiffel.UTM
dnAssert("the UTM zone number",oUtm.LongZone,31)
dnAssert("the UTM latitude band",oUtm.LatZone,"U")
dnAssert("the UTM easting (metres)",floor(oUtm.Easting / 100),4482)
dnAssert("the UTM northing (metres)",floor(oUtm.Northing / 100),54119)

# the military grid reference system
oMgrs = oEiffel.MGRS
dnAssert("the MGRS zone",oMgrs.LongZone,31)
dnAssert("the MGRS square",oMgrs.Digraph,"DQ")

# a coordinate in the southern and western halves has the other signs
oRio = (new Coordinate).@New([ :lat = -22.9068, :longi = -43.1729 ])
oRioLatitude = oRio.Latitude
dnAssert("the south",oRioLatitude.Position,"S")
dnAssert("a negative latitude as a number",oRioLatitude.ToDouble() < 0,1)

# the distance between two places: Paris and London
oLondon = (new Coordinate).@New([ :lat = 51.5074, :longi = -0.1278 ])
oDistance = (new Distance).@New([ :coord1 = oEiffel, :coord2 = oLondon ])
nKm = oDistance.Kilometers
dnAssert("Paris to London is about 340 km",nKm > 330 and nKm < 350,1)
dnAssert("miles are fewer than kilometers",oDistance.Miles < nKm,1)

# the sun on the longest day in Paris: it rises early in the morning (UTC) and sets in the evening
oDate = new DateTime(2024,6,21)
oSun = (new Coordinate).@New([ :lat = 48.8584, :longi = 2.2945, :date = oDate ])
oCelestial = oSun.CelestialInfo
oRise = oCelestial.SunRise
oSet = oCelestial.SunSet
dnAssert("the sun rises before 5 UTC in June",oRise.Hour < 5,1)
dnAssert("the sun sets after 19 UTC in June",oSet.Hour >= 19,1)

dnTestSummary()
