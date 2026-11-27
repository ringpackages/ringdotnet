# MathNet.Spatial: 2D and 3D geometry as structs (points, vectors, angles, circles, lines) with operators and unit conversions
load "pkg.ring"
pkgUse("mathspatial",[["MathNet.Spatial","0.6.0"]],[["MathNet.Spatial.dll",["MathNet.Spatial.Euclidean","MathNet.Spatial.Units"]],["MathNet.Numerics.dll",[]]])
pkgImport("mathspatial","MathNet.Spatial.dll","MathNet.Spatial.Euclidean")
pkgImport("mathspatial","MathNet.Spatial.dll","MathNet.Spatial.Units")

# points: a 3-4-5 triangle
oOrigin = point2(0,0)
oPoint = point2(3,4)
dnAssert("the x of a point",oPoint.X,3)
dnAssert("the distance between two points",oOrigin.DistanceTo(oPoint),5)
dnAssert("the distance back",oPoint.DistanceTo(oOrigin),5)

# angles: degrees and radians
oAngles = new Angle()
oRight = oAngles.FromDegrees(90)
dnAssert("90 degrees",oRight.Degrees,90)
dnAssert("90 degrees in radians",floor(oRight.Radians * 1000),1570)
oHalfTurn = oAngles.FromRadians(3.141592653589793)
dnAssert("pi radians is 180 degrees",floor(oHalfTurn.Degrees + 0.5),180)

# vectors
oVector = vector2(3,4)
dnAssert("the length of a vector",oVector.Length,5)
oUnit = oVector.Normalize()
dnAssert("a unit vector has the length 1",floor(oUnit.Length * 1000 + 0.5),1000)
oOther = vector2(-4,3)
dnAssert("perpendicular vectors have a dot product of 0",oVector.DotProduct(oOther),0)
oRotated = vector2(1,0).Rotate(oRight)
dnAssert("a quarter turn of (1,0) gives y = 1",floor(oRotated.Y * 1000 + 0.5),1000)
dnAssert("and x close to 0",floor(fabs(oRotated.X) * 1000),0)

# a point from a distance and an angle
oPolar = point2(0,0).FromPolar(2,oRight)
dnAssert("a polar point at 90 degrees is on the y axis",floor(oPolar.Y * 1000 + 0.5),2000)

# 3D: the cross product of two axes is the third
oX = vector3(1,0,0)
oY = vector3(0,1,0)
oZ = oX.CrossProduct(oY)
dnAssert("x cross y is z (z)",oZ.Z,1)
dnAssert("x cross y is z (x)",oZ.X,0)
dnAssert("the length of a 3D vector",vector3(2,3,6).Length,7)

# a circle: area and circumference
oCircle = circle(point2(0,0),2)
dnAssert("the area of a circle",floor(oCircle.Area * 100),1256)
dnAssert("the circumference of a circle",floor(oCircle.Circumference * 100),1256)


dnTestSummary()

# the structs have no parameterless constructor: each one is made with the names of its constructor
func point2 nX,nY

	oMade = (new Point2D).@New([ :x = nX, :y = nY ])
	return oMade

func vector2 nX,nY

	oMade = (new Vector2D).@New([ :x = nX, :y = nY ])
	return oMade

func vector3 nX,nY,nZ

	oMade = (new Vector3D).@New([ :x = nX, :y = nY, :z = nZ ])
	return oMade

func circle oCenter,nRadius

	oMade = (new Circle2D).@New([ :center = oCenter, :radius = nRadius ])
	return oMade
