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

	func init  xSource
		oSource = xSource
		return self

	# ---- operators that return a query
	func Where  cCode
		return new DotNetQuery(dnLinq("Where",[oSource,dnCode(cCode)]))

	func Select  cCode
		return new DotNetQuery(dnLinq("Select",[oSource,dnCode(cCode)]))

	func SelectMany  cCode
		return new DotNetQuery(dnLinq("SelectMany",[oSource,dnCode(cCode)]))

	func OrderBy  cCode
		return new DotNetQuery(dnLinq("OrderBy",[oSource,dnCode(cCode)]))

	func OrderByDescending  cCode
		return new DotNetQuery(dnLinq("OrderByDescending",[oSource,dnCode(cCode)]))

	func ThenBy  cCode
		return new DotNetQuery(dnLinq("ThenBy",[oSource,dnCode(cCode)]))

	func ThenByDescending  cCode
		return new DotNetQuery(dnLinq("ThenByDescending",[oSource,dnCode(cCode)]))

	func TakeWhile  cCode
		return new DotNetQuery(dnLinq("TakeWhile",[oSource,dnCode(cCode)]))

	func SkipWhile  cCode
		return new DotNetQuery(dnLinq("SkipWhile",[oSource,dnCode(cCode)]))

	func Take  nCount
		return new DotNetQuery(dnLinq("Take",[oSource,nCount]))

	func Skip  nCount
		return new DotNetQuery(dnLinq("Skip",[oSource,nCount]))

	func Distinct
		return new DotNetQuery(dnLinq("Distinct",[oSource]))

	func Reverse
		return new DotNetQuery(dnLinq("Reverse",[oSource]))

	func Concat  oOther
		return new DotNetQuery(dnLinq("Concat",[oSource,dnQuerySource(oOther)]))

	func Union  oOther
		return new DotNetQuery(dnLinq("Union",[oSource,dnQuerySource(oOther)]))

	func Intersect  oOther
		return new DotNetQuery(dnLinq("Intersect",[oSource,dnQuerySource(oOther)]))

	func Except  oOther
		return new DotNetQuery(dnLinq("Except",[oSource,dnQuerySource(oOther)]))

	# ---- operators that return a value
	func ToList
		if islist(oSource)
			return oSource
		ok
		return dnRequest("tolist",[oSource])

	func Count
		return len(ToList())

	func CountWhere  cCode
		return dnLinq("Count",[oSource,dnCode(cCode)])

	func Any  cCode
		return dnLinq("Any",[oSource,dnCode(cCode)])

	func All  cCode
		return dnLinq("All",[oSource,dnCode(cCode)])

	func Contains  xValue
		return dnLinq("Contains",[oSource,xValue])

	func First
		return dnLinq("First",[oSource])

	func FirstWhere  cCode
		return dnLinq("First",[oSource,dnCode(cCode)])

	func Last
		return dnLinq("Last",[oSource])

	func ElementAt  nIndex
		return dnLinq("ElementAt",[oSource,nIndex])

	# Sum, Min, Max and Average are computed on the selected values (cCode = "" for the items themselves)
	func Sum  cCode
		nTotal = 0
		for xItem in dnSelected(cCode)
			nTotal += xItem
		next
		return nTotal

	func Average  cCode
		aValues = dnSelected(cCode)
		if len(aValues) = 0
			raise("DotNet Error: Sequence contains no elements")
		ok
		return Sum(cCode) / len(aValues)

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
