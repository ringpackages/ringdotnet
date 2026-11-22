# Semver: semantic versions as objects (parse, compare, precedence, prerelease, build), with operators and the helper methods
load "pkg.ring"
pkgUse("semver",[["Semver","3.0.0"]],[["Semver.dll",["Semver"]]])
pkgImport("semver","Semver.dll","Semver")

oVersion = dnStatic("Semver.SemVersion","Parse",["1.2.3-beta.4+build.5"])
dnAssert("the major number (a BigInteger object)",oVersion.Major.ToString(),"1")
dnAssert("the minor number",oVersion.Minor.ToString(),"2")
dnAssert("the patch number",oVersion.Patch.ToString(),"3")
dnAssert("the prerelease",oVersion.Prerelease,"beta.4")
dnAssert("a prerelease version",oVersion.IsPrerelease,1)
dnAssert("the build metadata",oVersion.Metadata,"build.5")
dnAssert("the text of the version",oVersion.ToString(),"1.2.3-beta.4+build.5")

# comparison: SemVersion has no operators, it compares by precedence (the rules of Semantic Versioning)
oRelease = dnStatic("Semver.SemVersion","Parse",["1.2.3"])
oNext = dnStatic("Semver.SemVersion","Parse",["1.10.0"])
dnAssert("a prerelease is before its release",dnStatic("Semver.SemVersion","ComparePrecedence",[oVersion,oRelease]) < 0,1)
dnAssert("1.2.3 is before 1.10.0 (numbers, not texts)",dnStatic("Semver.SemVersion","ComparePrecedence",[oRelease,oNext]) < 0,1)
dnAssert("the same versions are equal",dnStatic("Semver.SemVersion","Parse",["1.2.3"]) = oRelease,1)
dnAssert("the precedence of equal versions",dnStatic("Semver.SemVersion","ComparePrecedence",[oRelease,dnStatic("Semver.SemVersion","Parse",["1.2.3+other"])]),0)
dnAssert("the sort order looks at the metadata too",dnStatic("Semver.SemVersion","CompareSortOrder",[oRelease,dnStatic("Semver.SemVersion","Parse",["1.2.3+other"])]) != 0,1)

# a new version from an old one
oBumped = oRelease.WithMinor(5)
dnAssert("WithMinor",oBumped.ToString(),"1.5.3")
dnAssert("WithMajor",oRelease.WithMajor(2).ToString(),"2.2.3")
dnAssert("the original did not change",oRelease.ToString(),"1.2.3")

# a bad version
aTry = dnStatic("Semver.SemVersion","TryParse",["not a version"])
dnAssert("a bad text does not parse",aTry[1],0)
try
	dnStatic("Semver.SemVersion","Parse",["1.2"])
	dnAssert("a short version is an error (strict)",1,0)
catch
	dnAssert("a short version is an error (strict)",substr(cCatchError,"Invalid version") > 0 or substr(cCatchError,"FormatException") > 0,1)
done

dnTestSummary()
