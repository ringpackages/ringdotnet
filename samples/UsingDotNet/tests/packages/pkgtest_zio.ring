# Zio: file systems behind one interface: a memory file system with / paths (UPath), the same calls on a read-only view and on a folder inside it
load "pkg.ring"
pkgUse("zio",[["Zio","0.25.0"]],[["Zio.dll",["Zio","Zio.FileSystems"]]])
pkgImport("zio","Zio.dll","Zio")
pkgImport("zio","Zio.dll","Zio.FileSystems")

oFs = new MemoryFileSystem()
oFs.CreateDirectory("/data/sub")
dnAssert("a folder is made",oFs.DirectoryExists("/data/sub"),1)
dnAssert("the parent folder exists",oFs.DirectoryExists("/data"),1)

# WriteAllText and ReadAllText are extension methods of IFileSystem: methods of the file system
oFs.WriteAllText([ :path = "/data/a.txt", :content = "alpha" ])
oFs.WriteAllText([ :path = "/data/b.txt", :content = "beta" ])
oFs.WriteAllText([ :path = "/data/sub/c.log", :content = "gamma" ])
dnAssert("a file is read",oFs.ReadAllText("/data/a.txt"),"alpha")
dnAssert("a file exists",oFs.FileExists("/data/b.txt"),1)
dnAssert("a missing file does not exist",oFs.FileExists("/data/none.txt"),0)
dnAssert("the length of a file",oFs.GetFileLength("/data/b.txt"),4)

# lists: a pattern, and with the folders inside
aTxt = oFs.EnumerateFiles([ :path = "/data", :searchPattern = "*.txt" ]).toList()
dnAssert("a pattern finds the txt files",len(aTxt),2)
aAll = oFs.EnumerateFiles([ :path = "/data", :searchPattern = "*", :searchOption = "AllDirectories" ]).toList()
dnAssert("all the files inside the folders",len(aAll),3)

# copy, move and delete
oFs.CopyFile("/data/a.txt","/data/copy.txt",1)
dnAssert("a copy has the text",oFs.ReadAllText("/data/copy.txt"),"alpha")
oFs.MoveFile("/data/b.txt","/data/sub/moved.txt")
dnAssert("a move: the old path is gone",oFs.FileExists("/data/b.txt"),0)
dnAssert("a move: the new path",oFs.ReadAllText("/data/sub/moved.txt"),"beta")
oFs.DeleteFile("/data/copy.txt")
dnAssert("a delete",oFs.FileExists("/data/copy.txt"),0)

# a view of one folder as a file system of its own
oSub = (new SubFileSystem).@New([ :fileSystem = oFs, :subPath = "/data/sub" ])
dnAssert("a sub file system sees the files of its folder",oSub.ReadAllText("/c.log"),"gamma")
dnAssert("and its root has the folder files only",oSub.FileExists("/a.txt"),0)

# a read-only view
oReadOnly = (new ReadOnlyFileSystem).@New([ :fileSystem = oFs ])
dnAssert("a read-only view reads",oReadOnly.ReadAllText("/data/a.txt"),"alpha")
lRefused = 0
try
	oReadOnly.WriteAllText([ :path = "/data/new.txt", :content = "no" ])
catch
	lRefused = 1
done
dnAssert("a read-only view refuses a write",lRefused,1)

dnTestSummary()
