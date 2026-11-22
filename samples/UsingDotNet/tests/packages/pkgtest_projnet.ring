# ProjNet: coordinate systems and transformations; WGS84 longitude and latitude to Web Mercator meters and back
load "pkg.ring"
pkgUse("projnet",[["ProjNet","2.1.0"]],[["ProjNet.dll",["ProjNet.CoordinateSystems","ProjNet.CoordinateSystems.Transformations"]]])
pkgImport("projnet","ProjNet.dll","ProjNet.CoordinateSystems")
pkgImport("projnet","ProjNet.dll","ProjNet.CoordinateSystems.Transformations")

oWgs84 = dnStatic("ProjNet.CoordinateSystems.GeographicCoordinateSystem","WGS84",[])
oMercator = dnStatic("ProjNet.CoordinateSystems.ProjectedCoordinateSystem","WebMercator",[])
dnAssert("the name of WGS84",oWgs84.Name,"WGS 84")
dnAssert("the dimension",oWgs84.Dimension,2)

oFactory = new CoordinateTransformationFactory()
oTransform = oFactory.callMethod("CreateFromCoordinateSystems",[oWgs84,oMercator])
oMath = oTransform.MathTransform

aPoint = oMath.callMethod("Transform",[[31.2357,30.0444]]).toList()
dnAssert("Cairo: x in meters",floor(aPoint[1]),3477142)
dnAssert("Cairo: y in meters",floor(aPoint[2]),3509258)

aBack = oTransform.MathTransform.Inverse().callMethod("Transform",[aPoint]).toList()
dnAssert("and back: longitude",floor(aBack[1] * 1000),31235)
dnAssert("and back: latitude",floor(aBack[2] * 1000),30044)

dnAssert("the origin stays at the origin",floor(oMath.callMethod("Transform",[[0,0]]).toList()[1]),0)

dnTestSummary()
