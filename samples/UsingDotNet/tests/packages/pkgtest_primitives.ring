# Microsoft.Extensions.Primitives: StringValues (a struct that is one text or many), StringSegment, StringTokenizer
load "pkg.ring"
pkgUse("primitives",[["Microsoft.Extensions.Primitives","9.0.0"]],[["Microsoft.Extensions.Primitives.dll",["Microsoft.Extensions.Primitives"]]])
pkgImport("primitives","Microsoft.Extensions.Primitives.dll","Microsoft.Extensions.Primitives")

oValues = dnNew("Microsoft.Extensions.Primitives.StringValues",[["a","b","c"]])
dnAssert("a count",oValues.Count,3)
dnAssert("an item",oValues.Item(1),"b")
dnAssert("joined",oValues.ToString(),"a,b,c")

oOne = dnNew("Microsoft.Extensions.Primitives.StringValues",["only"])
dnAssert("one text",oOne.Count,1)
dnAssert("and its text",oOne.ToString(),"only")

oSegment = dnNew("Microsoft.Extensions.Primitives.StringSegment",["Ring and .NET",5,3])
dnAssert("a segment's value",oSegment.Value,"and")
dnAssert("a segment's length",oSegment.Length,3)
dnAssert("a segment starts with",oSegment.StartsWith("an",dnStatic("System.StringComparison","Ordinal",[])),1)

oTokens = dnNew("Microsoft.Extensions.Primitives.StringTokenizer",["a,b,,c",[","]])
aParts = oTokens.toList()
dnAssert("the tokens",len(aParts),4)

dnTestSummary()
