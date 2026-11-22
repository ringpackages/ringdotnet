# GeoJSON.Net: geometry objects that serialize with Newtonsoft.Json; positions, points, line strings, features
load "pkg.ring"
pkgUse("geojson",[["GeoJSON.Net","1.4.1"]],[["GeoJSON.Net.dll",["GeoJSON.Net.Geometry","GeoJSON.Net.Feature"]],["Newtonsoft.Json.dll",[]]])
pkgImport("geojson","GeoJSON.Net.dll","GeoJSON.Net.Geometry")
pkgImport("geojson","GeoJSON.Net.dll","GeoJSON.Net.Feature")

oPosition = dnNew("GeoJSON.Net.Geometry.Position",[ :latitude = 30.05, :longitude = 31.25 ])
dnAssert("a latitude",oPosition.Latitude,30.05)
dnAssert("a longitude",oPosition.Longitude,31.25)

oPoint = dnNew("GeoJSON.Net.Geometry.Point",[ :coordinates = oPosition ])
cJson = dnStatic("Newtonsoft.Json.JsonConvert","SerializeObject",[oPoint])
dnAssert("a point as GeoJSON",substr(cJson,'"type":"Point"') > 0,1)
dnAssert("the coordinates are longitude first",substr(cJson,"[31.25,30.05]") > 0,1)

oBack = dnType("Newtonsoft.Json.JsonConvert").callGeneric("DeserializeObject",["GeoJSON.Net.Geometry.Point"],[cJson])
dnAssert("read back: latitude",oBack.Coordinates.Latitude,30.05)

oFeature = dnNew("GeoJSON.Net.Feature.Feature",[ :geometry = oPoint ])
dnAssert("a feature has a geometry",oFeature.Geometry.Type,"Point")
dnAssert("a feature as GeoJSON",substr(dnStatic("Newtonsoft.Json.JsonConvert","SerializeObject",[oFeature]),'"type":"Feature"') > 0,1)

dnTestSummary()
