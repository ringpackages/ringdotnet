# System.Linq.Async: LINQ over an IAsyncEnumerable (an async iterator made by a Ring-callable .NET method), with the type argument of each generic method; the stream is read with toList()
load "pkg.ring"
pkgUse("linqasync",[["System.Linq.Async","7.0.1"]],[["System.Linq.Async.dll",[]]])
dnImport("System")
dnImport("System.Collections.Generic")          # the classes of IAsyncEnumerator and the like

# an async sequence: Range through ToAsyncEnumerable of the extension class
cAsync = "System.Linq.AsyncEnumerable"
oSource = dnType(cAsync).callGeneric("ToAsyncEnumerable",["System.Int32"],[ [1,2,3,4,5,6] ])
dnAssert("a sequence from a list",len(oSource.toList()),6)

oWhere = dnType(cAsync).callGeneric("Where",["System.Int32"],[oSource,dnCallback("isEven")])
dnAssert("Where keeps the even numbers",len(oWhere.toList()),3)
dnAssert("the first even number",oWhere.toList()[1],2)

oSelect = dnType(cAsync).callGeneric("Select",["System.Int32","System.Int32"],[oSource,dnCallback("square")])
dnAssert("Select squares",oSelect.toList()[6],36)

# one item at a time
oEnum = oSource.asyncEnumerator()
nSum = 0
while oEnum.asyncNext()
	nSum += oEnum.getProp("Current")          # the object is wrapped as the first interface that it implements (IList), which has no Current: getProp
end
oEnum.asyncDispose()
dnAssert("the sum of the items read one at a time",nSum,21)

# the aggregates are tasks: CountAsync, SumAsync, FirstAsync with the type argument
oCount = dnType(cAsync).callGeneric("CountAsync",["System.Int32"],[oSource])
dnAssert("CountAsync",oCount.Result,6)
oFirst = dnType(cAsync).callGeneric("FirstAsync",["System.Int32"],[oSource])
dnAssert("FirstAsync",oFirst.Result,1)

dnTestSummary()

func isEven aArgs

	return aArgs[1] % 2 = 0

func square aArgs

	return aArgs[1] * aArgs[1]
