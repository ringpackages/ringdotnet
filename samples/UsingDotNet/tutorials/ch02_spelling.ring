# a spell checker - a set of words, edit distance (Levenshtein) and the best suggestions
load "dotnet.ring"

using {
	"System.Collections.Generic"
	"System.Text.RegularExpressions"
}

aDictionary = ["the","quick","brown","fox","jumps","over","lazy","dog","and","then","there","their","brain","crown","frown","jump","quack","quiet","lake","dig","dot","dug"]

func main

	# 1. A StringSet (a .NET HashSet) answers "is this word known?" at once, however many words it holds
	oWords = new StringSet()
	for cWord in aDictionary
		oWords.Add(cWord)
	next
	? "1. the dictionary has " + oWords.Count + " words. Contains 'fox'? " + yesNo(oWords.Contains("fox")) + ", 'fax'? " + yesNo(oWords.Contains("fax"))

	# 2. Edit distance: the least number of single-letter changes (insert, delete, replace) that turn one word into the other
	? nl + "2. distance(kitten, sitting) = " + distance("kitten","sitting") + "   (k->s, e->i, add g)"
	? "   distance(fox, fox) = " + distance("fox","fox") + ", distance(teh, the) = " + distance("teh","the") + ", distance(brwn, brown) = " + distance("brwn","brown")

	# 3. Suggestions: the dictionary words with the smallest distance to a word that is not known
	? nl + "3. suggestions for 'brwn'  : " + joinWith(suggest("brwn",3),", ")
	? "   suggestions for 'quik'  : " + joinWith(suggest("quik",3),", ")
	? "   suggestions for 'jumsp' : " + joinWith(suggest("jumsp",3),", ")

	# 4. Check a whole text: find the words with a regular expression, keep the position, mark what is unknown
	cText = "Teh quick brwn fox jumps ovr the lazy dgo"
	? nl + "4. checking: " + cText
	oMatches = new Regex("[A-Za-z]+").Matches(cText)
	nMistakes = 0
	for nIndex = 0 to oMatches.Count - 1
		cWord = lower(oMatches.Item(nIndex).Value)
		if not oWords.Contains(cWord)
			nMistakes++
			? "   '" + oMatches.Item(nIndex).Value + "' at position " + (oMatches.Item(nIndex).Index + 1) + " -> " + joinWith(suggest(cWord,2),", ")
		ok
	next
	? "   " + nMistakes + " words to check"

# The distance with a table: aTable[i][j] = the distance between the first i letters of cA and the first j letters of cB.
# The first row and column are the distances to the empty text. Each cell is the cheapest of: delete, insert, replace (free when the letters are equal).
func distance cA, cB

	nA = len(cA)
	nB = len(cB)
	aTable = []
	for nI = 0 to nA
		aRow = []
		for nJ = 0 to nB
			aRow + 0
		next
		aTable + aRow
	next
	for nI = 0 to nA
		aTable[nI + 1][1] = nI
	next
	for nJ = 0 to nB
		aTable[1][nJ + 1] = nJ
	next
	for nI = 1 to nA
		for nJ = 1 to nB
			nCost = 1
			if substr(cA,nI,1) = substr(cB,nJ,1)
				nCost = 0
			ok
			nDelete = aTable[nI][nJ + 1] + 1
			nInsert = aTable[nI + 1][nJ] + 1
			nReplace = aTable[nI][nJ] + nCost
			aTable[nI + 1][nJ + 1] = min(nDelete,min(nInsert,nReplace))
		next
	next
	return aTable[nA + 1][nB + 1]

# the nCount closest dictionary words: sorted by distance, equal distances alphabetically
func suggest cWord, nCount

	aScored = []
	for cKnown in aDictionary
		aScored + [distance(cWord,cKnown),cKnown]
	next
	for nI = 1 to len(aScored) - 1
		for nJ = nI + 1 to len(aScored)
			if aScored[nJ][1] < aScored[nI][1] or (aScored[nJ][1] = aScored[nI][1] and strcmp(aScored[nJ][2],aScored[nI][2]) < 0)
				aTemp = aScored[nI]
				aScored[nI] = aScored[nJ]
				aScored[nJ] = aTemp
			ok
		next
	next
	aBest = []
	for nI = 1 to min(nCount,len(aScored))
		aBest + aScored[nI][2]
	next
	return aBest

func joinWith aList, cSeparator

	cText = ""
	for cItem in aList
		if cText != ""
			cText += cSeparator
		ok
		cText += cItem
	next
	return cText

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"
