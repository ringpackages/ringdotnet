# ICSharpCode.Decompiler: C# source text from the metadata of an assembly file (UserLib.dll): a type name in, source code out
load "pkg.ring"
pkgUse("decompiler",[["ICSharpCode.Decompiler","9.1.0.7988"]],[["ICSharpCode.Decompiler.dll",["ICSharpCode.Decompiler","ICSharpCode.Decompiler.CSharp","ICSharpCode.Decompiler.TypeSystem"]]])
pkgImport("decompiler","ICSharpCode.Decompiler.dll","ICSharpCode.Decompiler")
pkgImport("decompiler","ICSharpCode.Decompiler.dll","ICSharpCode.Decompiler.CSharp")
pkgImport("decompiler","ICSharpCode.Decompiler.dll","ICSharpCode.Decompiler.TypeSystem")

cLib = cPkgHere + "/../UserLib/bin/UserLib.dll"
oSettings = new DecompilerSettings()
oDecompiler = dnNew("ICSharpCode.Decompiler.CSharp.CSharpDecompiler",[cLib,oSettings])

oName = dnNew("ICSharpCode.Decompiler.TypeSystem.FullTypeName",["MyCompany.Tools.Circle"])
cCode = oDecompiler.DecompileTypeAsString(oName)
dnAssert("the class is in the source",substr(cCode,"class Circle") > 0,1)
dnAssert("it implements the interface",substr(cCode,"IShape") > 0,1)
dnAssert("the namespace is there",substr(cCode,"namespace MyCompany.Tools") > 0,1)

oDelegate = dnNew("ICSharpCode.Decompiler.TypeSystem.FullTypeName",["MyCompany.Tools.Transform"])
dnAssert("a delegate type",substr(oDecompiler.DecompileTypeAsString(oDelegate),"delegate int Transform") > 0,1)

oMoney = dnNew("ICSharpCode.Decompiler.TypeSystem.FullTypeName",["MyCompany.Tools.Money"])
cMoney = oDecompiler.DecompileTypeAsString(oMoney)
dnAssert("a struct",substr(cMoney,"struct Money") > 0,1)
dnAssert("a property of it",substr(cMoney,"Cents") > 0,1)

dnTestSummary()
