# MiniExcel: write rows (dictionaries) to an xlsx, read them back as rows of dictionaries (dynamic rows)
load "pkg.ring"
pkgUse("miniexcel",[["MiniExcel","1.41.3"]],[["MiniExcel.dll",["MiniExcelLibs"]]])
pkgImport("miniexcel","MiniExcel.dll","MiniExcelLibs")
dnImport("System.Collections.Generic")

cFile = cPkgCache + "miniexcel/test.xlsx"
pkgRemoveFile(cFile)

oRows = dnNew("System.Collections.Generic.List`1[[System.Collections.Generic.Dictionary`2[[System.String],[System.Object]]]]",[])
for i = 1 to 3
	oRow = dnNew("System.Collections.Generic.Dictionary`2[[System.String],[System.Object]]",[])
	oRow.SetItem("Name","user" + i)
	oRow.SetItem("Score",i * 10)
	oRows.Add(oRow)
next
dnAssert("three rows to write",oRows.Count,3)

oSaved = dnStatic("MiniExcelLibs.MiniExcel","SaveAs",[cFile,oRows])
dnAssert("the file is written",fexists(cFile),1)

aBack = dnRequest("callnamed",[dnType("MiniExcelLibs.MiniExcel"),"Query",[ ["path",cFile], ["useHeaderRow",1] ]]).toList()
dnAssert("three rows read",len(aBack),3)
dnAssert("a text cell",aBack[1].Item("Name"),"user1")
dnAssert("a number cell",aBack[2].Item("Score"),20)
dnAssert("the last row",aBack[3].Item("Name"),"user3")

dnTestSummary()

func pkgRemoveFile cPath
	if fexists(cPath)
		remove(cPath)
	ok
