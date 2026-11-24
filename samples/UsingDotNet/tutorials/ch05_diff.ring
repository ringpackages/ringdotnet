# a project: compare two text files - the longest common subsequence of lines, a diff with + and -, changes with context, and a similarity
load "dotnet.ring"

using {
	"System"
	"System.IO"
}

func main

	oFile = new File()
	oPath = new Path()
	cFolder = oPath.Combine([ oPath.GetTempPath(), "ringdotnet-diff-" + oPath.GetRandomFileName() ])
	new Directory().CreateDirectory(cFolder)

	# Two versions of a small text file (the program writes them, so that the output is always the same)
	cOld = "title: Tea" + nl + "water: 200 ml" + nl + "tea: 2 g" + nl + "heat: 90 C" + nl + "wait: 3 min" + nl + "serve: hot" + nl + "enjoy"
	cNew = "title: Tea" + nl + "water: 250 ml" + nl + "tea: 2 g" + nl + "milk: 20 ml" + nl + "heat: 90 C" + nl + "wait: 3 min" + nl + "serve: hot" + nl + "enjoy"
	oFile.WriteAllText([ :path = cFolder + "/old.txt", :contents = cOld ])
	oFile.WriteAllText([ :path = cFolder + "/new.txt", :contents = cNew ])
	aOld = oFile.ReadAllLines(cFolder + "/old.txt").toList()
	aNew = oFile.ReadAllLines(cFolder + "/new.txt").toList()
	? "1. the files have " + len(aOld) + " and " + len(aNew) + " lines"

	# A DIFF says what to do with the lines of the old file to get the new one: keep (a space), delete (-) or add (+). The idea is the
	# LONGEST COMMON SUBSEQUENCE (LCS): the longest list of lines that are in both files, in the same order. Lines that are in the LCS are
	# kept; the others of the old file are deleted and the others of the new file are added.
	aTable = lcsTable(aOld,aNew)
	? nl + "2. the length of the longest common subsequence: " + aTable[1][1]

	# 3. Walk the table from the top left corner: if the lines are the same keep them; else go on in the direction that has the longer LCS
	aDiff = makeDiff(aOld,aNew,aTable)
	? nl + "3. the whole diff:"
	for aItem in aDiff
		? "   " + aItem[1] + " " + aItem[2]
	next

	# 4. A summary: how many lines were kept, added and deleted, and how similar the files are (kept lines compared with all)
	nKept = countOf(aDiff," ")
	nAdded = countOf(aDiff,"+")
	nDeleted = countOf(aDiff,"-")
	? nl + "4. kept " + nKept + ", added " + nAdded + ", deleted " + nDeleted
	? "   similarity: " + floor(100 * 2 * nKept / (len(aOld) + len(aNew))) + " percent"

	# 5. Only the changes, with one line of context around them. A long file has few changes, and a person wants to see only those.
	? nl + "5. changes with 1 line of context:"
	aLines = withContext(aDiff,1)
	for cLine in aLines
		? "   " + cLine
	next

	# 6. Two files that are the same, and two that have nothing in common
	? nl + "6. identical files: similarity " + similarity(aOld,aOld) + " percent; nothing in common: " + similarity([ "a","b" ],[ "c","d" ]) + " percent"

	# 7. The same with the lines in another order: the LCS keeps the longest part that is in order
	aMoved = [ "serve: hot", "title: Tea", "water: 200 ml", "tea: 2 g", "heat: 90 C", "wait: 3 min", "enjoy" ]
	? nl + "7. 'serve' moved to the top: similarity " + similarity(aOld,aMoved) + " percent (the moved line is deleted at one place and added at another)"

	new Directory().Delete([ :path = cFolder, :recursive = True ])

# The LCS table: aTable[i][j] is the length of the LCS of the lines i.. of the old list and the lines j.. of the new list. It is
# filled from the end to the start, and the cell [1][1] has the answer for the whole lists.
func lcsTable aOld,aNew

	nOld = len(aOld)
	nNew = len(aNew)
	aTable = []
	for i = 1 to nOld + 1
		aRow = []
		for j = 1 to nNew + 1
			aRow + 0
		next
		aTable + aRow
	next
	for i = nOld to 1 step -1
		for j = nNew to 1 step -1
			if aOld[i] = aNew[j]
				aTable[i][j] = aTable[i + 1][j + 1] + 1
			else
				aTable[i][j] = max(aTable[i + 1][j],aTable[i][j + 1])
			ok
		next
	next
	return aTable

# the diff as a list of [mark, line]
func makeDiff aOld,aNew,aTable

	aDiff = []
	i = 1
	j = 1
	while i <= len(aOld) and j <= len(aNew)
		if aOld[i] = aNew[j]
			aDiff + [ " ", aOld[i] ]
			i++
			j++
		but aTable[i + 1][j] >= aTable[i][j + 1]
			aDiff + [ "-", aOld[i] ]
			i++
		else
			aDiff + [ "+", aNew[j] ]
			j++
		ok
	end
	while i <= len(aOld)
		aDiff + [ "-", aOld[i] ]
		i++
	end
	while j <= len(aNew)
		aDiff + [ "+", aNew[j] ]
		j++
	end
	return aDiff

func countOf aDiff,cMark

	nCount = 0
	for aItem in aDiff
		if aItem[1] = cMark
			nCount++
		ok
	next
	return nCount

func similarity aOld,aNew

	aDiff = makeDiff(aOld,aNew,lcsTable(aOld,aNew))
	return floor(100 * 2 * countOf(aDiff," ") / (len(aOld) + len(aNew)))

# the lines of the diff that are changes or are within nContext lines of a change; "..." marks the lines that were left out
func withContext aDiff,nContext

	aShow = []
	for i = 1 to len(aDiff)
		aShow + False
	next
	for i = 1 to len(aDiff)
		if aDiff[i][1] != " "
			for j = max(1,i - nContext) to min(len(aDiff),i + nContext)
				aShow[j] = True
			next
		ok
	next
	aOut = []
	lSkipped = False
	for i = 1 to len(aDiff)
		if aShow[i]
			aOut + (aDiff[i][1] + " " + aDiff[i][2])
			lSkipped = False
		but not lSkipped
			aOut + "..."
			lSkipped = True
		ok
	next
	return aOut
