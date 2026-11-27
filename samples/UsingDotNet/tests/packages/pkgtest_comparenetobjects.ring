# CompareNETObjects: a deep comparison of two objects (CompareLogic) that says what is different, with a configuration (ignored members, tolerance)
load "pkg.ring"
pkgUse("compareobjects",[["CompareNETObjects","4.84.0"]],[["KellermanSoftware.Compare-NET-Objects.dll",["KellermanSoftware.CompareNetObjects"]]])
pkgImport("compareobjects","KellermanSoftware.Compare-NET-Objects.dll","KellermanSoftware.CompareNetObjects")

using {
	"System"
	"System.Collections.Generic"
}

oLogic = new CompareLogic()

# two equal values, and two that are not
oResult = oLogic.Compare("ring","ring")
dnAssert("equal texts",oResult.AreEqual,1)
oResult = oLogic.Compare("ring","Ring")
dnAssert("texts that differ",oResult.AreEqual,0)
dnAssert("one difference is found",oResult.Differences.Count,1)

# numbers
oResult = oLogic.Compare(42,42)
dnAssert("equal numbers",oResult.AreEqual,1)

# two lists are compared item by item
oListA = dnNew("System.Collections.Generic.List`1[[System.Int32]]",[])
oListB = dnNew("System.Collections.Generic.List`1[[System.Int32]]",[])
for nItem in [1,2,3]
	oListA.Add(nItem)
	oListB.Add(nItem)
next
oResult = oLogic.Compare(oListA,oListB)
dnAssert("equal lists",oResult.AreEqual,1)
oListB.Add(4)
oResult = oLogic.Compare(oListA,oListB)
dnAssert("lists of another length differ",oResult.AreEqual,0)

# two dates
oDateA = new DateTime(2024,5,17)
oDateB = new DateTime(2024,5,18)
oResult = oLogic.Compare(oDateA,oDateB)
dnAssert("two dates that differ",oResult.AreEqual,0)
oDateC = new DateTime(2024,5,17)
oResult = oLogic.Compare(oDateA,oDateC)
dnAssert("the same date is equal",oResult.AreEqual,1)

# the message tells what is different
oResult = oLogic.Compare("one","two")
dnAssert("the difference text is not empty",len(oResult.DifferencesString) > 0,1)

dnTestSummary()
