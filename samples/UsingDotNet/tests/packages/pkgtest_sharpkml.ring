# SharpKml: KML documents (the format of Google Earth) built as objects, written as text with a Serializer, and read again with a Parser
load "pkg.ring"
pkgUse("sharpkml",[["SharpKml.Core","6.1.0"]],[["SharpKml.Core.dll",["SharpKml.Dom","SharpKml.Base","SharpKml.Engine"]]])
pkgImport("sharpkml","SharpKml.Core.dll","SharpKml.Dom")
pkgImport("sharpkml","SharpKml.Core.dll","SharpKml.Base")
pkgImport("sharpkml","SharpKml.Core.dll","SharpKml.Engine")

oPoint = new Point()
oPoint.Coordinate = dnNew("SharpKml.Base.Vector",[30.05,31.23,10])
oPlacemark = new Placemark()
oPlacemark.Name = "Cairo"
oPlacemark.Geometry = oPoint
dnAssert("the name of a placemark",oPlacemark.Name,"Cairo")
dnAssert("the latitude of its point",oPlacemark.Geometry.Coordinate.Latitude,30.05)
dnAssert("its longitude",oPlacemark.Geometry.Coordinate.Longitude,31.23)
dnAssert("its altitude",oPlacemark.Geometry.Coordinate.Altitude,10)

# a document with two placemarks, written as KML text
oDocument = new Document()
oDocument.Name = "Cities"
oDocument.AddFeature(oPlacemark)
oLima = new Placemark()
oLima.Name = "Lima"
oLondon = new Point()
oLondon.Coordinate = dnNew("SharpKml.Base.Vector",[-12.04,-77.03])
oLima.Geometry = oLondon
oDocument.AddFeature(oLima)
oSerializer = new Serializer()
oSerializer.Serialize(oDocument)
cKml = oSerializer.Xml
dnAssert("the text is KML",substr(cKml,"<Document xmlns=") > 0,1)
dnAssert("it has the name of a placemark",substr(cKml,"<name>Cairo</name>") > 0,1)
dnAssert("it has the coordinates",substr(cKml,"<coordinates>31.23,30.05") > 0,1)

# read again: the parser gives the root and the elements by their types
oParser = new Parser()
oParser.ParseString(cKml,0)
oRoot = oParser.Root
dnAssert("the root is the document",oRoot.typeName(),"SharpKml.Dom.Document")
dnAssert("its name",oRoot.Name,"Cities")
aFeatures = oRoot.Features.toList()
dnAssert("two features",len(aFeatures),2)
dnAssert("the second is Lima",aFeatures[2].Name,"Lima")
dnAssert("the point of the first",aFeatures[1].Geometry.Coordinate.Latitude,30.05)

# a KML with a style and a line, built from text
cLine = '<kml xmlns="http://www.opengis.net/kml/2.2"><Placemark><name>Road</name><LineString><coordinates>1,2,0 3,4,0 5,6,0</coordinates></LineString></Placemark></kml>'
oLineParser = new Parser()
oLineParser.ParseString(cLine,0)
oRoad = oLineParser.Root
dnAssert("the root of a KML text is a kml element",oRoad.typeName(),"SharpKml.Dom.Kml")
dnAssert("the placemark has a line",oRoad.Feature.Geometry.Coordinates.Count,3)
dnAssert("a point of the line",oRoad.Feature.Geometry.Coordinates.toList()[2].Longitude,3)

# a point with no altitude has a null altitude
dnAssert("no altitude is null",dnIsNull(dnNew("SharpKml.Base.Vector",[1,2]).Altitude),1)

# text that is not KML gives no root (and no error)
oBad = new Parser()
oBad.ParseString("this is not xml",0)
dnAssert("text that is not XML gives no root",dnIsNull(oBad.Root),1)
dnTestSummary()
