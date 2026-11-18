# Batch: System.IO, System.IO.Compression, System.Text.RegularExpressions
load "dotnet.ring"
dnImport("System")
dnImport("System.IO")
dnImport("System.IO.Compression")
dnImport("System.Text")
dnImport("System.Text.RegularExpressions")

oPath = new Path()
cTemp = oPath.Combine(oPath.GetTempPath(),"ringdotnet_test_" + new Guid().NewGuid().ToString_1("N"))
dnAssert("Path.Combine",oPath.Combine("a","b"),"a" + oPath.DirectorySeparatorChar + "b")
dnAssert("Path.GetFileName",oPath.GetFileName("c:/x/file.txt"),"file.txt")
dnAssert("Path.GetExtension",oPath.GetExtension("c:/x/file.txt"),".txt")
dnAssert("Path.ChangeExtension",oPath.GetFileNameWithoutExtension("a/b/doc.md"),"doc")

# Directories
oDir = new Directory()
oInfo = oDir.CreateDirectory(cTemp)
dnAssert("CreateDirectory returns DirectoryInfo",oInfo.Exists,1)
dnAssert("Directory.Exists",oDir.Exists(cTemp),1)

# Files
oFile = new File()
cFile = oPath.Combine(cTemp,"a.txt")
oFile.WriteAllText(cFile,"hello")
oFile.AppendAllText(cFile," world")
dnAssert("ReadAllText",oFile.ReadAllText(cFile),"hello world")
dnAssert("File.Exists",oFile.Exists(cFile),1)
oFile.WriteAllLines(oPath.Combine(cTemp,"lines.txt"),["one","two","three"])
dnAssert("ReadAllLines",len(oFile.ReadAllLines(oPath.Combine(cTemp,"lines.txt")).toList()),3)
oFile.Copy(cFile,oPath.Combine(cTemp,"b.txt"))
oFile.Move(oPath.Combine(cTemp,"b.txt"),oPath.Combine(cTemp,"c.txt"))
dnAssert("Copy/Move",oFile.Exists(oPath.Combine(cTemp,"c.txt")),1)
oFI = new FileInfo(cFile)
dnAssert("FileInfo.Length",oFI.Length,11)
dnAssert("FileInfo.Extension",oFI.Extension,".txt")
dnAssert("GetFiles",len(oDir.GetFiles(cTemp).toList()),3)

# Objects are wrapped by their runtime type: File.Create declares Stream but returns a FileStream
oStream = oFile.Create(oPath.Combine(cTemp,"s.bin"))
dnAssert("runtime type wrapper",classname(oStream),"filestream")
oStream.Close()

# Readers and writers
cText = oPath.Combine(cTemp,"w.txt")
oWriter = new StreamWriter(cText)
oWriter.WriteLine("first")
oWriter.WriteLine("second")
oWriter.Close()
oReader = new StreamReader(cText)
dnAssert("StreamReader.ReadLine",oReader.ReadLine(),"first")
dnAssert("StreamReader.ReadToEnd",left(oReader.ReadToEnd(),6),"second")
oReader.Close()

# Memory streams and binary readers/writers
oMem = new MemoryStream()
oBin = new BinaryWriter(oMem)
oBin.Write(7)
oBin.Write("text")
oBin.Flush()
dnAssert("MemoryStream.Length",oMem.Length > 4,1)
oMem.Position = 0
oRead = new BinaryReader(oMem)
dnAssert("BinaryReader.ReadInt32",oRead.ReadInt32(),7)
dnAssert("BinaryReader.ReadString",oRead.ReadString(),"text")

# GZip round trip
oPacked = new MemoryStream()
oGz = new GZipStream(oPacked,"Compress")
oGz.Write("hello hello hello hello",0,23)
oGz.Close()
cPacked = oPacked.ToArray()
dnAssert("GZip compressed",len(cPacked) > 10,1)
oGz2 = new GZipStream(new MemoryStream().New_1(cPacked),"Decompress")
dnAssert("GZip decompress",new StreamReader(oGz2).ReadToEnd(),"hello hello hello hello")

# Zip archives
cZip = oPath.Combine(oPath.GetTempPath(),"ringdotnet_test.zip")
if oFile.Exists(cZip) oFile.Delete(cZip) ok
new ZipFile().CreateFromDirectory(cTemp,cZip)
dnAssert("Zip created",oFile.Exists(cZip),1)
oArchive = new ZipFile().OpenRead(cZip)
dnAssert("Zip entries",oArchive.Entries.getProp("Count") >= 4,1)
oArchive.Dispose()

# Regular expressions
oRegex = new Regex("(?<year>\d{4})-(?<month>\d{2})")
dnAssert("Regex.IsMatch",oRegex.IsMatch("date 2024-05-17"),1)
oMatch = oRegex.Match("date 2024-05-17")
dnAssert("Match.Value",oMatch.Value,"2024-05")
dnAssert("Match.Groups",oMatch.Groups.Item("month").Value,"05")
dnAssert("Regex.Matches",oRegex.Matches("2020-01 and 2021-02").Count,2)
dnAssert("Regex.Replace",new Regex("\s+").Replace("a   b    c"," "),"a b c")
dnAssert("Regex static",new Regex("x").Escape("a.b"),"a\.b")

# Clean up
oDir.Delete_2(cTemp,1)
oFile.Delete(cZip)
dnAssert("deleted",oDir.Exists(cTemp),0)
nFail = dnTestSummary()
