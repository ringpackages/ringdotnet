# sets - HashSet, union, intersection, difference, subsets, and how a set removes duplicates and finds common items fast
load "dotnet.ring"

using {
	"System"
}

func main

	cText = "System.String"

	# A set holds each value ONCE and has no order. Adding a value that is already there changes nothing. Looking for a value is
	# very fast, even with a million values, because a set uses a hash table (a list has to look at every item).
	oSetA = makeSet(["ring","dotnet","linq","json","web"])
	oSetB = makeSet(["web","json","tcp","udp","ring","ring"])
	? "1. A has " + oSetA.Count + " items: " + sortedText(oSetA)
	? "   B has " + oSetB.Count + " items (the list had 6, 'ring' twice): " + sortedText(oSetB)

	# 2. The result of Add says whether the value was new
	? nl + "2. Add('tcp') to A: " + oSetA.Add("tcp") + " (new), Add('tcp') again: " + oSetA.Add("tcp") + " (already there)"
	oSetA.Remove("tcp")

	# 3. The four operations of set theory. They CHANGE the set they are called on, so each one works on a copy.
	? nl + "3. A = " + sortedText(oSetA) + "   B = " + sortedText(oSetB)
	oUnion = copySet(oSetA)
	oUnion.UnionWith(oSetB)
	? "   union (in A or B):               " + sortedText(oUnion)
	oBoth = copySet(oSetA)
	oBoth.IntersectWith(oSetB)
	? "   intersection (in A and in B):    " + sortedText(oBoth)
	oOnlyA = copySet(oSetA)
	oOnlyA.ExceptWith(oSetB)
	? "   difference (in A but not in B):  " + sortedText(oOnlyA)
	oEither = copySet(oSetA)
	oEither.SymmetricExceptWith(oSetB)
	? "   in A or B but not in both:       " + sortedText(oEither)

	# 4. Questions about two sets
	oSmall = makeSet(["ring","json"])
	? nl + "4. {ring, json} is a subset of A:  " + oSmall.IsSubsetOf(oSetA)
	? "   A is a superset of {ring, json}: " + oSetA.IsSupersetOf(oSmall)
	? "   A and B have items in common:  " + oSetA.Overlaps(oSetB)
	? "   A and {tcp, udp} have items in common: " + oSetA.Overlaps(makeSet(["tcp","udp"]))
	? "   A equals A with the same items in another order: " + oSetA.SetEquals(makeSet(["web","json","linq","dotnet","ring"]))

	# 5. A set with a comparer: names that differ only in case are the same item (the tutorial "Comparing text")
	oNames = new HashSet([ :typeArguments = [cText], :comparer = new StringComparer().OrdinalIgnoreCase ])
	for cName in ["Ann","ann","BOB","Bob","Cy"]
		oNames.Add(cName)
	next
	? nl + "5. five names, case ignored: " + oNames.Count + " different people"

	# 6. Removing duplicates from a Ring list is one line with a set. The order of a HashSet is not defined: sort when it matters.
	aWithDuplicates = [5,3,5,1,3,8,1,5]
	oIntSet = new HashSet([ :typeArguments = ["System.Int32"] ])
	for nNumber in aWithDuplicates
		oIntSet.Add(nNumber)
	next
	aUnique = sort(oIntSet.toList())
	? nl + "6. " + len(aWithDuplicates) + " numbers, " + len(aUnique) + " different: " + list2text(aUnique)

func makeSet aList

	oSet = new HashSet([ :typeArguments = ["System.String"] ])
	for cItem in aList
		oSet.Add(cItem)
	next
	return oSet

# a copy of a set: the constructor of HashSet takes a collection
func copySet oSet

	return new HashSet([ :typeArguments = ["System.String"], :collection = oSet ])

func sortedText oSet

	return list2text(sort(oSet.toList()))

func list2text aList

	cText = ""
	for item in aList
		cText += "" + item + " "
	next
	return cText
