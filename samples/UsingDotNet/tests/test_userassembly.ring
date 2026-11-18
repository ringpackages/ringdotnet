# Your own assemblies: tools/wrapassembly.ring generates the classes, dnImportFrom() loads them
load "dotnet.ring"

cHere = currentdir()
cLib = cHere + "/UserLib/bin/UserLib.dll"
if not fexists(cLib)
	system("dotnet build UserLib -c Release -o UserLib/bin -nologo -v q")
ok
cOut = cHere + "/UserLib/generated"
# the generator loads its files relative to the folder it runs from
chdir("../../../tools")
system(exefilename() + " wrapassembly.ring " + cLib + " " + cOut + " > nul")
chdir(cHere)
dnAssert("generated loader exists",fexists(cOut + "/MyCompany.Tools.ring"),1)

dnLoad(cLib)
dnImportFrom(cOut + "/","MyCompany.Tools")

oCalc = new Calculator()
oCalc.Add(10).Multiply(3)
dnAssert("fluent calls return the class",oCalc.Total,30)
dnAssert("property read/write",oCalc.Name,"calc")
oCalc.Name = "mine"
dnAssert("property write",oCalc.Name,"mine")
dnAssert("constructor with parameters",new Calculator().New_1(5).Total,5)
dnAssert("static method",new Calculator().Square(7),49)
dnAssert("enum as string and optional parameter",oCalc.Describe_2("High","Sum"),"Sum=30 (High)")
aDivide = oCalc.TryDivide(4)
dnAssert("out parameter ok",aDivide[1],1)
dnAssert("out parameter value",aDivide[2],7.5)
dnAssert("out parameter fails",oCalc.TryDivide(0)[1],0)
dnAssert("returns generic list",len(oCalc.Words("a b c").toList()),3)

nEvents = 0
oCalc.setChangedEvent("nEvents++")
oCalc.Add(1)
dnAssert("user event",nEvents,1)

oCounter = new Counter()
oCounter.Increment()
oCounter.Increment()
oCounter.Add(2)
dnAssert("derived class property",oCounter.Count,2)
dnAssert("inherited method",oCounter.Total,2)
dnAssert("objects come back as the derived class",classname(oCalc.Add(0)),"calculator")

nFail = dnTestSummary()
