# System.Linq.Dynamic.Core: LINQ with the conditions and orderings as text; extension methods of IQueryable<T> with string arguments
load "pkg.ring"
pkgUse("dynamiclinq",[["System.Linq.Dynamic.Core","1.6.0"]],[["System.Linq.Dynamic.Core.dll",["System.Linq.Dynamic.Core"]]])
pkgImport("dynamiclinq","System.Linq.Dynamic.Core.dll","System.Linq.Dynamic.Core")
dnImport("System.Linq")
dnImport("System.Collections.Generic")

oNumbers = dnNew("System.Collections.Generic.List`1[[System.Int32]]",[])
for i = 1 to 10
	oNumbers.Add(i)
next
oQuery = dnType("System.Linq.Queryable").callGeneric("AsQueryable",["System.Int32"],[oNumbers])

oBig = dnType("System.Linq.Dynamic.Core.DynamicQueryableExtensions").callGeneric("Where",["System.Int32"],[oQuery,"it > 7"])
dnAssert("a condition as text",len(oBig.toList()),3)

oEven = dnType("System.Linq.Dynamic.Core.DynamicQueryableExtensions").callGeneric("Where",["System.Int32"],[oQuery,"it % 2 == 0"])
dnAssert("a condition with a remainder",len(oEven.toList()),5)

oBoth = dnType("System.Linq.Dynamic.Core.DynamicQueryableExtensions").callGeneric("Where",["System.Int32"],[oEven,"it > 4"])
dnAssert("conditions in a chain",len(oBoth.toList()),3)

oOrdered = dnType("System.Linq.Dynamic.Core.DynamicQueryableExtensions").callMethod("OrderBy",[oQuery,"it desc"])
dnAssert("an ordering as text",oOrdered.toList()[1],10)

dnAssert("a count",dnType("System.Linq.Dynamic.Core.DynamicQueryableExtensions").callMethod("Count",[oBig]),3)

cError = ""
try
	dnType("System.Linq.Dynamic.Core.DynamicQueryableExtensions").callGeneric("Where",["System.Int32"],[oQuery,"it >>> ("]).toList()
catch
	cError = cCatchError
done
dnAssert("a broken condition raises an error",len(cError) > 0,1)

dnTestSummary()
