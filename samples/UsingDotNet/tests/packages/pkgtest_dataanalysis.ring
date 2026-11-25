# Microsoft.Data.Analysis: a DataFrame of typed columns (generic columns of ints, doubles and texts), rows filled by index, columns computed from others
load "pkg.ring"
pkgUse("dataanalysis",[["Microsoft.Data.Analysis","0.24.0"]],[["Microsoft.Data.Analysis.dll",["Microsoft.Data.Analysis"]]])
pkgImport("dataanalysis","Microsoft.Data.Analysis.dll","Microsoft.Data.Analysis")
using { "System.IO" }

oAges = dnNew("Microsoft.Data.Analysis.PrimitiveDataFrameColumn`1[[System.Int32]]",["Age"])
oAges.Append(31)
oAges.Append(25)
oAges.Append(40)
dnAssert("the name of a column",oAges.Name,"Age")
dnAssert("the length of a column",oAges.Length,3)
dnAssert("a value of a column",oAges.Item(1),25)

oNames = dnNew("Microsoft.Data.Analysis.StringDataFrameColumn",["Name"])
oNames.Append("Ann")
oNames.Append("Bob")
oNames.Append("Cy")
oFrame = dnNew("Microsoft.Data.Analysis.DataFrame",[[oNames,oAges]])
dnAssert("the rows of the frame",oFrame.Rows.Count,3)
dnAssert("the columns of the frame",oFrame.Columns.Count,2)
oAgeColumn = oFrame.Columns.Item("Age")
dnAssert("a column found by its name",oAgeColumn.Length,3)
dnAssert("a text in a column",oFrame.Columns.Item("Name").Item(2),"Cy")
oRow = oFrame.Rows.Item(1)
dnAssert("a cell of a row by its column index",oRow.Item(0),"Bob")

# column arithmetic: the answers are new columns
dnAssert("the sum of a column",oAgeColumn.Sum(NULL),96)
dnAssert("the largest value",oAgeColumn.Max(NULL),40)
dnAssert("the smallest value",oAgeColumn.Min(NULL),25)
oPlus = oAgeColumn.Add(10)
dnAssert("a column plus a number",oPlus.Item(0),41)
dnAssert("the original column is unchanged",oAgeColumn.Item(0),31)
oBig = oAgeColumn.ElementwiseGreaterThan(30)
dnAssert("a comparison gives a column of yes/nos",oBig.Item(0),1)
dnAssert("a comparison that is false",oBig.Item(1),0)

# rows chosen by a condition, sorted, and the first rows
oOlder = oFrame.Filter(oBig)
dnAssert("the rows that pass the condition",oOlder.Rows.Count,2)
dnAssert("the first of them",oOlder.Columns.Item("Name").Item(0),"Ann")
oSorted = oFrame.OrderBy("Age")
dnAssert("the youngest comes first when sorted",oSorted.Columns.Item("Name").Item(0),"Bob")
dnAssert("the oldest comes last",oSorted.Columns.Item("Name").Item(2),"Cy")
dnAssert("the first rows",oFrame.Head(2).Rows.Count,2)

# a column that is added to the frame, computed from another one
oDouble = oAgeColumn.Multiply(2)
oDouble.setName("Double")
oFrame.Columns.Add(oDouble)
dnAssert("a column was added",oFrame.Columns.Count,3)
dnAssert("its values",oFrame.Columns.Item("Double").Item(2),80)

# a value that is not there is null
oAges.Append(dnNull())
dnAssert("a null in a column",dnIsNull(oAges.Item(3)),1)
dnAssert("the null is counted",oAges.NullCount,1)

# a CSV text read into a frame
cCsv = "city,visits" + nl + "Cairo,12" + nl + "Lima,7" + nl + "Oslo,30" + nl
oStream = new MemoryStream().@New([ :buffer = dnBuffer(cCsv) ])
oCsv = dnStatic("Microsoft.Data.Analysis.DataFrame","LoadCsv",[oStream])
dnAssert("the rows of the CSV",oCsv.Rows.Count,3)
dnAssert("the names of the columns",oCsv.Columns.Item("visits").Name,"visits")
dnAssert("a number column was found",oCsv.Columns.Item("visits").Sum(NULL),49)
dnAssert("a text column was found",oCsv.Columns.Item("city").Item(1),"Lima")

dnTestSummary()
