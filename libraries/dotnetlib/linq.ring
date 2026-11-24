/*
	DotNetQuery - a fluent LINQ wrapper (loaded with the namespace System.Linq: using { "System.Linq" })

	oResult = dnQuery([5,3,8,1]).Where("xDotNetResult = aDotNetArgs[1] > 2").OrderBy("xDotNetResult = aDotNetArgs[1]").ToList()

	The source is a Ring list or any .NET collection. The selector/predicate arguments are Ring code
	(see dnCallback): aDotNetArgs[1] is the item, xDotNetResult the result. The name of a Ring function works too (it gets the list of
	arguments and returns the result).
*/

# A query on a Ring list or a .NET collection: dnQuery(aList).Where("...").ToList()
func dnQuery  xSource
	return new DotNetQuery(xSource)

class DotNetQuery

	oSource = NULL

	# a query on xSource, a Ring list or a .NET collection (made by dnQuery)
	func init  xSource
		oSource = xSource
		return self

	# ---- operators that return a query
	# the items for which the code gives true
	func Where  cCode
		return new DotNetQuery(dnLinq("Where",[oSource,dnCode(cCode)]))

	# the code applied to every item (the results are the new items)
	func Select  cCode
		return new DotNetQuery(dnLinq("Select",[oSource,dnCode(cCode)]))

	# the code gives a list for every item; the lists are joined into one
	func SelectMany  cCode
		return new DotNetQuery(dnLinq("SelectMany",[oSource,dnCode(cCode)]))

	# sort by the value that the code gives for an item
	func OrderBy  cCode
		return new DotNetQuery(dnLinq("OrderBy",[oSource,dnCode(cCode)]))

	# sort by the value that the code gives, the largest first
	func OrderByDescending  cCode
		return new DotNetQuery(dnLinq("OrderByDescending",[oSource,dnCode(cCode)]))

	# after OrderBy: sort items with the same value by another value
	func ThenBy  cCode
		return new DotNetQuery(dnLinq("ThenBy",[oSource,dnCode(cCode)]))

	# after OrderBy: sort items with the same value by another value, the largest first
	func ThenByDescending  cCode
		return new DotNetQuery(dnLinq("ThenByDescending",[oSource,dnCode(cCode)]))

	# the items from the start, while the code gives true
	func TakeWhile  cCode
		return new DotNetQuery(dnLinq("TakeWhile",[oSource,dnCode(cCode)]))

	# leave out the items from the start, while the code gives true
	func SkipWhile  cCode
		return new DotNetQuery(dnLinq("SkipWhile",[oSource,dnCode(cCode)]))

	# the first nCount items
	func Take  nCount
		return new DotNetQuery(dnLinq("Take",[oSource,nCount]))

	# leave out the first nCount items
	func Skip  nCount
		return new DotNetQuery(dnLinq("Skip",[oSource,nCount]))

	# every value once
	func Distinct
		return new DotNetQuery(dnLinq("Distinct",[oSource]))

	# the items in the opposite order
	func Reverse
		return new DotNetQuery(dnLinq("Reverse",[oSource]))

	# the items followed by the items of oOther (a query, a list or a .NET collection)
	func Concat  oOther
		return new DotNetQuery(dnLinq("Concat",[oSource,dnQuerySource(oOther)]))

	# the values of both sources, every value once
	func Union  oOther
		return new DotNetQuery(dnLinq("Union",[oSource,dnQuerySource(oOther)]))

	# the values that both sources have
	func Intersect  oOther
		return new DotNetQuery(dnLinq("Intersect",[oSource,dnQuerySource(oOther)]))

	# the values of this source that oOther does not have
	func Except  oOther
		return new DotNetQuery(dnLinq("Except",[oSource,dnQuerySource(oOther)]))

	# ---- operators that return a value
	# run the query: the result as a Ring list
	func ToList
		if islist(oSource)
			return oSource
		ok
		return dnRequest("tolist",[oSource])

	# the number of items
	func Count
		return len(ToList())

	# the number of items for which the code gives true
	func CountWhere  cCode
		return dnLinq("Count",[oSource,dnCode(cCode)])

	# 1 when the code gives true for at least one item
	func Any  cCode
		return dnLinq("Any",[oSource,dnCode(cCode)])

	# 1 when the code gives true for every item
	func All  cCode
		return dnLinq("All",[oSource,dnCode(cCode)])

	# 1 when the source has the value xValue
	func Contains  xValue
		return dnLinq("Contains",[oSource,xValue])

	# the first item (an error when there is none)
	func First
		return dnLinq("First",[oSource])

	# the first item for which the code gives true
	func FirstWhere  cCode
		return dnLinq("First",[oSource,dnCode(cCode)])

	# the last item (an error when there is none)
	func Last
		return dnLinq("Last",[oSource])

	# the item at the zero-based position nIndex
	func ElementAt  nIndex
		return dnLinq("ElementAt",[oSource,nIndex])

	# Sum, Min, Max and Average are computed on the selected values (cCode = "" for the items themselves)
	func Sum  cCode
		nTotal = 0
		aSelected = dnSelected(cCode)
		for xItem in aSelected
			nTotal += xItem
		next
		return nTotal

	# the average of the selected values (cCode = "" for the items themselves)
	func Average  cCode
		aValues = dnSelected(cCode)
		if len(aValues) = 0
			raise("DotNet Error: Sequence contains no elements")
		ok
		return Sum(cCode) / len(aValues)

	# the smallest of the selected values (cCode = "" for the items themselves)
	func Min  cCode
		aValues = dnSelected(cCode)
		if len(aValues) = 0
			raise("DotNet Error: Sequence contains no elements")
		ok
		xMin = aValues[1]
		for xItem in aValues
			if xItem < xMin xMin = xItem ok
		next
		return xMin

	# the largest of the selected values (cCode = "" for the items themselves)
	func Max  cCode
		aValues = dnSelected(cCode)
		if len(aValues) = 0
			raise("DotNet Error: Sequence contains no elements")
		ok
		xMax = aValues[1]
		for xItem in aValues
			if xItem > xMax xMax = xItem ok
		next
		return xMax

	# the values that the code selects (the items themselves for ""), as a Ring list: used by Sum, Average, Min and Max
	func dnSelected  cCode
		if cCode = ""
			return ToList()
		ok
		return new DotNetQuery(dnLinq("Select",[oSource,dnCode(cCode)])).ToList()

# Call System.Linq.Enumerable.<cName> (the type is found in the System.Linq assembly)
func dnLinq  cName, aArguments
	return dnRequest("call",dnJoin([dnTypeCached("System.Linq.Enumerable, System.Linq"),cName],aArguments))

# Ring code (or a function name) as a callback
func dnCode  xCode
	if isstring(xCode)
		return dnCallback(xCode)
	ok
	return xCode

# The source of another query (a DotNetQuery, a Ring list or a .NET object)
func dnQuerySource  oOther
	if isobject(oOther) and isattribute(oOther,"oSource")
		return oOther.oSource
	ok
	return oOther
