# comparing text - ordinal and culture comparison, ignoring case, StringComparer and a sorted set that ignores case
load "dotnet.ring"

using {
	"System"
	"System.Globalization"
	"System.Collections.Generic"
}

func main

	oString = new String()
	# 1. Two texts can be compared in different ways. Ordinal compares the code of every character: fast, exact, the same on every
	#    computer. Culture-aware comparison follows the rules of a language (in German "ä" is close to "a"). Both can ignore case.
	? "1. 'apple' = 'APPLE'"
	? "   ordinal:                " + (oString.Compare([ :strA = "apple", :strB = "APPLE", :comparisonType = "Ordinal" ]) = 0)
	? "   ordinal, ignore case:    " + (oString.Compare([ :strA = "apple", :strB = "APPLE", :comparisonType = "OrdinalIgnoreCase" ]) = 0)
	? "   invariant culture, ignore case: " + (oString.Compare([ :strA = "apple", :strB = "APPLE", :comparisonType = "InvariantCultureIgnoreCase" ]) = 0)

	# 2. The result of Compare is negative, zero or positive: only the SIGN means something
	? nl + "2. Compare('a','b') is negative: " + (oString.Compare([ :strA = "a", :strB = "b", :comparisonType = "Ordinal" ]) < 0)
	? "   Compare('b','a') is positive: " + (oString.Compare([ :strA = "b", :strB = "a", :comparisonType = "Ordinal" ]) > 0)

	# 3. Capital letters come before small letters in ordinal order (the code of "Z" is smaller than the code of "a"),
	#    a culture puts "a" and "A" next to each other
	oOrdinal = new StringComparer().Ordinal
	oCulture = new StringComparer().InvariantCulture
	oWords = new List([ :typeArguments = ["System.String"] ])
	for cWord in ["banana","Cherry","apple","Banana","cherry","Apple"]
		oWords.Add(cWord)
	next
	oWords.Sort(oOrdinal)
	? nl + "3. ordinal order:  " + joinList(oWords.toList())
	oWords.Sort(oCulture)
	? "   culture order:  " + joinList(oWords.toList())
	oWords.Sort(new StringComparer().OrdinalIgnoreCase)
	? "   ignore case:    " + joinList(oWords.toList()) + "   (equal words can come in any order)"

	# 4. A dictionary that ignores case: the comparer is the second argument of the constructor
	oPeople = new Dictionary([ :typeArguments = ["System.String","System.Int32"], :comparer = new StringComparer().OrdinalIgnoreCase ])
	oPeople.callMethod("Add",["Ann",31])
	? nl + "4. the key 'ANN' finds the key 'Ann': " + oPeople.callMethod("ContainsKey",["ANN"])
	oPlain = new Dictionary([ :typeArguments = ["System.String","System.Int32"] ])
	oPlain.callMethod("Add",["Ann",31])
	? "   a plain dictionary does not: " + oPlain.callMethod("ContainsKey",["ANN"])

	# 5. A sorted set with the same idea keeps one of 'Apple' and 'apple'
	oSet = new SortedSet([ :typeArguments = ["System.String"], :comparer = new StringComparer().OrdinalIgnoreCase ])
	for cWord in ["Apple","apple","Pear","APPLE","pear"]
		oSet.Add(cWord)
	next
	? nl + "5. " + oSet.Count + " words stay in the set: " + joinList(oSet.toList())

	# 6. The same letter is not the same in every culture. In Turkish the capital of "i" is "İ" (with a dot) and the small
	#    letter of "I" is "ı" (without a dot): upper-casing with the wrong culture breaks a comparison like "TITLE" = "title"
	oTurkish = new CultureInfo("tr-TR")
	? nl + "6. 'title' in capitals, invariant culture: " + upperText("title",new CultureInfo(""))
	? "   'title' in capitals, Turkish culture:   " + upperText("title",oTurkish)

func upperText cText,oCulture

	return oCulture.TextInfo.ToUpper(cText)

func joinList aList

	cText = ""
	for item in aList
		cText += "" + item + " "
	next
	return cText
