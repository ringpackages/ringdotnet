# toList(): a list of texts, numbers and yes/nos is made in C and returned as it is; every other collection (an object, a null, bytes, an error while the items
# are read) is read by dnFinish from the answer that the extension kept. The result and the error must be those of the plain request ("tolist").
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

oLists = new TypedLists()
aNames = ["Texts","Numbers","Longs","Doubles","Floats","Decimals","Bools","Mixed","WithNull","WithObject","Nulls","Empty","Bytes","Nested","Dict","Array","Ints",
          "Big","BigTexts","Throws","Lazy"]
nMismatch = 0
for cName in aNames
	eval("oCollection = oLists." + cName + "()")
	cNew = tryList(oCollection,true)
	cOld = tryList(oCollection,false)
	if cNew != cOld
		nMismatch++
		? cName + ": toList " + left(cNew,120) + " | request " + left(cOld,120)
	ok
next
dnAssert("toList gives the answer of the plain request for " + len(aNames) + " collections",nMismatch,0)

# values
aTexts = oLists.Texts().toList()
dnAssert("a list of texts: the items",len(aTexts),6)
dnAssert("a text with a UTF-8 letter",aTexts[3],"héllo ✓")
dnAssert("a text with a line break",aTexts[4],"line" + nl + "break")
dnAssert("a text with a NUL",aTexts[6],"nul" + char(0) + "nul")
aNumbers = oLists.Numbers().toList()
dnAssert("numbers: the first and the last",aNumbers[1] + aNumbers[5],-2147483648)
dnAssert("a list of yes/nos",oLists.Bools().toList()[2],0)
dnAssert("an empty collection",len(oLists.Empty().toList()),0)
dnAssert("a big list",len(oLists.Big().toList()),20000)
dnAssert("the last item of a big list",oLists.Big().toList()[20000],19999)
aNulls = oLists.Nulls().toList()
dnAssert("a null text is the null object",dnIsNull(aNulls[2]),1)
dnAssert("the texts around a null",aNulls[1] + aNulls[3],"ab")
aObjects = oLists.WithObject().toList()
dnAssert("an object in the list is wrapped",aObjects[2].IntValue,7)
aDict = oLists.Dict().toList()
dnAssert("a dictionary: the pairs are objects",len(aDict),2)
dnAssert("an array of texts",oLists.Array().toList()[2],"q")
dnAssert("an array of numbers",oLists.Ints().toList()[3],6)
dnAssert("a lazy sequence",oLists.Lazy().toList()[2],20)
cError = tryList(oLists.Throws(),true)
dnAssert("an error while the items are read is raised",substr(cError,"enumeration failed") > 0,1)
# the answer of a failed call is not kept: the next call is a different one
dnAssert("a call after the error",len(oLists.Texts().toList()),6)
# the null object
oNull = new DotNetObject(0)
dnAssert("the null object raises the same error as the request",tryList(oNull,true),tryList(oNull,false))

dnTestSummary()

# the items as text, or the text of the error: with toList (lNew) or with the plain request
func tryList oObject, lNew

	try
		if lNew
			aItems = oObject.toList()
		else
			aItems = dnRequest("tolist",[oObject])
		ok
	catch
		return "error: " + cCatchError
	done
	return describeList(aItems)

func describeList aList

	cText = "[" + len(aList) + "]"
	for xItem in aList
		cText += " " + describe(xItem)
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
			return "null"
		ok
		return "object:" + classname(xValue)
	ok
	return "list" + describeList(xValue)
