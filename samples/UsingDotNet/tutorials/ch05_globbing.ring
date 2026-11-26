# file patterns (globbing) - "**/*.ring", include and exclude rules, matching a list of paths, and finding files in a folder tree
load "dotnet.ring"

using {
	"Microsoft.Extensions.FileSystemGlobbing"
	"System"
	"System.IO"
	"RingDotNet.Web"                  # Microsoft.Extensions.FileSystemGlobbing is part of the ASP.NET Core runtime: this line starts it
}

func main

	# A glob pattern describes a set of files with wildcards, like the patterns in a .gitignore file or a build tool:
	#   *      any characters inside one name           *.ring     a.ring, b.ring
	#   **     any number of folders (also none)         **/*.ring  src/a.ring, src/sub/b.ring, a.ring
	#   ?      one character                             file?.txt  file1.txt, fileA.txt
	cBase = makeTree()

	# 1. A Matcher has include rules and exclude rules. A file is in the result when an include rule matches it and no exclude rule does.
	oMatcher = new Matcher()
	oMatcher.AddInclude("**/*.ring")
	? "1. **/*.ring :"
	showFiles(oMatcher,cBase)

	# 2. Exclude: everything under "tests" and every file whose name starts with "old_" is left out
	oMatcher2 = new Matcher()
	oMatcher2.AddInclude("**/*.ring")
	oMatcher2.AddExclude("tests/**")
	oMatcher2.AddExclude("**/old_*")
	? nl + "2. **/*.ring without tests/** and old_* :"
	showFiles(oMatcher2,cBase)

	# 3. Several include rules at once: the code and the documents
	oMatcher3 = new Matcher()
	oMatcher3.AddInclude("src/*.ring")
	oMatcher3.AddInclude("docs/**/*.md")
	? nl + "3. src/*.ring (one folder only) and docs/**/*.md :"
	showFiles(oMatcher3,cBase)

	# 4. A pattern does not need files on a disk: Match(root, list of paths) tests a list of names, for example the files of an archive
	#    (the tutorial "ZIP archives in memory") or the changed files of a project. The paths use / and are relative to the root.
	aPaths = ["src/main.ring","src/old_main.ring","README.md","docs/guide/intro.md","docs/logo.png"]
	oResult = oMatcher3.Match([ :rootDir = ".", :files = aPaths ])
	? nl + "4. which of the names are matched: has matches = " + oResult.HasMatches
	aFiles = oResult.Files.toList()
	for oFile in aFiles
		? "   " + oFile.Path
	next

	# 5. By default a Matcher ignores case (OrdinalIgnoreCase). The constructor takes a StringComparison: with Ordinal, case counts.
	oStrict = (new Matcher).@New([ :comparisonType = "Ordinal" ])
	oStrict.AddInclude("**/*.RING")
	oResultStrict = oStrict.Match([ :rootDir = ".", :files = ["a.ring","b.RING"] ])
	? nl + "5. with Ordinal comparison, **/*.RING matches only: " + oResultStrict.Files.toList()[1].Path

	new Directory().Delete([ :path = cBase, :recursive = True ])

# the files of the program, with their relative paths in sorted order (the order of a disk is not the same on every system)
func showFiles oMatcher,cBase

	oResult = oMatcher.GetResultsInFullPath(cBase)
	aNames = []
	aFullNames = oResult.toList()
	for cFull in aFullNames
		aNames + substr(substr(cFull,cBase + "\",""),cBase + "/","")
	next
	aSortedNames = sort(aNames)
	for cName in aSortedNames
		? "   " + substr(cName,"\","/")
	next
	? "   (" + len(aNames) + " files)"

func makeTree

	oPath = new Path()
	cBase = oPath.Combine([oPath.GetTempPath(),"ringdotnet_globbing"])
	if new Directory().Exists(cBase)
		new Directory().Delete([ :path = cBase, :recursive = True ])
	ok
	for cFile in ["src/main.ring","src/old_main.ring","src/util/tools.ring","tests/test1.ring","docs/readme.md","docs/guide/intro.md","docs/logo.png","build.txt"]
		cFull = oPath.Combine([cBase,substr(cFile,"/",oPath.DirectorySeparatorChar)])
		new Directory().CreateDirectory(oPath.GetDirectoryName(cFull))
		new File().WriteAllText([ :path = cFull, :contents = "x" ])
	next
	return cBase
