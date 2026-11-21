# Your own assemblies: tools/dotnettools/wrapassembly.ring generates the classes, dnImportFrom() loads them
load "dotnet.ring"

cHere = currentdir()
cLib = cHere + "/UserLib/bin/UserLib.dll"
if not fexists(cLib)
	system("dotnet build UserLib -c Release -o UserLib/bin -nologo -v q")
ok
cOut = cHere + "/UserLib/generated"
# the generator loads its files relative to the folder it runs from
chdir("../../../tools/dotnettools")
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
dnAssert("constructor with parameters",new Calculator().@New([ :start = 5 ]).Total,5)
dnAssert("static method",new Calculator().Square(7),49)
dnAssert("enum as string and optional parameter",oCalc.Describe([ :level = "High", :prefix = "Sum" ]),"Sum=30 (High)")
aDivide = oCalc.TryDivide(4)
dnAssert("out parameter ok",aDivide[1],1)
dnAssert("out parameter value",aDivide[2],7.5)
dnAssert("out parameter fails",oCalc.TryDivide(0)[1],0)
dnAssert("returns generic list",len(oCalc.Words("a b c").toList()),3)
oMixed = oCalc.Mixed()
dnAssert("a method that returns a List<object> gives an object, like any other collection",classname(oMixed),"objectlist")
dnAssert("and its items are there",oMixed.Count,3)
dnAssert("an item of it",oMixed.Item(1),"two")

nEvents = 0
oCalc.setChangedEvent("nEvents++")
oCalc.Add(1)
dnAssert("user event",nEvents,1)

# extension methods are methods of the class of the type that they extend
dnAssert("an extension method",oCalc.Shout("!"),"MINE!")
dnAssert("an extension method with the name of a method of the class",oCalc.Describe("Total is {0}"),"Total is 31")
dnAssert("the method of the class with that name still works",oCalc.Describe([ :level = "High", :prefix = "Sum" ]),"Sum=31 (High)")

# a class of the assembly with the name of a class of the library gets the prefix of its namespace, and both work in one program
dnAssert("a class named like a class of the library is renamed",new ToolsVersion().Text,"user version")
dnAssert("the class of the library has its own name",new Version("1.2.3").Major,1)

# methods that a non-public class implements explicitly are found through its public interfaces
oGetter = new Hiding().NewGetter()
dnAssert("a method of an explicit interface implementation",oGetter.Fetch("key"),"key!")
dnAssert("the same with named parameters",oGetter.Join([ :first = "a", :second = "b" ]),"a+b")

# a parameter of the type System.Enum does not say which enum it is: the text gives the full name of the member
dnAssert("a System.Enum parameter takes the full name of an enum member",new Calculator().EnumName("MyCompany.Tools.Level.High"),"Level.High")

# a class that is not public comes back as the interface named after it (IBox), and an interface has the members of the interfaces it inherits
oBox = new Shapes().NewBox(3)
dnAssert("a non-public class is wrapped as the interface named after it",classname(oBox),"ibox")
dnAssert("a member of the interface itself",oBox.Side,3)
dnAssert("a method inherited from another interface",oBox.Area(),9)
dnAssert("a property inherited from another interface",oBox.Name,"box")
oBox.Name = "big"
dnAssert("an inherited property can be set",oBox.Name,"big")

# an extension method of an interface is a method of the classes that implement it and of the interfaces that inherit it
dnAssert("a class gets the extension methods of its interface",new Circle().Label("a "),"a circle")
dnAssert("an interface gets the extension methods of the interface it inherits",oBox.Label("a "),"a big")

oCounter = new Counter()
oCounter.Increment()
oCounter.Increment()
oCounter.Add(2)
dnAssert("derived class property",oCounter.Count,2)
dnAssert("inherited method",oCounter.Total,2)
dnAssert("objects come back as the derived class",classname(oCalc.Add(0)),"calculator")

nFail = dnTestSummary()
