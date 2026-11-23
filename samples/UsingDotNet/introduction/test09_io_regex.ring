# Text files, compression and regular expressions
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.IO.Compression"
	"System.Text.RegularExpressions"
}

oPath = new Path()
oFile = new File()
cDir = oPath.Combine([oPath.GetTempPath(),"ringdotnet_demo"])
new Directory().CreateDirectory(cDir)

# Text files
cLog = oPath.Combine([cDir,"log.txt"])
oWriter = new StreamWriter(cLog)
oWriter.WriteLine("2024-05-17 ERROR disk full")
oWriter.WriteLine("2024-05-18 INFO backup done")
oWriter.WriteLine("2024-06-01 ERROR network down")
oWriter.Close()
? "Lines in file : " + len(oFile.ReadAllLines(cLog).toList())
? "File size     : " + new FileInfo(cLog).Length + " bytes"

# Regular expressions: find the errors and their month
oRegex = new Regex("(?<month>\d{4}-\d{2})-\d{2} ERROR (?<what>.+)")
oMatches = oRegex.Matches(oFile.ReadAllText(cLog))
? "Errors found  : " + oMatches.Count
for nLoop = 0 to oMatches.Count - 1
	oMatch = oMatches.Item(nLoop)
	? "  " + oMatch.Groups.Item("month").Value + " -> " + trim(oMatch.Groups.Item("what").Value)
next
? "Cleaned       : " + new Regex("\s+").Replace([ :input = "too    many   spaces", :replacement = " " ])

# Compression
oPacked = new MemoryStream()
oGzip = new GZipStream(oPacked,"Compress")
cData = copy("Ring and .NET ",200)
oGzip.Write(cData,0,len(cData))
oGzip.Close()
? "GZip          : " + len(cData) + " -> " + len(oPacked.ToArray()) + " bytes"

cZip = oPath.Combine([oPath.GetTempPath(),"ringdotnet_demo.zip"])
if oFile.Exists(cZip) oFile.Delete(cZip) ok
new ZipFile().CreateFromDirectory([ :sourceDirectoryName = cDir, :destinationArchiveFileName = cZip ])
? "Zip created   : " + new FileInfo(cZip).Length + " bytes"

new Directory().Delete([ :path = cDir, :recursive = True ])
oFile.Delete(cZip)
