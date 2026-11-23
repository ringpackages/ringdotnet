# money - why 0.1 + 0.2 is not 0.3, cents as whole numbers, rounding rules and fair splitting
load "dotnet.ring"

using {
	"System"
}

func main

	# 1. Computers store fractions in binary: 0.1 and 0.2 cannot be written exactly, so tiny errors appear
	? "1. 0.1 + 0.2 = 0.3 ?  " + yesNo((0.1 + 0.2) = 0.3)
	nTotal = 0
	for nI = 1 to 10
		nTotal += 0.1
	next
	? "   ten times 0.1 equals 1 ?  " + yesNo(nTotal = 1)

	# 2. The rule for money: keep whole CENTS (integers) and only turn them into "12.50" when you show them
	nPriceCents = toCents("19.99")
	nTotalCents = nPriceCents * 3
	? nl + "2. three items of 19.99 = " + showMoney(nTotalCents)

	# 3. Percentages need a rounding rule. The tax of 7.5 % on 19.99 is 1.49925: how many cents?
	nTaxExact = nPriceCents * 7.5 / 100
	? nl + "3. tax on " + showMoney(nPriceCents) + " at 7.5 % is 149.925 cents: a part of a cent does not exist"
	? "   rounded to the nearest cent: " + roundHalfUp(nTaxExact) + " cents = " + showMoney(roundHalfUp(nTaxExact))

	# 4. "Half" cases: 2.5 rounds to 2 in banker's rounding (the .NET default) and to 3 in school rounding
	oMath = new Math()
	? nl + "4. rounding 0.5, 1.5, 2.5, 3.5:"
	? "   banker's (to even)  : " + roundList(oMath,"ToEven")
	? "   school (away from 0): " + roundList(oMath,"AwayFromZero")

	# 5. Splitting 100.00 into 3 shares must give back exactly 100.00: the extra cents go to the first shares
	aShares = splitCents(10000,3)
	? nl + "5. 100.00 split in 3: " + showMoney(aShares[1]) + ", " + showMoney(aShares[2]) + ", " + showMoney(aShares[3])
	? "   the shares add up to " + showMoney(aShares[1] + aShares[2] + aShares[3])

	# 6. An invoice: lines in cents, the total, the tax on the total (not on every line!), the grand total
	aLines = [["Notebook",1250,2],["Pen",199,10],["Backpack",4599,1]]
	? nl + "6. An invoice:"
	nSubtotal = 0
	for aLine in aLines
		nSubtotal += aLine[2] * aLine[3]
		? "   " + padRight(aLine[1],10) + padLeft(showMoney(aLine[2]),8) + " x " + aLine[3]
	next
	nTax = roundHalfUp(nSubtotal * 20 / 100)
	? "   subtotal " + showMoney(nSubtotal) + ", tax 20 % " + showMoney(nTax) + ", total " + showMoney(nSubtotal + nTax)

# "19.99" -> 1999
func toCents cText

	return floor(number(cText) * 100 + 0.5)

# 1999 -> "19.99"
func showMoney nCents

	cSign = ""
	if nCents < 0
		cSign = "-"
		nCents = -nCents
	ok
	nUnits = floor(nCents / 100)
	nRest = nCents - nUnits * 100
	cRest = "" + nRest
	if len(cRest) < 2
		cRest = "0" + cRest
	ok
	return cSign + nUnits + "." + cRest

func roundHalfUp nValue

	return floor(nValue + 0.5)

func roundList oMath, cMode

	cText = ""
	for nValue in [0.5,1.5,2.5,3.5]
		nRounded = oMath.Round([ :value = nValue, :mode = cMode ])
		cText += "" + nRounded + " "
	next
	return trim(cText)

# n cents in parts shares, the first shares get the remaining cents
func splitCents nCents, nParts

	nShare = floor(nCents / nParts)
	nRest = nCents - nShare * nParts
	aList = []
	for nI = 1 to nParts
		if nI <= nRest
			aList + (nShare + 1)
		else
			aList + nShare
		ok
	next
	return aList

func padRight cText, nWidth

	while len(cText) < nWidth
		cText += " "
	end
	return cText

func padLeft cText, nWidth

	while len(cText) < nWidth
		cText = " " + cText
	end
	return cText

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"
