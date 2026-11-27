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

# a generic method whose type argument only the result shows: the type arguments are given by name
dnAssert("generic method, an Int32",oCalc.callGeneric("Parse",["System.Int32"],["42"]) + 1,43)
dnAssert("generic method, a Double",oCalc.callGeneric("Parse",["System.Double"],["2.5"]),2.5)
oBuilder = oCalc.callGeneric("Create",["System.Text.StringBuilder"],[])
dnAssert("generic method, a new object",oBuilder.typeName(),"System.Text.StringBuilder")
dnAssert("generic method on a type",dnType("MyCompany.Tools.Calculator").callGeneric("Parse",["System.Int32"],["7"]),7)
dnAssert("generic method, named arguments",dnRequest("callnamed",[oCalc,"Parse",[ [:typeArguments,["System.Int32"]], [:text,"9"] ]]),9)
# a closed generic type with no class of its own is wrapped by the class of its definition
oCounts = oCalc.Counts()
dnAssert("generic type, class of the definition",classname(oCounts),"dictionary")
dnAssert("generic type, a property",oCounts.Count,2)
dnAssert("generic type, a method",oCounts.ContainsKey("b"),1)
dnAssert("generic type, a method with a missing key",oCounts.ContainsKey("z"),0)
dnAssert("another generic type",oCalc.Sorted().Count,2)
oNumbers = new HashSet([ :typeArguments = ["System.Int32"] ])
oNumbers.Add(4)
oNumbers.Add(4)
dnAssert("new with type arguments",oNumbers.Count,1)
oNumbers2 = new SortedSet([ :typeArguments = ["System.String"] ])
oNumbers2.Add("b")
oNumbers2.Add("a")
dnAssert("a sorted set of texts",oNumbers2.Min,"a")
try
	new HashSet([ :capacity = 3 ])
	dnAssert("a generic class needs its type arguments",1,0)
catch
	dnAssert("a generic class needs its type arguments",substr(cCatchError,"typeArguments") > 0,1)
done

# a nested type has a class named after the types around it
oMemory = oCalc.Remember()
dnAssert("nested type, class",classname(oMemory),"calculatormemory")
dnAssert("nested type, a method",oMemory.Label(),"stored 30")
oMemory2 = new CalculatorMemory()
oMemory2.Stored = 2
dnAssert("nested type, new",oMemory2.Stored,2)

# a .NET method called Init is @Init (init is the constructor of a generated class)
dnAssert("a method called Init",oCalc.@Init("fast"),"init fast")

# the operators < > of an object that only has IComparable<T>.CompareTo
oLow = new Rank(1)
oHigh = new Rank(5)
bLess = oLow < oHigh
dnAssert("a smaller rank with IComparable<T>",bLess,1)
bMore = oLow > oHigh
dnAssert("not a greater rank",bMore,0)

# reflection: the arguments of MethodInfo.Invoke are an object[] of doubles, converted to the types of the method that is invoked
oSquare = dnStatic("System.Type","GetType",["MyCompany.Tools.Calculator, UserLib"]).callMethod("GetMethod",["Square"])
dnAssert("MethodInfo.Invoke with an int parameter",oSquare.callMethod("Invoke",[dnNull(),[7]]),49)

# a params array: a plain list, a single value (see below), or left out (it is empty)
dnAssert("a params array is a list",dnStatic("MyCompany.Tools.Calculator","Join",["-",["a","b","c"]]),"a-b-c")
dnAssert("a params array that is left out is empty",dnStatic("MyCompany.Tools.Calculator","Join",["-"]),"")

# an indexer with several indexes takes them as a list; the one with a single index keeps its plain form
oGrid = new Grid()
oGrid.SetItem([1,2],4.5)
dnAssert("indexer with two indexes",oGrid.Item([1,2]),4.5)
dnAssert("indexer with two indexes, another cell",oGrid.Item([0,0]),0)
dnAssert("indexer with three indexes (a read-only one)",oGrid.Item(["a","b","c"]),"abc")
oGrid.SetItem(1,"z")
dnAssert("indexer with one index next to the others",oGrid.Item(1),"z")
dnAssert("indexer with several indexes and no other",new Table2().Item([3,4]),34)
try
	new Table2().Item(5)
	dnAssert("a plain index for a multi-index only type",1,0)
catch
	dnAssert("a plain index for a multi-index only type",substr(cCatchError,"as a list") > 0,1)
done

# a generic type that no simple type closes has a class too
oFluent = new Fluent([ :typeArguments = ["MyCompany.Tools.FluentText"] ])
oFluent.Hit()
oFluent.Hit()
dnAssert("open generic definition, a method",oFluent.Hits,2)
dnAssert("open generic definition, a call chain",oFluent.Hit().Hit().Hits,4)

# the generated method takes the type arguments in the named form
dnAssert("generated method, type arguments",oCalc.Parse([ :typeArguments = ["System.Int32"], :text = "12" ]),12)
dnAssert("generated method, no arguments",oCalc.Create([ :typeArguments = ["System.Text.StringBuilder"] ]).typeName(),"System.Text.StringBuilder")
try
	oCalc.callGeneric("Parse",["System.Int32","System.Int32"],["1"])
	dnAssert("two type arguments for one",1,0)
catch
	dnAssert("two type arguments for one",substr(cCatchError,"No public generic method") > 0,1)
done

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
dnAssert("a non-public class is wrapped as the interface named after it (and the interfaces that it implements)",parentclassname(oBox),"ibox")
dnAssert("a member of the interface itself",oBox.Side,3)
dnAssert("a method inherited from another interface",oBox.Area(),9)
dnAssert("a property inherited from another interface",oBox.Name,"box")
oBox.Name = "big"
dnAssert("an inherited property can be set",oBox.Name,"big")

# an extension method of an interface is a method of the classes that implement it and of the interfaces that inherit it
dnAssert("a class gets the extension methods of its interface",new Circle().Label("a "),"a circle")
dnAssert("an interface gets the extension methods of the interface it inherits",oBox.Label("a "),"a big")

# a class that is not public and is two interfaces at once (neither is named after it): the wrapper has the members of both, with their properties
# and the extension methods of each
oChannel = new Channels().NewChannel()
oChannel.Write("ab")          # a method of the interface that was asked for
dnAssert("a method of the other interface",oChannel.Read(),"ab")
dnAssert("a property of the other interface",oChannel.Position,2)
dnAssert("a property of the first interface",oChannel.Name,"channel")
oChannel.Name = "changed"
dnAssert("a property of the first interface can be set",oChannel.Name,"changed")
dnAssert("an extension method of the other interface",oChannel.Shout(),"AB!")
dnAssert("an extension method of the first interface, and it answers the same object",oChannel.Tag("x").Read(),"ab[x]")
dnAssert("a chain of calls goes on",oChannel.Tag("y").Tag("z").Shout(),"AB[X][Y][Z]!")
oSource = new Channels().AsSource(oChannel)
dnAssert("the same object as the other interface",oSource.Read(),"ab[x][y][z]")
dnAssert("it has the members of both again",oSource.Name,"changed")
dnAssert("and a copy of the object keeps them",classname(oSource),classname(oChannel))

# a base class and a derived class: overloads of one name that answer a number and an object
oBase = new ParserBase()
dnAssert("the base class: a number answer",oBase.Read(21),42)
dnAssert("the base class: a property that answers a number",oBase.Size,7)
oDerived = new ParserDerived()
dnAssert("the derived class: the inherited overload answers a number",oDerived.Read(21),42)
oBox = oDerived.Read("text")
dnAssert("the derived class: the overload that answers an object",oBox.Text,"text")
dnAssert("the derived class: an inherited property",oDerived.Size,7)
dnAssert("the derived class: a text answer",oDerived.Describe(1),"positive")
dnAssert("the derived class: a null text is the null object",dnIsNull(oDerived.Describe(0)),true)

# a class with two indexers: the generated Item method is made from the first indexer that .NET lists (position of a box: a number), and the call with
# a number answers an object
oBoxes = new BoxList()
dnAssert("an indexer: the count",oBoxes.Count,2)
oSecond = oBoxes.Item(1)
dnAssert("an indexer that answers an object, with another indexer that answers a number",oSecond.Text,"second")

# a class that is not public derives from a public one and adds an overload: wrapped as the public class
oPlain = new Parsers().NewPlain()
dnAssert("a hidden subclass is wrapped as the public class",classname(oPlain),"plainbase")
dnAssert("a hidden subclass: the overload that the public class has",oPlain.Measure(4),5)
oMeasured = oPlain.Measure("x")
dnAssert("a hidden subclass: an overload that only the real class has",oMeasured.Text,"measured x")

oCounter = new Counter()
oCounter.Increment()
oCounter.Increment()
oCounter.Add(2)
dnAssert("derived class property",oCounter.Count,2)
dnAssert("inherited method",oCounter.Total,2)
dnAssert("objects come back as the derived class",classname(oCalc.Add(0)),"calculator")

# an extension method that takes its struct by reference (this in S): found on the object, and the answer is the value
oMoney = new Money().@New(1234)
dnAssert("an extension of a struct taken by reference",oMoney.Show("$"),"$12.34")
dnAssert("and one that returns a struct",oMoney.Doubled().Cents,2468)

# one object for a params array of an interface type is an array of one item
dnAssert("a single object for a params array",dnStatic("MyCompany.Tools.ParamsTools","CountShapes",["x",new Circle()]),1)
dnAssert("a list for a params array",dnStatic("MyCompany.Tools.ParamsTools","CountShapes",["x",[new Circle(),new Circle()]]),2)
dnAssert("no objects for a params array",dnStatic("MyCompany.Tools.ParamsTools","CountShapes",["x"]),0)

# a delegate type with extension methods has a class: the methods are called on the object
oIncrement = dnStatic("MyCompany.Tools.DelegateFactory","Increment",[])
dnAssert("a delegate object is called",oIncrement.Invoke(5),6)
dnAssert("an extension method of a delegate",oIncrement.Twice().Invoke(5),7)
dnAssert("a chain of them",oIncrement.Twice().Plus(10).Invoke(0),12)
oExclaim = dnStatic("MyCompany.Tools.DelegateFactory","Exclaim",[])
dnAssert("a generic delegate",oExclaim.Repeat(3).Invoke("hi"),"hi!!!")

# an extension method of a closed generic type with a type parameter of its own (IStage<IStageMarker>.Append<TNext>): the implementing classes have it
oChain = new StageOne().Append(new StageTwo())
dnAssert("an extension method on a closed generic interface",oChain.Name,"one>two")
dnAssert("its result is wrapped by its real type",classname(oChain),"stagechain")
dnAssert("and it is chained",oChain.Append(new StageTwo()).Name,"one>two>two")

# dnIsNull: true for the .NET null, false for every other value
dnAssert("a method that returns null",dnIsNull(dnStatic("MyCompany.Tools.ParamsTools","NoShape",[])),1)
dnAssert("the null of dnNull",dnIsNull(dnNull()),1)
dnAssert("an object that is not null",dnIsNull(new Circle()),0)
dnAssert("a number",dnIsNull(5),0)
dnAssert("a text",dnIsNull("x"),0)
dnAssert("a list",dnIsNull([1,2]),0)

nFail = dnTestSummary()
