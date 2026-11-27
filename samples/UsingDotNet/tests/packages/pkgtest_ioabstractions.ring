# System.IO.Abstractions: a file system that lives in memory (MockFileSystem): files, folders, file information and paths, without touching the disk
load "pkg.ring"
pkgUse("ioabstractions",[["System.IO.Abstractions.TestingHelpers","23.1.0"]],[["TestableIO.System.IO.Abstractions.TestingHelpers.dll",["System.IO.Abstractions.TestingHelpers"]],["Testably.Abstractions.FileSystem.Interface.dll",["System.IO.Abstractions"]]])
pkgImport("ioabstractions","TestableIO.System.IO.Abstractions.TestingHelpers.dll","System.IO.Abstractions.TestingHelpers")
pkgImport("ioabstractions","Testably.Abstractions.FileSystem.Interface.dll","System.IO.Abstractions")

oFs = new MockFileSystem()
oFile = oFs.File
oDirectory = oFs.Directory
oPath = oFs.Path
oFileInfo = oFs.FileInfo

cText = "one" + nl + "two"
oFile.WriteAllText([ :path = mp("notes.txt"), :contents = cText ])
dnAssert("a file is written",oFile.Exists(mp("notes.txt")),1)
dnAssert("its text is read",oFile.ReadAllText(mp("notes.txt")),cText)
dnAssert("a file that was not written",oFile.Exists(mp("other.txt")),0)

oDirectory.CreateDirectory(mp("data/sub"))
dnAssert("a folder is made",oDirectory.Exists(mp("data/sub")),1)
oFile.WriteAllText([ :path = mp("data/a.csv"), :contents = "1,2" ])
oFile.WriteAllText([ :path = mp("data/b.csv"), :contents = "3,4" ])
oFile.WriteAllText([ :path = mp("data/readme.txt"), :contents = "hello" ])
aCsv = oDirectory.GetFiles([ :path = mp("data"), :searchPattern = "*.csv" ]).toList()
dnAssert("a pattern finds the csv files",len(aCsv),2)

oInfo = oFileInfo.callMethod("New",[ mp("data/readme.txt") ])
dnAssert("the size of a file",oInfo.Length,5)
dnAssert("the name of a file",oInfo.Name,"readme.txt")
dnAssert("the extension",oInfo.Extension,".txt")

oFile.Copy([ :sourceFileName = mp("data/a.csv"), :destFileName = mp("data/sub/a.csv") ])
dnAssert("a copy",oFile.ReadAllText(mp("data/sub/a.csv")),"1,2")
oFile.Move([ :sourceFileName = mp("data/b.csv"), :destFileName = mp("data/moved.csv") ])
dnAssert("a move: the old name is gone",oFile.Exists(mp("data/b.csv")),0)
dnAssert("a move: the new name",oFile.ReadAllText(mp("data/moved.csv")),"3,4")
oFile.Delete(mp("data/a.csv"))
dnAssert("a delete",oFile.Exists(mp("data/a.csv")),0)

dnAssert("paths: combine",oPath.Combine([ mp("data"),"x.txt" ]),mp("data/x.txt"))
dnAssert("paths: the file name",oPath.GetFileName(mp("data/x.txt")),"x.txt")

# a file system that has a file from the start
oFs2 = new MockFileSystem()
oData = (new MockFileData).@New("preset text")
oFs2.AddFile([ :path = mp("preset.txt"), :mockFile = oData ])
oFile2 = oFs2.File
dnAssert("a preset file",oFile2.ReadAllText(mp("preset.txt")),"preset text")
dnAssert("the files of the file system",len(oFs2.AllFiles.toList()) >= 1,1)

# reading a file that is not there is an error, as with the real file system
lError = 0
try
	oFile2.ReadAllText(mp("missing.txt"))
catch
	lError = 1
done
dnAssert("a missing file raises an error",lError,1)

dnTestSummary()

# the file system of the test follows the system that runs it: c:\ and backslashes on Windows, / on Linux
func mp cRelative

	if iswindows()
		return "c:\" + substr(cRelative,"/","\")
	ok
	return "/" + cRelative
