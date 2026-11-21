# arrays - Ring lists and .NET arrays, Array.Sort, Reverse, IndexOf, BinarySearch, Copy and Clear, and arrays with two dimensions
load "dotnet.ring"
using {
	"System"
}

func main
	oArray = new Array()

	# 1. A .NET array has a fixed size and one type. A Ring list becomes an array when a method asks for one: the bridge makes an int[],
	#    string[] or double[] from the values of the list. An array that comes back is a DotNetObject: toList() makes a Ring list of it.
	aNumbers = [42,7,19,3,25]
	oSorted = new Array().Sort(aNumbers)
	? "1. a list given to Array.Sort comes back unchanged: " + list2text(aNumbers) + "(the bridge sorted its own copy)"

	# 2. So to sort, reverse or search an array, make the array first: a List<Int32> filled with Add, and ToArray()
	oInts = makeIntArray([42,7,19,3,25])
	? nl + "2. an Int32 array of " + oInts.Length + " items: " + arrayText(oInts)
	new Array().Sort(oInts)
	? "   after Array.Sort:     " + arrayText(oInts)
	new Array().Reverse(oInts)
	? "   after Array.Reverse:  " + arrayText(oInts)

	# 3. Searching: IndexOf answers the position (0-based, as in .NET) or -1. BinarySearch is much faster, but the array must be
	#    SORTED; it answers a negative number (the complement of the place to insert) when the value is not there.
	new Array().Sort(oInts)
	? nl + "3. IndexOf(19) in the sorted array: " + dnStatic("System.Array","IndexOf",[oInts,19]) + "   (0-based: Ring would say 3)"
	? "   IndexOf(99): " + dnStatic("System.Array","IndexOf",[oInts,99])
	nFound = dnStatic("System.Array","BinarySearch",[oInts,19])
	nMissing = dnStatic("System.Array","BinarySearch",[oInts,20])
	? "   BinarySearch(19): " + nFound + ", BinarySearch(20): " + nMissing + "   (negative: not found; the complement " + (-nMissing - 1) + " is where 20 would go, 0-based)"

	# 4. Copy and Clear. Array.Copy(source, target, count) copies the first items into another array; Clear(array, start, count) sets items to zero
	oTarget = makeIntArray([0,0,0,0,0,0,0,0])
	dnStatic("System.Array","Copy",[oInts,oTarget,oInts.Length])
	? nl + "4. copied into a bigger array: " + arrayText(oTarget)
	dnStatic("System.Array","Clear",[oTarget,0,3])
	? "   Array.Clear(array, 0, 3) sets 3 items to zero: " + arrayText(oTarget)

	# 5. An array of texts, and the join of a list into one text
	oWordList = dnNewGeneric("System.Collections.Generic.List",["System.String"],[])
	for cWord in ["pear","apple","fig"]
		oWordList.Add(cWord)
	next
	oWords = oWordList.ToArray()
	new Array().Sort(oWords)
	? nl + "5. sorted words: " + arrayText(oWords)

	# 6. Two dimensions: a table with rows and columns. Array.CreateInstance(type, rows, columns); items are written with SetValue(value, row, column)
	#    and read with GetValue(row, column). The items are Doubles, because SetValue needs the type that a Ring number has.
	oGrid = dnStatic("System.Array","CreateInstance",[dnType("System.Double"),3,4])
	for nRow = 0 to 2
		for nColumn = 0 to 3
			oGrid.SetValue([ :value = nRow * 10 + nColumn, :index1 = nRow, :index2 = nColumn ])
		next
	next
	? nl + "6. a 3 x 4 table (rank " + oGrid.Rank + ", " + oGrid.Length + " items, " + oGrid.@GetLength(0) + " rows, " + oGrid.@GetLength(1) + " columns):"
	for nRow = 0 to 2
		cLine = "   "
		for nColumn = 0 to 3
			cLine += padLeft("" + oGrid.GetValue([ :index1 = nRow, :index2 = nColumn ]),4)
		next
		? cLine
	next

# A typed array is made from a list: add the values to a List<Int32> and call ToArray(). (SetValue takes an object, and a Ring number
# arrives there as a double, which an Int32 array refuses.)
func makeIntArray aList
	oList = dnNewGeneric("System.Collections.Generic.List",["System.Int32"],[])
	for nValue in aList
		oList.Add(nValue)
	next
	return oList.ToArray()

func arrayText oArray
	cText = ""
	for item in oArray.toList()
		cText += "" + item + " "
	next
	return cText

func list2text aList
	cText = ""
	for item in aList
		cText += "" + item + " "
	next
	return cText

func padLeft cText,nWidth
	return copy(" ",nWidth - len(cText)) + cText
