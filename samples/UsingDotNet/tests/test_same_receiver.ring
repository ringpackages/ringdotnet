# A method that answers the object it was called on (StringBuilder.Append, every fluent method) gives back the wrapper that Ring has: no new wrapper and no new handle. An
# answer that is another object is wrapped as before.
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
dnLoad(cLib)
dnImportFrom(cOut + "/","MyCompany.Tools")
dnImport("System.Text")

# a chain, with the same results as before
oFluent = new FluentChain()
oFluent.Add(1).Add(2).Add(3)
dnAssert("a chain of methods that answer the same object",oFluent.Value,6)
oBuilder = new StringBuilder("a")
oBuilder.Append("b").Append("c").Append("d")
dnAssert("a chain on a StringBuilder",oBuilder.ToString(),"abcd")
dnAssert("a chain that ends in a text",new StringBuilder("x").Append("y").Append("z").ToString(),"xyz")

# the answer is the object itself: the same handle, and a change through the answer is a change of the object
oAnswer = oFluent.Add(4)
dnAssert("the answer of a fluent method is the same .NET object (the same handle)",oAnswer.nHandle,oFluent.nHandle)
dnAssert("the answer sees the change",oAnswer.Value,10)
dnAssert("a method that answers its object as object",oFluent.AsObject().nHandle,oFluent.nHandle)
dnAssert("a method that answers its object as an interface",oFluent.AsInterface().nHandle,oFluent.nHandle)
dnAssert("an overload that answers the same object",oFluent.Over(5).nHandle,oFluent.nHandle)
dnAssert("the value after that",oFluent.Value,15)

# an answer that is another object, or nothing
oCopy = oFluent.Copy()
dnAssert("a copy is another object",oCopy.nHandle != oFluent.nHandle,1)
dnAssert("it has the value of the first",oCopy.Value,15)
oCopy.Add(1)
dnAssert("a change of the copy is not a change of the first",oFluent.Value,15)
dnAssert("a method that sometimes answers the same object: the same",oFluent.Maybe(1).nHandle,oFluent.nHandle)
oOther = oFluent.Maybe(0)
dnAssert("and sometimes another",oOther.nHandle != oFluent.nHandle,1)
dnAssert("the other has its own value",oOther.Value,115)
dnAssert("an overload that answers a new object",oFluent.Over("abc").Value,3)
dnAssert("a method that answers nothing is the null object",dnIsNull(oFluent.Nothing()),1)
dnAssert("a static method gives a wrapper",new FluentChain().Make(7).Value,7)

# a copy of the Ring object (an assignment) is the same .NET object
oAlias = oFluent
oAlias.Add(1)
dnAssert("an assignment makes a copy of the wrapper that shares the .NET object",oFluent.Value,16)

# the handles: a loop of fluent calls makes no handles
nBefore = settle()
for i = 1 to 2000
	oFluent.Add(1).Add(1)
next
dnAssert("fluent calls in a loop make no handles",settle() - nBefore < 5,1)
dnAssert("and the object has all the changes",oFluent.Value,4016)
# a loop that makes new objects still releases them
nBefore = settle()
for i = 1 to 2000
	oFluent.Copy()
next
dnAssert("copies in a loop are released",settle() - nBefore < 60,1)

# an object that is released while a copy of the wrapper is alive stays valid
oKeep = new FluentChain()
oKeep.Add(1)
oSecond = oKeep.Add(2)
oKeep = ""
dnAssert("the wrapper that was kept still works after the first one was dropped",oSecond.Add(3).Value,6)
dnTestSummary()

func settle

	return dnHandleCount()
