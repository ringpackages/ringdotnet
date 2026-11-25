# Typed static calls: a static method of numbers, yes/nos and texts is called by dotnet_callts (the type name, the method name, the arguments), without a
# request text. Every answer and every error must be the one of the generic request (dnStatic), also for what stays with it: overloads that can take the
# arguments, optional parameters, params, generic methods, out, an enum, a char, a nullable, an object, a method that throws.
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
using {
	"System"
	"System.IO"
}

cType = "MyCompany.Tools.TypedStatic"
nMismatch = 0
nChecked = 0

# ---- values
oS = new TypedStatic()
dnAssert("two numbers",oS.Add(2,3),5)
dnAssert("three numbers",oS.Sum3(1,2,3),6)
dnAssert("four numbers",oS.Mix4(2,3,4,1),9)
dnAssert("a text, a number, a yes/no and a text",oS.Join4("x",5,1,"y"),"x5Ty")
dnAssert("a yes/no",oS.Between(5,1,10),1)
dnAssert("a yes/no that is false",oS.Between(50,1,10),0)
oS.Set2(7,"z")
dnAssert("a method that answers nothing",oS.GetLast(),"7z")
dnAssert("a long",oS.Big(5000000000),10000000000)
dnAssert("a byte",oS.ByteIn(255),256)
dnAssert("an sbyte",oS.SByteIn(-128),-127)
dnAssert("a uint",oS.UIntIn(4294967295),4294967296)
dnAssert("a float",oS.FloatIn(1.5),3)
dnAssert("a decimal",oS.DecimalIn(1.5),2.5)
dnAssert("a text",oS.Echo("héllo ✓"),"héllo ✓")
dnAssert("a text answer that is null",dnIsNull(oS.TextOrNull("")),1)
dnAssert("a text answer",oS.TextOrNull("a"),"a!")
dnAssert("a char",oS.LetterOf("xyz"),"x")
dnAssert("an enum",oS.Paint("Blue"),"Blue")
dnAssert("a nullable",oS.Maybe(4),4)
dnAssert("a number for an enum parameter",oS.OnlyColor(2),"color Blue")
dnAssert("a number keeps choosing the overload of a text over the one of an enum",oS.Choose(1),"text 1")
dnAssert("a text goes to the overload of a text",oS.Choose("Green"),"text Green")
dnAssert("an optional parameter",oS.Opt(2),205)
dnAssert("overloads of one arity: a number",oS.Over(1),2)
dnAssert("overloads of one arity: a text",oS.Over("a"),"a?")
dnAssert("overloads of different arities",oS.Scale([ :a = 3, :b = 4 ]),12)
dnAssert("an object answer",oS.Box(8).IntValue,8)
dnAssert("a call that throws",substr(tryStatic(cType,"Throws",[5],true),"typed static error 5") > 0,1)
oMath = new Math()
oPath = new Path()
dnAssert("the framework: Math.Sqrt",oMath.Sqrt(16),4)
dnAssert("the framework: Math.Pow",oMath.Pow(2,10),1024)
dnAssert("the framework: Math.Max",oMath.Max(3,9),9)
dnAssert("the framework: Path.GetFileName",oPath.GetFileName("a/b.txt"),"b.txt")
dnAssert("the framework: Path.GetFileNameWithoutExtension",oPath.GetFileNameWithoutExtension("a/b.txt"),"b")
dnAssert("a static method of a class that has an instance method of the name",new TypedBoth().Twice(4),8)
dnAssert("a static method inherited by a derived class",new TypedBothDerived().Inherited(4),5)

# ---- the same answers and errors as the generic request
# [name, arity]: the generated method takes that many parameters (a name with overloads of different arities takes one: a dispatcher)
aMethods = [ ["Add",2],["Sum3",3],["Mix4",4],["Join4",4],["Between",3],["Set2",2],["Big",1],["ByteIn",1],["SByteIn",1],["UIntIn",1],["FloatIn",1],["DecimalIn",1],
             ["TextOrNull",1],["Echo",1],["Throws",1],["LetterOf",1],["Paint",1],["Maybe",1],["Many",1],["Same",1],["Over",1],
             ["Box",1],["Reset",0],["GetLast",0],["OutValue",0] ]
aValues = [0,1,-1,3.5,0.1,127,128,255,256,-128,-129,32767,65536,2147483647,2147483648,4294967295,4294967296,1000000000000000,100000000000000000000,
           "","abc","12","true","Blue","blue","héllo ✓",char(255) + char(254),[1,2],[ ["a",1] ]]
aSome = [0,1,5,2.5,"a","x",-1,4294967296,[1,2]]
for aMethod in aMethods
	cName = aMethod[1]
	switch aMethod[2]
	on 0
		compareStatic(cType,cName,[])
	on 1
		for xA in aValues
			compareStatic(cType,cName,[xA])
		next
	on 2
		for xA in aSome
			for xB in aSome
				compareStatic(cType,cName,[xA,xB])
			next
		next
	on 3
		for xA in aSome
			for xB in aSome
				compareStatic(cType,cName,[xA,xB,xA])
				compareStatic(cType,cName,[xA,xB,xB])
			next
		next
	on 4
		for xA in aSome
			for xB in aSome
				compareStatic(cType,cName,[xA,xB,xA,xB])
				compareStatic(cType,cName,[xA,xB,xB,xA])
			next
		next
	off
next
dnAssert("typed and generic static calls agree (" + nChecked + " comparisons)",nMismatch,0)

# the framework
aCases = [ ["System.Math","Sqrt",[16]], ["System.Math","Sqrt",["a"]], ["System.Math","Pow",[2,10]], ["System.Math","Max",[3,9]], ["System.Math","Max",[3.5,2]],
           ["System.Math","Abs",[-3]], ["System.IO.Path","GetFileName",["a/b.txt"]], ["System.IO.File","Exists",["nofile"]],
           ["System.String","IsNullOrEmpty",[""]], ["System.Environment","GetEnvironmentVariable",["NO_SUCH_VARIABLE_X"]], ["System.Int32","Parse",["12"]],
           ["System.Int32","Parse",["xx"]], ["System.Convert","ToInt32",["7"]], ["System.Guid","Parse",["bad"]],
           ["System.Math","Floor",[2.5]], ["System.Char","IsDigit",["5"]], ["System.Char","ToUpper",["a"]] ]
for aCase in aCases
	compareStatic(aCase[1],aCase[2],aCase[3])
next
dnAssert("typed and generic static calls agree for the framework (" + nChecked + " comparisons)",nMismatch,0)

dnTestSummary()

func compareStatic cType, cName, aArgs
	nChecked++
	cTyped = tryStatic(cType,cName,aArgs,true)
	cGeneric = tryStatic(cType,cName,aArgs,false)
	if cTyped != cGeneric
		nMismatch++
		if nMismatch < 30
			? cType + "." + cName + "(" + describeList(aArgs) + "): typed " + cTyped + " | generic " + cGeneric
		ok
	ok

# typed: the generated class (a Ring method), generic: dnStatic
func tryStatic cType, cName, aArgs, lTyped
	cResult = ""
	try
		if lTyped
			aParts = str2list(substr(cType,".",nl))
			cCall = "xResult = new " + aParts[len(aParts)] + "()." + cName + "("
			for x = 1 to len(aArgs)
				if x > 1
					cCall += ","
				ok
				cCall += "aArgs[" + x + "]"
			next
			cCall += ")"
			eval(cCall)
		else
			xResult = dnStatic(cType,cName,aArgs)
		ok
		cResult = describeResult(xResult,cName)
	catch
		cResult = "error: " + cCatchError
	done
	return cResult

# a method that answers nothing gives the object from the Ring method and the null object from dnStatic, so they are not compared
func describeResult xResult, cName
	if find(["Set2","Reset"],cName) > 0 and isobject(xResult)
		return "nothing"
	ok
	return describe(xResult)

func describeList aList
	cText = ""
	for xItem in aList
		if cText != ""
			cText += ","
		ok
		cText += describe(xItem)
	next
	return cText

func describe xValue
	if isnumber(xValue)
		return "n:" + xValue
	ok
	if isstring(xValue)
		return "s:" + xValue
	ok
	if isobject(xValue)
		if ismethod(xValue,"isNull") and xValue.isNull()
			return "null object"
		ok
		return "object " + classname(xValue)
	ok
	return "list"
