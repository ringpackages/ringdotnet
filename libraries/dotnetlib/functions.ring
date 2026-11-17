/*
	DotNetLib - Functions
	Wire format: items of <tag><byte length>:<data>  (see extensions/ringdotnet/bridge/Bridge.cs)
*/

# Pack one Ring value as a wire item
func dnPackItem  dn_xValue
	if isstring(dn_xValue)
		return C_DOTNET_STRING + len(dn_xValue) + ":" + dn_xValue
	ok
	if isnumber(dn_xValue)
		if dn_xValue = floor(dn_xValue) and fabs(dn_xValue) < 1000000000000
			dn_cNumber = string(dn_xValue)
			return C_DOTNET_NUMBER + len(dn_cNumber) + ":" + dn_cNumber
		ok
		# other numbers travel as the 8 bytes of the double (no loss of precision)
		return C_DOTNET_DOUBLE + "8:" + double2bytes(dn_xValue)
	ok
	if islist(dn_xValue)
		dn_cData = dnPack(dn_xValue)
		return C_DOTNET_LIST + len(dn_cData) + ":" + dn_cData
	ok
	if isobject(dn_xValue) and isattribute(dn_xValue,"cCode")
		return C_DOTNET_CALLBACK + len(dn_xValue.cCode) + ":" + dn_xValue.cCode
	ok
	if isobject(dn_xValue) and isattribute(dn_xValue,"nHandle")
		if dn_xValue.nHandle = 0
			return C_DOTNET_NULL + "0:"
		ok
		dn_cHandle = string(dn_xValue.nHandle)
		return C_DOTNET_OBJECT + len(dn_cHandle) + ":" + dn_cHandle
	ok
	raise("DotNet Error: Unsupported parameter type (use strings, numbers, lists and .NET objects)")

# Pack a list of Ring values
func dnPack  aValues
	dn_cData = ""
	for dn_xValue in aValues
		dn_cData += dnPackItem(dn_xValue)
	next
	return dn_cData

# Unpack wire items to a Ring list
func dnUnpack  dn_cData
	dn_aItems = []
	dn_nPos = 1
	dn_nSize = len(dn_cData)
	while dn_nPos <= dn_nSize
		dn_cTag = dn_cData[dn_nPos]
		dn_nPos++
		dn_nLen = 0
		while dn_cData[dn_nPos] != ":"
			dn_nLen = dn_nLen * 10 + (ascii(dn_cData[dn_nPos]) - 48)
			dn_nPos++
		end
		dn_nPos++
		if dn_nLen > 0
			dn_cBody = substr(dn_cData,dn_nPos,dn_nLen)
		else
			dn_cBody = ""
		ok
		dn_nPos += dn_nLen
		switch dn_cTag
		on C_DOTNET_STRING
			dn_aItems + dn_cBody
		on C_DOTNET_NUMBER
			dn_aItems + number(dn_cBody)
		on C_DOTNET_BOOL
			dn_aItems + (dn_cBody = "1")
		on C_DOTNET_NULL
			dn_aItems + new DotNetObject(0)
		on C_DOTNET_OBJECT
			dn_aItems + dnWrapObject(dn_cBody)
		on C_DOTNET_LIST
			dn_aItems + dnUnpack(dn_cBody)
		on C_DOTNET_ERROR
			raise("DotNet Error: " + dn_cBody)
		other
			raise("DotNet Error: Unknown response item '" + dn_cTag + "'")
		off
	end
	return dn_aItems

# Send a request to the bridge: dnRequest("call", [oTarget, "Method", arg1, ...]), returns one value
func dnRequest  cOperation, aParameters
	dn_cResponse = dotnet_invoke(C_DOTNET_STRING + len(cOperation) + ":" + cOperation + dnPack(aParameters))
	dn_aItems = dnUnpack(dn_cResponse)
	return dn_aItems[1]

# Version of the .NET runtime that is hosted in this process
func dnVersion
	return dnRequest("version",[])

# Load an assembly (.dll) from a path, returns the assembly name
func dnLoad  cPath
	return dnRequest("load",[cPath])

# Load an assembly by name (for example "System.Xml")
func dnLoadName  dn_cName
	return dnRequest("loadname",[dn_cName])

# Get a type (to call its static members), for example dnType("System.Math")
func dnType  cTypeName
	return dnRequest("type",[cTypeName])

# Create a .NET object: dnNew("System.Text.StringBuilder", ["Hello"])
func dnNew  cTypeName, aParameters
	if not islist(aParameters)
		aParameters = []
	ok
	return dnRequest("new",dnJoin([dnType(cTypeName)],aParameters))

# Call a static method: dnStatic("System.Math", "Max", [3, 9])
func dnStatic  cTypeName, cMethod, aParameters
	if not islist(aParameters)
		aParameters = []
	ok
	return dnType(cTypeName).callMethod(cMethod,aParameters)

# Append the items of one list to another (in Ring, list + list adds a nested list)
func dnJoin  aFirst, aRest
	for dn_xItem in aRest
		aFirst + dn_xItem
	next
	return aFirst

# Type object for static members, cached per type name
func dnTypeCached  cTypeName
	dn_nPos = find(aDotNetTypes,cTypeName,1)
	if dn_nPos > 0
		return aDotNetTypes[dn_nPos][2]
	ok
	dn_oType = dnType(cTypeName)
	aDotNetTypes + [cTypeName,dn_oType]
	return dn_oType

# Create a .NET object and return its handle (used by the generated classes)
func dnCreate  cTypeName, aParameters
	dn_xNew = dnRequest("new",dnJoin([dnTypeCached(cTypeName)],aParameters))
	if isobject(dn_xNew)
		return dn_xNew.nHandle
	ok
	return 0	# primitive values (Int32, Double...) have no object, their classes are used for static members

# Public API of a type (used by tools/gendotnet.ring)
func dnDescribe  cTypeName
	return dnRequest("describe",[cTypeName])

# Ring code callable from .NET: dnCallback("? aDotNetArgs[1]") or dnCallback("myfunc"),
# then pass it where a delegate is expected. The code is compiled once into a function (the same code gives the same function).
func dnCallback  cCode
	dn_nPos = find(aDotNetCallbacks,cCode,1)
	if dn_nPos = 0
		dn_cName = "dncallback" + (len(aDotNetCallbacks) + 1)
		if dnIsIdentifier(cCode)
			dn_cBody = "xDotNetResult = " + cCode + "(aDotNetArgs)"
		else
			dn_cBody = cCode
		ok
		eval("func " + dn_cName + nl + dn_cBody + nl)
		aDotNetCallbacks + [cCode,dn_cName]
		dn_nPos = len(aDotNetCallbacks)
	ok
	return new DotNetCallback(aDotNetCallbacks[dn_nPos][2])

# Runs one Ring callback requested by .NET (called by the extension, don't call it directly)
func dnDispatchCallback
	dn_aItems = dnUnpack(dotnet_callbackrequest())
	aDotNetArgs = []
	for dn_x = 2 to len(dn_aItems)
		aDotNetArgs + dn_aItems[dn_x]
	next
	try
		xDotNetResult = ""
		dn_cFunction = dn_aItems[1]
		call dn_cFunction()
		dn_cOut = dnPackItem(xDotNetResult)
	catch
		dn_cOut = C_DOTNET_ERROR + len(cCatchError) + ":" + cCatchError
	done
	dotnet_callbackresult(dn_cOut)

# True when the text is only a name (letters, digits, _), i.e. a function name and not Ring code
func dnIsIdentifier  cText
	if cText = ""
		return false
	ok
	for dn_x = 1 to len(cText)
		dn_n = ascii(cText[dn_x])
		dn_lLetter = (dn_n >= 65 and dn_n <= 90) or (dn_n >= 97 and dn_n <= 122) or dn_n = 95
		dn_lDigit = (dn_n >= 48 and dn_n <= 57)
		if not (dn_lLetter or (dn_x > 1 and dn_lDigit))
			return false
		ok
	next
	return true

# Use Windows Forms / WPF (adds the Windows Desktop runtime). Call it before any other .NET call.
func dnUseDesktop
	dotnet_start("desktop")
	# errors in event handlers are raised out of Application.Run() (catch them with try/catch) instead of opening a dialog
	dnRequest("call",[dnTypeCached("System.Windows.Forms.Application, System.Windows.Forms"),"SetUnhandledExceptionMode","ThrowException"])
	return 1

# Folder (with a trailing "/") of a file path
func dnFolderOf  cPath
	for dn_x = len(cPath) to 1 step -1
		if cPath[dn_x] = "/" or cPath[dn_x] = "\\"
			return left(cPath,dn_x)
		ok
	next
	return ""

# Load the generated Ring classes of a .NET namespace: dnImport("System.IO")
func dnImport  cNamespace
	if find(aDotNetImported,cNamespace) > 0
		return true
	ok
	dn_cFile = cDotNetLibFolder + "generated/" + cNamespace + ".ring"
	if not fexists(dn_cFile)
		raise("DotNet Error: No generated classes for the namespace " + cNamespace + " (see tools/dotnetmanifest.ring)")
	ok
	aDotNetImported + cNamespace
	eval('load "' + dn_cFile + '"')
	return true

# Load classes generated by tools/wrapassembly.ring for your own assembly: dnImportFrom("myclasses/","MyCompany.Tools")
func dnImportFrom  cFolder, cNamespace
	dn_cFile = cFolder + cNamespace + ".ring"
	if find(aDotNetImported,dn_cFile) > 0
		return true
	ok
	if not fexists(dn_cFile)
		raise("DotNet Error: File not found: " + dn_cFile)
	ok
	aDotNetImported + dn_cFile
	eval('load "' + dn_cFile + '"')
	return true

# Name of a closed generic type: dnGenericName("System.Collections.Generic.List",["System.Int32"])
func dnGenericName  cType, aArguments
	dn_cName = cType + "`" + len(aArguments) + "["
	for dn_x = 1 to len(aArguments)
		if dn_x > 1 dn_cName += "," ok
		dn_cName += "[" + aArguments[dn_x] + "]"
	next
	return dn_cName + "]"

# Create an object of a generic type without a generated class (a DotNetObject: use callMethod/getProp)
func dnNewGeneric  cType, aArguments, aParameters
	return dnNew(dnGenericName(cType,aArguments),aParameters)

# Simple test helpers: dnAssert("name",actual,expected) ... dnTestSummary()
func dnAssert  dn_cName, xActual, xExpected
	if (isnumber(xActual) and isnumber(xExpected) and fabs(xActual - xExpected) < 0.000001) or (isstring(xActual) and isstring(xExpected) and xActual = xExpected)
		nDotNetPass++
	else
		nDotNetFail++
		? "FAIL: " + dn_cName + " expected <" + dnShow(xExpected) + "> got <" + dnShow(xActual) + ">"
	ok

func dnShow  dn_xValue
	if isstring(dn_xValue) or isnumber(dn_xValue)
		return "" + dn_xValue
	ok
	return "(" + type(dn_xValue) + ")"

func dnTestSummary
	? "TESTS: " + nDotNetPass + " passed, " + nDotNetFail + " failed"
	return nDotNetFail

# Register a generated class: objects of this .NET type are returned as instances of the Ring class
func dnRegisterClass  cType, cClass, nInit
	if find(aDotNetClasses,cType,1) = 0
		cDummies = ""
		for dn_x = 1 to nInit
			if dn_x > 1 cDummies += "," ok
			cDummies += "0"
		next
		aDotNetClasses + [cType,cClass,cDummies]
	ok

# A .NET object received from the bridge ("<handle>|<type>|<base type>|...") as the generated class of its type.
# When no class is registered yet, the namespace of the first known type of the chain is imported automatically.
func dnWrapObject  cInfo
	dn_aParts = str2list(substr(cInfo,"|",nl))
	nHandle = number(dn_aParts[1])
	for dn_nPass = 1 to 2
		for dn_x = 2 to len(dn_aParts)
			dn_nPos = find(aDotNetClasses,dn_aParts[dn_x],1)
			if dn_nPos > 0
				nDotNetWrapHandle = nHandle
				dn_cFactory = "dotnetnew_" + aDotNetClasses[dn_nPos][2]
				call dn_cFactory()
				return oDotNetNew
			ok
		next
		if dn_nPass = 1
			dn_lImported = false
			for dn_x = 2 to len(dn_aParts)
				dn_nPos = find(aDotNetClassIndex,dn_aParts[dn_x],1)
				if dn_nPos > 0
					if find(aDotNetImported,aDotNetClassIndex[dn_nPos][2]) = 0
						dnImport(aDotNetClassIndex[dn_nPos][2])
						dn_lImported = true
					ok
					exit
				ok
			next
			if not dn_lImported
				exit
			ok
		ok
	next
	return new DotNetObject(nHandle)

# The .NET null: oPictureBox.Image = dnNull()
func dnNull
	return new DotNetObject(0)
