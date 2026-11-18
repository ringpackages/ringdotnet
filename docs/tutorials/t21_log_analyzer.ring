# Tutorial 21: a project - analyze a log file (files, regular expressions, dictionaries, LINQ, JSON)
load "../../libraries/dotnetlib/dotnetlib.ring"
using {
	"System"
	"System.IO"
	"System.Text.RegularExpressions"
	"System.Collections.Generic"
	"System.Linq"
	"System.Text.Json"
}

func main
	# STEP 1. Make a sample log file (a real program would read an existing file)
	cLog = new Path().Combine(new Path().GetTempPath(),"tutorial21.log")
	makeLog(cLog)
	? "STEP 1: log written, " + len(new File().ReadAllLines(cLog).toList()) + " lines"

	# STEP 2. Read it and pick the parts of each line with a regular expression.
	#   a line looks like:  2024-05-17 08:15:02 ERROR [db] connection lost
	oLine = new Regex("^(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}:\d{2}) (?<level>[A-Z]+) \[(?<part>\w+)\] (?<text>.+)$")
	oLevels = new NumberDictionary()          # level -> how many
	oParts = new NumberDictionary()           # part with errors -> how many
	aErrors = []                              # the texts of the errors
	nLines = 0
	for cLine in new File().ReadAllLines(cLog).toList()
		oMatch = oLine.Match(cLine)
		if not oMatch.Success
			loop
		ok
		nLines++
		cLevel = oMatch.Groups.Item("level").Value
		cPart = oMatch.Groups.Item("part").Value
		oLevels.SetItem(cLevel,count(oLevels,cLevel) + 1)
		if cLevel = "ERROR"
			oParts.SetItem(cPart,count(oParts,cPart) + 1)
			aErrors + oMatch.Groups.Item("text").Value
		ok
	next
	? "STEP 2: " + nLines + " lines understood"

	# STEP 3. Report
	? nl + "STEP 3: lines per level"
	for cLevel in ["INFO","WARN","ERROR"]
		? "   " + cLevel + " : " + count(oLevels,cLevel)
	next
	? "   Errors per part: db=" + count(oParts,"db") + " web=" + count(oParts,"web") + " disk=" + count(oParts,"disk")

	# STEP 4. LINQ: the distinct error texts, sorted
	aDistinct = dnQuery(aErrors).Distinct().OrderBy("xDotNetResult = aDotNetArgs[1]").ToList()
	? nl + "STEP 4: " + len(aDistinct) + " different errors:"
	for cText in aDistinct
		? "   - " + cText
	next

	# STEP 5. Save a JSON report and read it back
	cReport = new Path().Combine(new Path().GetTempPath(),"tutorial21-report.json")
	aReport = [
		["lines",nLines],
		["errors",len(aErrors)],
		["different",len(aDistinct)]
	]
	new File().WriteAllText(cReport,webJsonText(aReport))
	? nl + "STEP 5: report " + new File().ReadAllText(cReport)
	new File().Delete(cLog)
	new File().Delete(cReport)

# a count from the dictionary (0 when the key is missing)
func count oDictionary, cKey
	aFound = oDictionary.TryGetValue(cKey)
	if aFound[1]
		return aFound[2]
	ok
	return 0

# a small JSON object from [name, value] pairs
func webJsonText aPairs
	cText = "{"
	for nIndex = 1 to len(aPairs)
		if nIndex > 1
			cText += ","
		ok
		cText += '"' + aPairs[nIndex][1] + '":' + aPairs[nIndex][2]
	next
	return cText + "}"

func makeLog cFile
	aLines = []
	aLevels = ["INFO","INFO","WARN","INFO","ERROR","INFO","ERROR","WARN","INFO","ERROR"]
	aParts = ["db","web","disk","web","db","web","disk","db","web","web"]
	aTexts = ["connection lost","request done","slow response","user logged in","connection lost","page served","disk almost full","retrying","cache warmed","timeout"]
	for nIndex = 1 to 30
		nPick = (nIndex - 1) % 10 + 1
		cTime = "08:" + right("0" + (nIndex % 60),2) + ":00"
		aLines + ("2024-05-" + right("0" + (17 + floor(nIndex / 10)),2) + " " + cTime + " " + aLevels[nPick] + " [" + aParts[nPick] + "] " + aTexts[nPick])
	next
	aLines + "this line is not in the format"
	cText = ""
	for cLine in aLines
		cText += cLine + windowsnl()
	next
	new File().WriteAllText(cFile,cText)
