# Audit of the public API of assemblies: how much of it can Ring use, and what gets in the way?
#   ring auditassembly.ring Library.dll                 the table of one assembly
#   ring auditassembly.ring A.dll B.dll C.dll           one table for each, then the total of all of them
#   ring auditassembly.ring --quiet A.dll B.dll         only the total
# The rules are those of the bridge (the same ones that wrapassembly.ring and the generator use), so the answer is what the generator does:
#   OK    something Ring can use (a type that gets a class, a method that can be called, an event ...)
#   INFO  a fact about the assembly
#   GAP   something Ring cannot use today (a generic type, a nested type, a Span parameter, an operator ...)
# The GAP lines of the total are sorted by how many members they touch: that is the list to work from.
load "../../libraries/dotnetlib/dotnetlib.ring"

func main
	aFiles = []
	lQuiet = False
	for nIndex = 3 to len(sysargv)
		if sysargv[nIndex] = "--quiet"
			lQuiet = True
		else
			aFiles + sysargv[nIndex]
		ok
	next
	if len(aFiles) = 0
		? "usage: ring auditassembly.ring [--quiet] Library.dll [Other.dll ...]"
		return
	ok
	aTags = []          # the tags in the order they were met
	aTotals = []        # the count of each tag over all the assemblies
	aExamples = []      # an example of each tag: "assembly: Type.member"
	for cFile in aFiles
		try
			dnLoad(cFile)
			aResult = dnRequest("auditassembly",[cFile])
		catch
			? "could not read " + cFile + ": " + left(cCatchError,100)
			loop
		done
		if not lQuiet
			? nl + "== " + cFile
			show(aResult)
		ok
		for aItem in aResult
			cTag = aItem[1]
			nAt = find(aTags,cTag)
			if nAt = 0
				aTags + cTag
				aTotals + 0
				aExamples + ""
				nAt = len(aTags)
			ok
			aTotals[nAt] += aItem[2]
			if aExamples[nAt] = "" and len(aItem[3]) > 0
				aExamples[nAt] = justName(cFile) + ": " + aItem[3][1]
			ok
		next
	next
	if len(aFiles) > 1 or lQuiet
		? nl + "== total of " + len(aFiles) + " assembl" + iif(len(aFiles) = 1,"y","ies")
		aAll = []
		for nAt = 1 to len(aTags)
			aAll + [aTags[nAt],aTotals[nAt],[aExamples[nAt]]]
		next
		show(aAll)
		summary(aAll)
	ok

# the lines of a result, grouped by the first word of the tag, the GAP lines last and the biggest first
func show aResult
	for cKind in ["OK","INFO","GAP"]
		aLines = []
		for aItem in aResult
			if trim(left(aItem[1],5)) = cKind
				aLines + aItem
			ok
		next
		aLines = sortByCount(aLines)
		for aItem in aLines
			cExample = ""
			if len(aItem[3]) > 0
				cExample = "   e.g. " + aItem[3][1]
			ok
			? padLeft("" + aItem[2],7) + "  " + aItem[1] + cExample
		next
	next

func sortByCount aLines
	for i = 1 to len(aLines) - 1
		for j = i + 1 to len(aLines)
			if aLines[j][2] > aLines[i][2]
				aTemp = aLines[i]
				aLines[i] = aLines[j]
				aLines[j] = aTemp
			ok
		next
	next
	return aLines

func count aResult, cTag
	for aItem in aResult
		if aItem[1] = cTag
			return aItem[2]
		ok
	next
	return 0

# the numbers that matter, as percentages
func summary aResult
	nTypes = count(aResult,"INFO type: public types")
	nWrapped = count(aResult,"OK   type: wrapped (class, struct, interface)")
	nEnums = count(aResult,"OK   type: enum (a text in Ring)")
	nDelegates = count(aResult,"OK   type: delegate (a callback in Ring)")
	nGeneric = count(aResult,"GAP  type: generic type definition (not wrapped)")
	nNested = count(aResult,"GAP  type: nested type (not wrapped)")
	nMethods = count(aResult,"INFO method: public methods")
	nCallable = count(aResult,"OK   method: callable")
	nLost = count(aResult,"GAP  members of types that are not wrapped")
	? nl + "summary"
	if nTypes > 0
		? "  types that Ring can use (wrapped, enums, delegates): " + percent(nWrapped + nEnums + nDelegates,nTypes) + "   (generic definitions " + nGeneric + ", nested " + nNested + ")"
	ok
	if nMethods > 0
		? "  methods that can be called, in the types that are wrapped: " + percent(nCallable,nMethods)
	ok
	? "  members (methods, constructors, properties) in types that are not wrapped: " + nLost

func percent nPart, nWhole
	return "" + floor(nPart * 100 / nWhole) + " % (" + nPart + " of " + nWhole + ")"

func padLeft cText, nWidth
	return copy(" ",nWidth - len(cText)) + cText

func justName cPath
	cPath = substr(cPath,"\","/")
	nSlash = 0
	for i = len(cPath) to 1 step -1
		if cPath[i] = "/"
			nSlash = i
			exit
		ok
	next
	return substr(cPath,nSlash + 1,len(cPath))

func iif lCondition, xYes, xNo
	if lCondition
		return xYes
	ok
	return xNo
