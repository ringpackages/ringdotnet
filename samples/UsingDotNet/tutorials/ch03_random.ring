# randomness - seeds, dice, shuffling cards, weighted choices, unique ids, and when "random" must be secure
load "dotnet.ring"

using {
	"System"
	"System.Security.Cryptography"
}

func main

	# 1. Random with a SEED gives the same sequence every time: perfect for tests and for repeating a simulation
	oFirst = new Random(2024)
	oSecond = new Random(2024)
	? "1. two generators with the same seed: " + oFirst.@Next(100) + " " + oFirst.@Next(100) + " " + oFirst.@Next(100) + "  and  " + oSecond.@Next(100) + " " + oSecond.@Next(100) + " " + oSecond.@Next(100)

	# 2. @Next(max) is 0..max-1. A die is @Next(6) + 1. Throw it 6000 times: each side comes up about 1000 times.
	oRandom = new Random(7)
	aCount = [0,0,0,0,0,0]
	for nThrow = 1 to 6000
		nSide = oRandom.@Next(6) + 1
		aCount[nSide]++
	next
	? nl + "2. 6000 throws of a die: " + joinWith(aCount," ")
	lFair = True
	for nCount in aCount
		if nCount < 900 or nCount > 1100
			lFair = False
		ok
	next
	? "   every side between 900 and 1100 times? " + yesNo(lFair)

	# 3. Shuffling a deck: the Fisher-Yates way. Go from the end; swap each card with a random card from the start up to it.
	aDeck = []
	for nCard = 1 to 10
		aDeck + nCard
	next
	for nIndex = len(aDeck) to 2 step -1
		nOther = oRandom.@Next(nIndex) + 1
		aTemp = aDeck[nIndex]
		aDeck[nIndex] = aDeck[nOther]
		aDeck[nOther] = aTemp
	next
	? nl + "3. a shuffled deck of 10: " + joinWith(aDeck," ") + "   (still 10 different cards: " + yesNo(len(aDeck) = 10 and sumOf(aDeck) = 55) + ")"

	# 4. A weighted choice: some outcomes are more likely. Pick a number below the total and walk through the weights.
	aItems = [["common",70],["rare",25],["legendary",5]]
	aWon = [0,0,0]
	for nDraw = 1 to 10000
		nPick = oRandom.@Next(100)
		nSum = 0
		for nIndex = 1 to len(aItems)
			nSum += aItems[nIndex][2]
			if nPick < nSum
				aWon[nIndex]++
				exit
			ok
		next
	next
	? nl + "4. 10000 draws with chances 70 / 25 / 5 percent:"
	for nIndex = 1 to 3
		? "   " + padRight(aItems[nIndex][1],10) + aWon[nIndex]
	next

	# 5. Unique identifiers: a Guid is 128 random bits; the chance of two equal Guids is practically zero
	oGuid = new Guid().NewGuid()
	cGuid = oGuid.ToString()
	? nl + "5. a Guid has " + len(cGuid) + " characters (8-4-4-4-12 hexadecimal digits); two new Guids are different: " + yesNo(new Guid().NewGuid().ToString() != new Guid().NewGuid().ToString())

	# 6. Random is predictable: with a few outputs one can calculate the next ones. Passwords, tokens and keys need real randomness.
	oSecure = new RandomNumberGenerator()
	nSecure = oSecure.GetInt32(1000000)
	? nl + "6. a secure number from RandomNumberGenerator.GetInt32: " + yesNo(nSecure >= 0 and nSecure < 1000000) + " (in range); a different one every run"

func sumOf aList

	nSum = 0
	for nItem in aList
		nSum += nItem
	next
	return nSum

func joinWith aList, cSeparator

	cText = ""
	for xItem in aList
		if cText != ""
			cText += cSeparator
		ok
		cText += xItem
	next
	return cText

func padRight cText, nWidth

	while len(cText) < nWidth
		cText += " "
	end
	return cText

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"
