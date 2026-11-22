# Microsoft.Extensions.FileSystemGlobbing: include and exclude patterns matched against files of a folder that the test makes
load "pkg.ring"
pkgUse("globbing",[["Microsoft.Extensions.FileSystemGlobbing","9.0.0"]],[["Microsoft.Extensions.FileSystemGlobbing.dll",["Microsoft.Extensions.FileSystemGlobbing","Microsoft.Extensions.FileSystemGlobbing.Abstractions"]]])
pkgImport("globbing","Microsoft.Extensions.FileSystemGlobbing.dll","Microsoft.Extensions.FileSystemGlobbing")
pkgImport("globbing","Microsoft.Extensions.FileSystemGlobbing.dll","Microsoft.Extensions.FileSystemGlobbing.Abstractions")

cRoot = cPkgCache + "globbing/tree"
pkgRemoveDir(cRoot)
pkgMakeDir(cRoot)
pkgMakeDir(cRoot + "/src")
pkgMakeDir(cRoot + "/src/deep")
pkgMakeDir(cRoot + "/docs")
write(cRoot + "/a.ring","")
write(cRoot + "/b.txt","")
write(cRoot + "/src/c.ring","")
write(cRoot + "/src/deep/d.ring","")
write(cRoot + "/src/deep/e.txt","")
write(cRoot + "/docs/f.md","")

oMatcher = new Matcher()
oMatcher.AddInclude("**/*.ring")
aFiles = matchFiles(oMatcher,cRoot)
dnAssert("every ring file in the tree",len(aFiles),3)

oOne = new Matcher()
oOne.AddInclude("*.txt")
dnAssert("a pattern in the root only",len(matchFiles(oOne,cRoot)),1)

oExclude = new Matcher()
oExclude.AddInclude("**/*")
oExclude.AddExclude("**/*.txt")
dnAssert("everything except text files",len(matchFiles(oExclude,cRoot)),4)

oMatcher2 = new Matcher()
oMatcher2.AddInclude("src/**/*.ring")
dnAssert("a folder in the pattern",len(matchFiles(oMatcher2,cRoot)),2)

dnAssert("a path matched by a pattern",oMatcher.Match("src/deep/d.ring").HasMatches,1)
dnAssert("a path not matched",oMatcher.Match("docs/f.md").HasMatches,0)

pkgRemoveDir(cRoot)
dnTestSummary()

func matchFiles oMatcher, cRoot
	oInfo = dnNew("System.IO.DirectoryInfo",[cRoot])
	oWrapper = dnNew("Microsoft.Extensions.FileSystemGlobbing.Abstractions.DirectoryInfoWrapper",[oInfo])
	oResult = oMatcher.Execute(oWrapper)
	return oResult.Files.toList()
