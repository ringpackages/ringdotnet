# Typed properties: the getter and the setter of a property of a number, a yes/no or a text call the extension, which reads and writes it without a request
# text (dotnet_getp, dotnet_setp). Every result and every error must be the one of the generic request (getProp, setProp), also for the properties that the
# typed path leaves to it: an enum, a char, a nullable, a byte array, a struct, a property that throws, one that hides another.
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

# ---- values
oBox = new TypedBox()
oBox.IntValue = 5
dnAssert("an int property is written and read",oBox.IntValue,5)
oBox.Text = "héllo ✓"
dnAssert("a text with letters that are not ASCII",oBox.Text,"héllo ✓")
oBox.Text = ""
dnAssert("the empty text",oBox.Text,"")
oBox.Flag = 1
dnAssert("a yes/no is true",oBox.Flag,1)
oBox.Flag = 0
dnAssert("a yes/no is false",oBox.Flag,0)
oBox.DoubleValue = 0.1
dnAssert("a double",oBox.DoubleValue = 0.1,1)
oBox.LongValue = 9007199254740991
dnAssert("a long",oBox.LongValue,9007199254740991)
oBox.DecimalValue = 12.5
dnAssert("a decimal",oBox.DecimalValue,12.5)
oBox.FloatValue = 1.5
dnAssert("a float",oBox.FloatValue,1.5)
dnAssert("a read-only property",oBox.ReadOnly,42)
oBox.CountField = 7
dnAssert("a public field of a number",oBox.CountField,7)
oBox.Field = "in a field"
dnAssert("a public field of a text",oBox.Field,"in a field")
oBox.WriteOnlyValue = 9
dnAssert("a write-only property: the value arrived",oBox.LastWritten,9)
dnAssert("a text that was never set is null",dnIsNull(new TypedBox().Text),1)
oBox.Text = 12
dnAssert("a text property gets the text of a number",oBox.Text,"12")
oBox.Color = "Blue"
dnAssert("an enum is still a text",oBox.Color,"Blue")
oBox.Flags = "A, C"
dnAssert("a flags enum",oBox.Flags,"A, C")
oBox.ColorField = "Red"
dnAssert("an enum field",oBox.ColorField,"Red")
dnAssert("a read-only enum",oBox.ReadOnlyColor,"Green")
oBox.Maybe = 3
dnAssert("a nullable int",oBox.Maybe,3)
oBox.Letter = "x"
dnAssert("a char",oBox.Letter,"x")
oDerived = new TypedDerived()
oDerived.IntValue = "hidden by a text"
dnAssert("a property that hides one of another type",oDerived.IntValue,"hidden by a text")
oDerived.Extra = 4
dnAssert("a property of the derived class",oDerived.Extra,4)
oDerived.ByteValue = 200
dnAssert("a property of the base class on a derived object",oDerived.ByteValue,200)
oPoint = dnNew("MyCompany.Tools.TypedPoint",[])
oPoint.X = 3
oPoint.Y = 4
dnAssert("a struct: a property",oPoint.X,3)
dnAssert("a struct: a field",oPoint.Y,4)

# ---- the same results and errors as the generic request
aNumberNames = ["SByteValue","ByteValue","ShortValue","UShortValue","IntValue","UIntValue","LongValue","ULongValue","FloatValue","DoubleValue","DecimalValue","CountField","Flag"]
aOtherNames = ["Text","Field","Letter","Color","Flags","ColorField","ReadOnlyColor","Maybe","Bytes","ReadOnly","LastWritten","WriteOnlyValue","Throws"]
aValues = [0,1,-1,3.5,0.1,127,128,255,256,-128,-129,32767,32768,65535,65536,2147483647,2147483648,4294967295,4294967296,1000000000000000,100000000000000000000,-100000000000000000000,
           "","abc","12","true","Blue","blue","Green","2","A, C","A","99",char(195) + char(169),char(255) + char(254),[1,2],[ ["a",1] ]]
aAllNames = []
for cName in aNumberNames
	aAllNames + cName
next
for cName in aOtherNames
	aAllNames + cName
next
nChecked = 0
nMismatch = 0
for cName in aAllNames
	# read: a fresh object of each kind, after a write through the generic request
	for xValue in aValues
		oA = new TypedBox()
		oB = new TypedBox()
		# (a read-only property has a setter that raises its own error, and a write-only one has no getter: those are not the typed path)
		if cName != "ReadOnly" and cName != "ReadOnlyColor"
			cWrite = tryWrite(oA,cName,xValue,true)
			cGenericWrite = tryWrite(oB,cName,xValue,false)
			nChecked++
			if cWrite != cGenericWrite
				nMismatch++
				? "write " + cName + " = " + describe(xValue) + ": typed " + cWrite + " | generic " + cGenericWrite
			ok
		ok
		if cName != "WriteOnlyValue"
			cRead = tryRead(oA,cName,true)
			cGenericRead = tryRead(oB,cName,false)
			nChecked++
			if cRead != cGenericRead
				nMismatch++
				? "read " + cName + " after " + describe(xValue) + ": typed " + cRead + " | generic " + cGenericRead
			ok
		ok
	next
next
dnAssert("typed and generic reads and writes agree (" + nChecked + " comparisons)",nMismatch,0)

# the other classes, read after a write
for oPair in [ [new TypedDerived(),"IntValue"], [new TypedDerived(),"Extra"], [new TypedDerived(),"ByteValue"] ]
	oObject = oPair[1]
	for xValue in aValues
		cA = tryWrite(oObject,oPair[2],xValue,true)
		oOther = new TypedDerived()
		cB = tryWrite(oOther,oPair[2],xValue,false)
		if cA != cB
			nMismatch++
			? "derived write " + oPair[2] + " = " + describe(xValue) + ": typed " + cA + " | generic " + cB
		ok
	next
next
dnAssert("a derived class agrees too",nMismatch,0)
oPointA = dnNew("MyCompany.Tools.TypedPoint",[])
oPointB = dnNew("MyCompany.Tools.TypedPoint",[])
oPointA.X = 11
oPointB.setProp("X",11)
dnAssert("a struct is changed in its box, as by the generic request",oPointA.X,oPointB.getProp("X"))

# ---- errors of the property itself
dnAssert("a property that throws on read: the same text",tryRead(new TypedBox(),"Throws",true),tryRead(new TypedBox(),"Throws",false))
dnAssert("the text of that error",substr(tryRead(new TypedBox(),"Throws",true),"no read") > 0,1)
dnAssert("a property that throws on write: the same text",tryWrite(new TypedBox(),"Throws",1,true),tryWrite(new TypedBox(),"Throws",1,false))
dnAssert("the text of that error on write",substr(tryWrite(new TypedBox(),"Throws",1,true),"no write") > 0,1)
# a handle that is not valid, and the null object
oGone = new TypedBox()
oNullBox = new DotNetObject(0)
cError = ""
try
	x = oNullBox.getProp("IntValue")
catch
	cError = cCatchError
done
dnAssert("the null object raises the generic error on a generic read",len(cError) > 0,1)

dnTestSummary()

# reads a property with the typed getter (lTyped) or with the generic request: the value as text, or the text of the error
func tryRead oObject, cName, lTyped

	cResult = ""
	try
		if lTyped
			eval("xValue = oObject.get" + cName + "()")
		else
			xValue = oObject.getProp(cName)
		ok
		cResult = describe(xValue)
	catch
		cResult = "error: " + cCatchError
	done
	return cResult

# writes a property with the typed setter or with the generic request: "done", or the text of the error
func tryWrite oObject, cName, xValue, lTyped

	cResult = "done"
	try
		if lTyped
			eval("oObject.set" + cName + "(xValue)")
		else
			oObject.setProp(cName,xValue)
		ok
	catch
		cResult = "error: " + cCatchError
	done
	return cResult

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
