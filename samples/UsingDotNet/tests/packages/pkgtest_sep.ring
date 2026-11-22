# Sep: a CSV reader built on spans and ref structs. The reader is a class; a row is a ref struct, which Ring receives as its text.
# Also covers a method that takes its struct receiver by reference (reader options: this in SepReaderOptions).
load "pkg.ring"
pkgUse("sep",[["Sep","0.9.0"]],[["Sep.dll",["nietras.SeparatedValues"]]])
pkgImport("sep","Sep.dll","nietras.SeparatedValues")

cCsv = "name,age" + nl + "ann,30" + nl + "bob,25" + nl + '"smith, jo",41' + nl
oReader = dnStatic("nietras.SeparatedValues.Sep","New",[","]).Reader(NULL).FromText(cCsv)
aRows = []
while oReader.MoveNext()
	aRows + oReader.Current
end
dnAssert("three data rows",len(aRows),3)
dnAssert("the first row",aRows[1],"ann,30")
dnAssert("the second row",aRows[2],"bob,25")
dnAssert("a quoted field keeps its comma",aRows[3],'"smith, jo",41')

# another separator, and the header
oSemi = dnStatic("nietras.SeparatedValues.Sep","New",[";"]).Reader(NULL).FromText("a;b;c" + nl + "1;2;3" + nl)
nCount = 0
while oSemi.MoveNext()
	nCount++
	dnAssert("a row with another separator",oSemi.Current,"1;2;3")
end
dnAssert("one row",nCount,1)
dnAssert("the header",oSemi.Header.ToString(),"a;b;c")
dnAssert("the number of columns",len(oSemi.Header.ColNames.toList()),3)

# Arabic and emoji text read as it is
oText = dnStatic("nietras.SeparatedValues.Sep","New",[","]).Reader(NULL).FromText("x,y" + nl + "مرحبا,💍" + nl)
oText.MoveNext()
dnAssert("text that is not English",oText.Current,"مرحبا,💍")

dnTestSummary()
