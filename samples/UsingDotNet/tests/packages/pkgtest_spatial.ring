# MathNet.Spatial (the operator of a number and a vector is written 3 * v: the operator is defined with the number first): 3D points and vectors (structs with operators and methods), lengths, dot and cross products, angles
load "pkg.ring"
pkgUse("spatial",[["MathNet.Spatial","0.6.0"],["MathNet.Numerics","5.0.0"]],[["MathNet.Spatial.dll",["MathNet.Spatial.Euclidean","MathNet.Spatial.Units"]],["MathNet.Numerics.dll",[]]])
pkgImport("spatial","MathNet.Spatial.dll","MathNet.Spatial.Euclidean")
pkgImport("spatial","MathNet.Spatial.dll","MathNet.Spatial.Units")

oX = dnNew("MathNet.Spatial.Euclidean.Vector3D",[1,0,0])
oY = dnNew("MathNet.Spatial.Euclidean.Vector3D",[0,1,0])
dnAssert("a length",dnNew("MathNet.Spatial.Euclidean.Vector3D",[3,4,0]).Length,5)
dnAssert("a dot product of perpendicular vectors",oX.DotProduct(oY),0)
oZ = oX.CrossProduct(oY)
dnAssert("a cross product",oZ.Z,1)
dnAssert("a sum of vectors",(oX + oY).X,1)
dnAssert("a sum of vectors, y",(oX + oY).Y,1)
dnAssert("a vector scaled",(3 * oX).X,3)
dnAssert("an angle of 90 degrees",oX.AngleTo(oY).Degrees,90)

oP = dnNew("MathNet.Spatial.Euclidean.Point3D",[1,2,3])
oQ = dnNew("MathNet.Spatial.Euclidean.Point3D",[4,6,3])
dnAssert("the distance of two points",oP.DistanceTo(oQ),5)
dnAssert("the vector between points",oP.VectorTo(oQ).X,3)
dnAssert("a point moved by a vector",(oP + oX).X,2)

dnTestSummary()
