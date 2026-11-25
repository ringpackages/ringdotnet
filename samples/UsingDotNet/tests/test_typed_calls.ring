# Typed method calls: a method with parameters of numbers, yes/nos and texts and an answer of a number, a yes/no, a text or nothing is called by the extension
# without a request text (dotnet_callt, dotnet_calltv; dotnet_calltd for a name with overloads that takes no argument or one). Every result and every error must
# be the one of the generic request (callMethod), also for the methods that the typed path leaves to it: overloads, optional parameters, params, generic
# methods, out and ref, an enum, a char, a nullable, an object, a static method, a method that throws.
load "dotnet.ring"

using {
	"System"
	"System.Collections.Generic"
	"System.Text"
}

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

# ---- values
oMath = new TypedMath()
dnAssert("two numbers",oMath.Add(2,3),5)
dnAssert("three numbers",oMath.Sum3(1,2,3),6)
dnAssert("four numbers",oMath.Mix4(2,3,4,1),9)
dnAssert("a text, a number, a yes/no and a text",oMath.Join4("x",5,1,"y"),"x5Ty")
dnAssert("a yes/no answer",oMath.Between(5,1,10),1)
dnAssert("a yes/no answer that is false",oMath.Between(50,1,10),0)
oMath.Set2(7,"z")
dnAssert("a method that answers nothing",oMath.Last,"7z")
dnAssert("a long",oMath.Big(5000000000),10000000000)
dnAssert("a byte",oMath.ByteIn(255),256)
dnAssert("an sbyte",oMath.SByteIn(-128),-127)
dnAssert("a short",oMath.ShortIn(32767),32768)
dnAssert("a ushort",oMath.UShortIn(65535),65536)
dnAssert("a uint",oMath.UIntIn(4294967295),4294967296)
dnAssert("a float",oMath.FloatIn(1.5),3)
dnAssert("a decimal",oMath.DecimalIn(1.5),2.5)
dnAssert("a text",oMath.Echo("héllo ✓"),"héllo ✓")
dnAssert("a text answer that is null",dnIsNull(oMath.TextOrNull("")),1)
dnAssert("a text answer",oMath.TextOrNull("a"),"a!")
dnAssert("a char answer",oMath.LetterOf("xyz"),"x")
dnAssert("an enum",oMath.Paint("Blue"),"Blue")
dnAssert("a nullable",oMath.Maybe(4),4)
dnAssert("an optional parameter",oMath.Opt(2),205)
dnAssert("a method with out",oMath.OutValue()[1],1)
oBox = oMath.Box(8)
dnAssert("an object answer",oBox.IntValue,8)
dnAssert("a static method",oMath.Square(7),49)
dnAssert("overloads of one arity: a number",oMath.Over(1),2)
dnAssert("overloads of one arity: a text",oMath.Over("a"),"a?")
dnAssert("a name with overloads: no argument",oMath.Pair(NULL),"none")
dnAssert("a name with overloads: one argument",oMath.Pair(4),"int 4")
dnAssert("a name with overloads: named",oMath.Pair([ :a = 6 ]),"int 6")
oMath.Reset(NULL)
dnAssert("a name with overloads, nothing answered: no argument",oMath.Last,"reset")
oMath.Reset(3)
dnAssert("a name with overloads, nothing answered: one argument",oMath.Last,"reset 3")
dnAssert("three overloads: no argument",oMath.Say(NULL),"hi")
dnAssert("three overloads: one argument",oMath.Say("you"),"hi you")
dnAssert("a call that throws",substr(tryCall(oMath,"Throws",[5],true),"typed call error 5") > 0,1)
dnAssert("a wrong kind of argument is the generic error",substr(tryCall(oMath,"Add",["a","b"],true),"DotNet Error") > 0,1)
dnAssert("a number that is not whole for an int",substr(tryCall(oMath,"Add",[2.5,1],true),"DotNet Error") > 0,1)
dnAssert("a number out of range for a byte",substr(tryCall(oMath,"ByteIn",[256],true),"DotNet Error") > 0,1)
oDerived = new TypedMathDerived()
dnAssert("a derived class that hides a method",oDerived.Add(1,2),1003)
dnAssert("a derived class: an inherited method",oDerived.Sum3(1,2,3),6)
dnAssert("a derived class: the added overload",oDerived.Add("a","b"),"ab")
oList = new StringList()
oList.Add("a")
oList.Add("b")
dnAssert("a framework method: a yes/no",oList.Contains("b"),1)
dnAssert("a framework method: a number",oList.IndexOf("b"),1)
oList.Insert(0,"z")
dnAssert("a framework method: two arguments, nothing answered",oList.Item(0),"z")
oList.RemoveAt(0)
dnAssert("a framework method: one number, nothing answered",oList.Count,2)

# ---- the same results and errors as the generic request
# [name, the arguments that are valid, the number of the arguments to vary]
aMethods = [
	["Add",[2,3]], ["Sum3",[1,2,3]], ["Mix4",[2,3,4,1]], ["Join4",["x",5,1,"y"]], ["Between",[5,1,10]], ["Set2",[7,"z"]], ["Big",[5]], ["ByteIn",[5]],
	["SByteIn",[5]], ["ShortIn",[5]], ["UShortIn",[5]], ["UIntIn",[5]], ["ULongIn",[5]], ["FloatIn",[1.5]], ["DecimalIn",[1.5]], ["TextOrNull",["a"]],
	["Echo",["a"]], ["Length",["abc"]], ["Throws",[5]], ["IsFive",[5]], ["LetterOf",["a"]], ["NextLetter",["a"]], ["Paint",["Red"]], ["Maybe",[4]],
	["Over",[1]], ["Box",[3]], ["OutValue",[]], ["RefValue",[1]]
]
aValues = [0,1,-1,2.5,127,128,255,256,-129,32767,32768,65535,65536,2147483647,2147483648,4294967295,4294967296,1000000000000000,
           "","abc","12","true",char(195) + char(169),char(255) + char(254),[1,2],[ ["a",1] ]]
nChecked = 0
nMismatch = 0
for aMethod in aMethods
	cName = aMethod[1]
	aValid = aMethod[2]
	# the valid arguments
	nChecked += compareCall(cName,aValid)
	# one argument at a time replaced by every value
	for nPos = 1 to len(aValid)
		for xValue in aValues
			aArgs = aValid
			aArgs[nPos] = xValue
			nChecked += compareCall(cName,aArgs)
		next
	next
next
dnAssert("typed and generic calls agree (" + nChecked + " comparisons)",nMismatch,0)

# the names with overloads that take no argument or one (and several): NULL, a value, a list of named arguments
# (a name that has an overload without parameters reads an empty text as no argument; Scale and Opt have none, so it is their one argument)
aDispatch = [ ["Pair",true], ["Reset",true], ["Count",true], ["Say",true], ["Scale",false], ["Opt",false] ]
nChecked = 0
for aDispatchName in aDispatch
	cName = aDispatchName[1]
	lNoArgument = aDispatchName[2]
	for xValue in aValues
		if not (islist(xValue) and len(xValue) > 0 and islist(xValue[1]))
			nChecked += compareDispatch(cName,xValue,lNoArgument)
		ok
	next
	nChecked += compareDispatch(cName,NULL,lNoArgument)
next
dnAssert("names with overloads agree (" + nChecked + " comparisons)",nMismatch,0)

# the derived class and a framework class
for xValue in aValues
	# (a list of [text, value] pairs alone is read as named arguments by a method with overloads: not compared here)
	if islist(xValue) and len(xValue) > 0 and islist(xValue[1])
		loop
	ok
	nCall = compareOn(new TypedMathDerived(),"Add",[xValue,2])
	nCall = compareOn(new TypedMathDerived(),"Add",[2,xValue])
	nCall = compareOn(new TypedMathDerived(),"Sum3",[xValue,2,3])
	nCall = compareOn(freshLike(new StringList()),"Contains",[xValue])
	nCall = compareOn(freshLike(new StringList()),"IndexOf",[xValue])
	nCall = compareOn(freshLike(new StringList()),"Insert",[0,xValue])
	nCall = compareOn(freshLike(new StringList()),"RemoveAt",[xValue])
next
dnAssert("a derived class and a framework class agree",nMismatch,0)

# the null object and a handle that is not valid
oNullMath = new TypedMath()
oNullMath.nHandle = 0
dnAssert("the null object raises the generic error",tryCall(oNullMath,"Add",[1,2],true),tryCall(oNullMath,"Add",[1,2],false))
oGone = new TypedMath()
oGone.nHandle = 999999
dnAssert("a handle that is not valid raises the generic error",tryCall(oGone,"Add",[1,2],true),tryCall(oGone,"Add",[1,2],false))

# ---- indexers: Item and SetItem of a list, a dictionary, a class with an indexer of numbers and a class with two indexers
nChecked = 0
aIndexValues = [0,1,2,-1,2.5,99,"","abc","one",[1,2]]
for xIndex in aIndexValues
	nChecked += compareItem("list",xIndex)
	nChecked += compareItem("numbers",xIndex)
	nChecked += compareItem("dictionary",xIndex)
	nChecked += compareItem("box",xIndex)
	nChecked += compareItem("indexed",xIndex)
next
dnAssert("Item and SetItem agree with the generic request (" + nChecked + " comparisons)",nMismatch,0)
oIndexed = new TypedIndexed()
dnAssert("two indexers: the one of a number",oIndexed.Item(1),"one")
dnAssert("two indexers: the one of a text",oIndexed.Item("abcd"),4)

dnTestSummary()

# an object of a kind: the list of three texts, the list of numbers, a dictionary of texts, a box whose indexer answers a number, a class with two indexers
func freshItems cKind

	switch cKind
	on "list"
		oNew = new StringList()
		oNew.Add("a")
		oNew.Add("b")
		oNew.Add("c")
		return oNew
	on "numbers"
		oNew = new NumberList()
		oNew.Add(10)
		oNew.Add(20)
		oNew.Add(30)
		return oNew
	on "dictionary"
		oNew = new StringDictionary()
		oNew.Add("a","alpha")
		oNew.Add("one","uno")
		return oNew
	on "box"
		return new TypedBox()
	off
	return new TypedIndexed()

# reads the item with Item (typed) and with callMethod("get_Item") (generic), then writes a value with SetItem and with callMethod("set_Item"), and compares
func compareItem cKind, xIndex

	for nStep = 1 to 2
		oTyped = freshItems(cKind)
		oGeneric = freshItems(cKind)
		cTyped = ""
		cGeneric = ""
		if nStep = 1
			try
				cTyped = describe(oTyped.Item(xIndex))
			catch
				cTyped = "error: " + cCatchError
			done
			try
				cGeneric = describe(oGeneric.callMethod("get_Item",[xIndex]))
			catch
				cGeneric = "error: " + cCatchError
			done
		else
			xValue = "new"
			if cKind = "numbers" or cKind = "box"
				xValue = 77
			ok
			if cKind = "box"
				loop
			ok
			try
				oTyped.SetItem(xIndex,xValue)
				cTyped = "done " + describe(oTyped.Item(0))
			catch
				cTyped = "error: " + cCatchError
			done
			try
				oGeneric.callMethod("set_Item",[xIndex,xValue])
				cGeneric = "done " + describe(oGeneric.callMethod("get_Item",[0]))
			catch
				cGeneric = "error: " + cCatchError
			done
		ok
		if cTyped != cGeneric
			nMismatch++
			? cKind + " step " + nStep + " index " + describe(xIndex) + ": typed " + cTyped + " | generic " + cGeneric
		ok
	next
	return 2

func compareCall cName, aArgs

	return compareOn(new TypedMath(),cName,aArgs)

# calls a method of a fresh object with the Ring method (typed) and of another with callMethod (generic), and compares the answers and the errors
func compareOn oTyped, cName, aArgs

	oGeneric = oTyped
	cTyped = tryCall(oTyped,cName,aArgs,true)
	oGeneric = freshLike(oTyped)
	cGeneric = tryCall(oGeneric,cName,aArgs,false)
	if cTyped != cGeneric
		nMismatch++
		? cName + "(" + describeList(aArgs) + "): typed " + cTyped + " | generic " + cGeneric
	ok
	return 1

func freshLike oObject

	if classname(oObject) = "typedmathderived"
		return new TypedMathDerived()
	ok
	if classname(oObject) = "stringlist"
		oNew = new StringList()
		oNew.Add("a")
		return oNew
	ok
	return new TypedMath()

func compareDispatch cName, xValue, lNoArgument

	oTyped = new TypedMath()
	oGeneric = new TypedMath()
	cTyped = ""
	cGeneric = ""
	try
		eval("xResult = oTyped." + cName + "(xValue)")
		cTyped = describeResult(xResult,cName) + "/" + describe(oTyped.Last)
	catch
		cTyped = "error: " + cCatchError
	done
	try
		if isstring(xValue) and xValue = "" and lNoArgument
			xGeneric = oGeneric.callMethod(cName,[])
		but islist(xValue) and isNamed(xValue)
			xGeneric = oGeneric.callMethod(cName,[xValue])
		else
			xGeneric = oGeneric.callMethod(cName,[xValue])
		ok
		cGeneric = describeResult(xGeneric,cName) + "/" + describe(oGeneric.Last)
	catch
		cGeneric = "error: " + cCatchError
	done
	if cTyped != cGeneric
		nMismatch++
		? cName + "(" + describe(xValue) + "): typed " + cTyped + " | generic " + cGeneric
	ok
	return 1

func isNamed aValue

	for aItem in aValue
		if not (islist(aItem) and len(aItem) = 2 and isstring(aItem[1]))
			return false
		ok
	next
	return true

# the Ring method (lTyped) or callMethod: the answer as text, or the text of the error. The method may change the object: its Last is added.
func tryCall oObject, cName, aArgs, lTyped

	cResult = ""
	try
		if lTyped
			cCall = "xResult = oObject." + cName + "("
			for x = 1 to len(aArgs)
				if x > 1
					cCall += ","
				ok
				cCall += "aArgs[" + x + "]"
			next
			cCall += ")"
			eval(cCall)
		else
			xResult = oObject.callMethod(cName,aArgs)
		ok
		cResult = describeResult(xResult,cName)
		if isattribute(oObject,"last")
			cResult += "/" + describe(oObject.Last)
		ok
	catch
		cResult = "error: " + cCatchError
	done
	return cResult

# the answer of a call: a method that answers nothing gives the object from the Ring method and the null object from callMethod, so they are not compared
func describeResult xResult, cName

	if find(["Set2","Reset","Insert","RemoveAt"],cName) > 0 and isobject(xResult)
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
