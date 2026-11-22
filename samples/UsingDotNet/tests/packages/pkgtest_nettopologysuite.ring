# NetTopologySuite: geometries (points, polygons) from WKT and from coordinates, area, distance, relations, overlay (intersection, union, buffer), and WKT back
load "pkg.ring"
pkgUse("nts",[["NetTopologySuite","2.6.0"]],[["NetTopologySuite.dll",["NetTopologySuite.Geometries","NetTopologySuite.IO","NetTopologySuite.Algorithm"]]])
pkgImport("nts","NetTopologySuite.dll","NetTopologySuite.Geometries")
pkgImport("nts","NetTopologySuite.dll","NetTopologySuite.IO")

oReader = new WKTReader()
oSquare = oReader.Read("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))")
oOther = oReader.Read("POLYGON ((2 2, 6 2, 6 6, 2 6, 2 2))")
dnAssert("the type of a geometry",oSquare.GeometryType,"Polygon")
dnAssert("the area of a polygon",oSquare.Area,16)
dnAssert("the perimeter",oSquare.Length,16)
dnAssert("a polygon is valid",oSquare.IsValid,1)
dnAssert("the number of points of the boundary",oSquare.NumPoints,5)

# relations
dnAssert("the two squares intersect",oSquare.Intersects(oOther),1)
oPoint = oReader.Read("POINT (1 1)")
dnAssert("a point inside",oSquare.Contains(oPoint),1)
dnAssert("a point is not inside the other square",oOther.Contains(oPoint),0)
dnAssert("the distance between a point and a polygon",oReader.Read("POINT (10 0)").Distance(oSquare),6)

# overlay: the intersection is a 2 x 2 square, the union has the area 16 + 16 - 4
oCommon = oSquare.Intersection(oOther)
dnAssert("the intersection area",oCommon.Area,4)
dnAssert("the union area",oSquare.Union(oOther).Area,28)
dnAssert("the difference area",oSquare.Difference(oOther).Area,12)

# the envelope and the centroid
oBox = oSquare.EnvelopeInternal
dnAssert("the width of the envelope",oBox.Width,4)
dnAssert("the centroid x",oSquare.Centroid.X,2)

# a buffer around a point: a circle with the area near pi * r * r
oCircle = oPoint.Buffer(10)
dnAssert("the area of a buffer is near a circle",oCircle.Area > 310 and oCircle.Area < 315,1)

# geometries from coordinates by a factory
oFactory = new GeometryFactory()
oCoordinate = dnNew("NetTopologySuite.Geometries.Coordinate",[3,4])
oMade = oFactory.CreatePoint(oCoordinate)
dnAssert("a point from a coordinate",oMade.X,3)
dnAssert("its distance from the origin",oMade.Distance(oReader.Read("POINT (0 0)")),5)

# back to text
dnAssert("a point as WKT",oMade.ToText(),"POINT (3 4)")
dnAssert("equal geometries",oMade.EqualsExact(oReader.Read("POINT (3 4)")),1)

# bad WKT is an error
try
	oReader.Read("POLYGON ((not wkt")
	dnAssert("bad WKT is an error",1,0)
catch
	dnAssert("bad WKT is an error",substr(cCatchError,"ParseException") > 0,1)
done

dnTestSummary()
