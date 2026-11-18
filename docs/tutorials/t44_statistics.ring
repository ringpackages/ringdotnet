# Tutorial 44: numbers - statistics, primes and a simulation (Monte Carlo estimate of pi)
load "dotnetlib.ring"
using {
	"System"
	"System.Linq"
}

func main
	aData = [4,8,15,16,23,42,8,15,8,4]

	# 1. The usual summaries of a set of numbers
	? "Data           : " + joinList(aData)
	? "Count, sum     : " + len(aData) + ", " + sumOf(aData)
	? "Mean (average) : " + mean(aData)
	? "Median (middle): " + median(aData)
	? "Mode (common)  : " + mode(aData)
	? "Smallest, largest: " + min(aData) + ", " + max(aData)
	? "Standard deviation: " + stdDev(aData)

	# 2. .NET gives the same answer with LINQ: a check of our own code
	? nl + "LINQ average   : " + dnQuery(aData).Average("") + " (same as the mean)"

	# 3. A histogram: how often each value occurs, as bars of #
	? nl + "Histogram:"
	aValues = []
	for nValue in sort(aData)
		if find(aValues,nValue) = 0
			aValues + nValue
		ok
	next
	for nValue in aValues
		? "   " + right("  " + nValue,2) + " " + copies("#",count(aData,nValue))
	next

	# 4. Primes: the sieve of Eratosthenes
	aPrimes = primesUpTo(100)
	? nl + "Primes up to 100: " + len(aPrimes) + " of them, the last is " + aPrimes[len(aPrimes)]

	# 5. Greatest common divisor and least common multiple
	? nl + "gcd(84, 36) = " + gcd(84,36) + ", lcm(4, 6) = " + lcm(4,6)

	# 6. A simulation: throw random points into a square. The share that falls inside the quarter circle is pi / 4
	oRandom = new Random(2024)                     # a fixed seed: the same numbers in every run
	nInside = 0
	nThrows = 20000
	for nThrow = 1 to nThrows
		nX = oRandom.NextDouble()
		nY = oRandom.NextDouble()
		if nX * nX + nY * nY <= 1
			nInside++
		ok
	next
	? nl + "Estimate of pi from " + nThrows + " random points: " + (4 * nInside / nThrows)
	? "Math.PI                                : " + new Math().PI

# ---------------------------------------------------------------- the formulas (small functions, each testable)

func sumOf aList
	nSum = 0
	for nValue in aList
		nSum += nValue
	next
	return nSum

func mean aList
	return sumOf(aList) / len(aList)

func median aList
	aSorted = sort(aList)
	nMiddle = len(aSorted) / 2
	if len(aSorted) % 2 = 1
		return aSorted[ceil(nMiddle)]
	ok
	return (aSorted[nMiddle] + aSorted[nMiddle + 1]) / 2

func mode aList
	nBest = aList[1]
	nBestCount = 0
	for nValue in aList
		nTimes = count(aList,nValue)
		if nTimes > nBestCount
			nBest = nValue
			nBestCount = nTimes
		ok
	next
	return nBest

func stdDev aList
	nMean = mean(aList)
	nSquares = 0
	for nValue in aList
		nSquares += (nValue - nMean) * (nValue - nMean)
	next
	return sqrt(nSquares / len(aList))

func count aList, nValue
	nTimes = 0
	for nItem in aList
		if nItem = nValue
			nTimes++
		ok
	next
	return nTimes

func primesUpTo nLimit
	aIsPrime = list(nLimit)
	for nIndex = 1 to nLimit
		aIsPrime[nIndex] = True
	next
	aIsPrime[1] = False
	for nNumber = 2 to floor(sqrt(nLimit))
		if aIsPrime[nNumber]
			for nMultiple = nNumber * nNumber to nLimit step nNumber
				aIsPrime[nMultiple] = False
			next
		ok
	next
	aPrimes = []
	for nIndex = 1 to nLimit
		if aIsPrime[nIndex]
			aPrimes + nIndex
		ok
	next
	return aPrimes

func gcd nA, nB
	while nB != 0
		nTemp = nB
		nB = nA % nB
		nA = nTemp
	end
	return nA

func lcm nA, nB
	return nA * nB / gcd(nA,nB)

func copies cText, nTimes
	cResult = ""
	for nIndex = 1 to nTimes
		cResult += cText
	next
	return cResult

func joinList aList
	cText = ""
	for xItem in aList
		if cText != ""
			cText += ", "
		ok
		cText += xItem
	next
	return cText
