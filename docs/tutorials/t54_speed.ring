# Tutorial 54: speed - measure first, then choose: Stopwatch, StringBuilder, a cache (memoization) and fewer calls
load "dotnet.ring"
using {
	"System"
	"System.Diagnostics"
	"System.Text"
	"System.Collections.Generic"
}

nCalls = 0
nCachedCalls = 0
aCache = []

func main
	# 1. Measure with a Stopwatch. A guess about speed is often wrong.
	oWatch = new Stopwatch()
	oWatch.Start()
	nSum = 0
	for nI = 1 to 200000
		nSum += nI
	next
	oWatch.Stop()
	? "1. A loop of 200000 additions gives " + nSum + " (measured: " + (oWatch.ElapsedMilliseconds >= 0) + ")"

	# 2. Building a big text: Ring's own += against the .NET StringBuilder. In other languages the builder always wins; here every
	#    Append is a call over the bridge, so do not assume - measure.
	nTextTime = timeOf(:buildWithPlus)
	nBuilderTime = timeOf(:buildWithBuilder)
	? nl + "2. Same text (20000 pieces), two ways:"
	if nBuilderTime < nTextTime
		? "   the faster one: StringBuilder"
	else
		? "   the faster one: Ring's own +="
	ok
	? "   same result? " + yesNo(len(buildWithPlus(0)) = len(buildWithBuilder(0)))

	# 3. A cache (memoization): never compute the same thing twice. Fibonacci is the classic example.
	nSlow = timeOf(:fibSlow)
	nFast = timeOf(:fibCached)
	? nl + "3. fib(22): slow = " + fibSlow(22) + ", cached = " + fibCached(22)
	? "   Number of calls without a cache: " + nCalls + ", with a cache: " + nCachedCalls
	? "   the cached version is faster ? " + yesNo(nFast < nSlow)

	# 4. Fewer calls across the bridge: each .NET call has a small cost. Ask once for a list instead of 1000 times for one item.
	oList = new StringList()
	for nI = 1 to 500
		oList.Add("item" + nI)
	next
	nOne = timeOfItems(oList,False)
	nAll = timeOfItems(oList,True)
	? nl + "4. Reading 500 items: one by one over the bridge vs one call (ToList)"
	? "   one call is faster ? " + yesNo(nAll < nOne)

func timeOf cFunction
	oWatch = new Stopwatch()
	oWatch.Start()
	eval(cFunction + "(22)")
	oWatch.Stop()
	return oWatch.Elapsed.TotalMilliseconds

func timeOfItems oList, lAtOnce
	oWatch = new Stopwatch()
	oWatch.Start()
	nTotal = 0
	for nRound = 1 to 5
		if lAtOnce
			aItems = oList.ToList()
			nTotal += len(aItems)
		else
			for nIndex = 0 to oList.Count - 1
				nTotal += len(oList.Item(nIndex))
			next
		ok
	next
	oWatch.Stop()
	return oWatch.Elapsed.TotalMilliseconds

func buildWithPlus nIgnored
	cText = ""
	for nI = 1 to 20000
		cText += "piece " + nI + ";"
	next
	return cText

func buildWithBuilder nIgnored
	oBuilder = new StringBuilder(NULL)
	for nI = 1 to 20000
		oBuilder.Append("piece " + nI + ";")
	next
	return oBuilder.ToString()

func fibSlow n
	nCalls++
	if n < 2
		return n
	ok
	return fibSlow(n-1) + fibSlow(n-2)

func fibCached n
	nCachedCalls++
	if n < 2
		return n
	ok
	for aPair in aCache
		if aPair[1] = n
			return aPair[2]
		ok
	next
	nValue = fibCached(n-1) + fibCached(n-2)
	aCache + [n,nValue]
	return nValue

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
