# Many objects from real packages: loops that make thousands of objects (dates, versions, parsers, text results) must give their .NET handles back (dnHandleCount), and results must stay right
load "pkg.ring"
pkgUse("nodatime",[["NodaTime","3.3.7"]],[["NodaTime.dll",["NodaTime"]]])
pkgUse("semver",[["Semver","3.0.0"]],[["Semver.dll",["Semver"]]])
pkgUse("markdig",[["Markdig","1.6.0"]],[["Markdig.dll",["Markdig","Markdig.Syntax"]]])
pkgImport("nodatime","NodaTime.dll","NodaTime")
pkgImport("semver","Semver.dll","Semver")
pkgImport("markdig","Markdig.dll","Markdig")

# the handles that Ring holds before: a few objects of the libraries
dnStatic("NodaTime.LocalDate","FromDateTime",[dnNew("System.DateTime",[ :year = 2024, :month = 1, :day = 1 ])])
callgc()
dnFlush()
nBefore = dnHandleCount()

# 3000 dates: each one makes several objects (a date, a period, a sum)
nChecksum = 0
for i = 1 to 3000
	oDate = dnNew("NodaTime.LocalDate",[ :year = 2024, :month = 1, :day = 1 ])
	oLater = oDate + dnStatic("NodaTime.Period","FromDays",[i % 365])
	nChecksum += oLater.DayOfYear
next
dnAssert("the results of 3000 dates are right",nChecksum > 0 and nChecksum % 1 = 0,1)
dnAssert("the last date",oLater.Month,3)

# 2000 versions parsed and compared
nNewer = 0
oBase = dnStatic("Semver.SemVersion","Parse",["1.2.3"])
for i = 1 to 2000
	oVersion = dnStatic("Semver.SemVersion","Parse",["1." + (i % 50) + ".0"])
	if dnStatic("Semver.SemVersion","ComparePrecedence",[oVersion,oBase]) > 0
		nNewer++
	ok
next
dnAssert("the versions that are newer (the minor numbers 3 to 49 of every 50)",nNewer,1880)

# 500 documents parsed to HTML and walked
nBlocks = 0
for i = 1 to 500
	cHtml = dnStatic("Markdig.Markdown","ToHtml",["# Title " + i + nl + nl + "text *with* emphasis"])
	if substr(cHtml,"<h1>Title " + i + "</h1>") > 0
		nBlocks++
	ok
next
dnAssert("every document gave its title",nBlocks,500)
oDocument = dnStatic("Markdig.Markdown","Parse",["# A" + nl + nl + "b"])
dnAssert("a parsed document still works",oDocument.Count,2)

# the handles of all those objects were given back: Ring drops them as it goes (the groups of releases are sent now)
oDate = ""
oLater = ""
oVersion = ""
oBase = ""
oDocument = ""
callgc()          # Ring frees what it dropped, then the releases are sent
dnFlush()
nAfter = dnHandleCount()
dnAssert("the handles were released (before " + nBefore + ", after " + nAfter + ")",nAfter < nBefore + 60,1)

dnTestSummary()
