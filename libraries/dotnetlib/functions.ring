/*
	DotNetLib - Functions
	Wire format: items of <tag><byte length>:<data>  (see extensions/ringdotnet/bridge/Bridge.cs)
*/

# Pack one Ring value as a wire item
func dnPackItem  xValue
	if isstring(xValue)
		return C_DOTNET_STRING + len(xValue) + ":" + xValue
	ok
	if isnumber(xValue)
		cNumber = string(xValue)
		return C_DOTNET_NUMBER + len(cNumber) + ":" + cNumber
	ok
	if islist(xValue)
		cData = dnPack(xValue)
		return C_DOTNET_LIST + len(cData) + ":" + cData
	ok
	if isobject(xValue) and isattribute(xValue,"cCode")
		return C_DOTNET_CALLBACK + len(xValue.cCode) + ":" + xValue.cCode
	ok
	if isobject(xValue) and isattribute(xValue,"nHandle")
		if xValue.nHandle = 0
			return C_DOTNET_NULL + "0:"
		ok
		cHandle = string(xValue.nHandle)
		return C_DOTNET_OBJECT + len(cHandle) + ":" + cHandle
	ok
	raise("DotNet Error: Unsupported parameter type (use strings, numbers, lists and .NET objects)")

# Pack a list of Ring values
func dnPack  aValues
	cData = ""
	for xValue in aValues
		cData += dnPackItem(xValue)
	next
	return cData

# Unpack wire items to a Ring list
func dnUnpack  cData
	aItems = []
	nPos = 1
	nSize = len(cData)
	while nPos <= nSize
		cTag = cData[nPos]
		nPos++
		nLen = 0
		while cData[nPos] != ":"
			nLen = nLen * 10 + (ascii(cData[nPos]) - 48)
			nPos++
		end
		nPos++
		if nLen > 0
			cBody = substr(cData,nPos,nLen)
		else
			cBody = ""
		ok
		nPos += nLen
		switch cTag
		on C_DOTNET_STRING
			aItems + cBody
		on C_DOTNET_NUMBER
			aItems + number(cBody)
		on C_DOTNET_BOOL
			aItems + (cBody = "1")
		on C_DOTNET_NULL
			aItems + new DotNetObject(0)
		on C_DOTNET_OBJECT
			aItems + new DotNetObject(number(cBody))
		on C_DOTNET_LIST
			aItems + dnUnpack(cBody)
		on C_DOTNET_ERROR
			raise("DotNet Error: " + cBody)
		other
			raise("DotNet Error: Unknown response item '" + cTag + "'")
		off
	end
	return aItems

# Send a request to the bridge: dnRequest("call", [oTarget, "Method", arg1, ...]), returns one value
func dnRequest  cOperation, aParameters
	cResponse = dotnet_invoke(C_DOTNET_STRING + len(cOperation) + ":" + cOperation + dnPack(aParameters))
	aItems = dnUnpack(cResponse)
	return aItems[1]

# Version of the .NET runtime that is hosted in this process
func dnVersion
	return dnRequest("version",[])

# Load an assembly (.dll) from a path, returns the assembly name
func dnLoad  cPath
	return dnRequest("load",[cPath])

# Load an assembly by name (for example "System.Xml")
func dnLoadName  cName
	return dnRequest("loadname",[cName])

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
	for xItem in aRest
		aFirst + xItem
	next
	return aFirst

# Type object for static members, cached per type name
func dnTypeCached  cTypeName
	nPos = find(aDotNetTypes,cTypeName,1)
	if nPos > 0
		return aDotNetTypes[nPos][2]
	ok
	oType = dnType(cTypeName)
	aDotNetTypes + [cTypeName,oType]
	return oType

# Create a .NET object and return its handle (used by the generated classes)
func dnCreate  cTypeName, aParameters
	return dnRequest("new",dnJoin([dnTypeCached(cTypeName)],aParameters)).nHandle

# Public API of a type (used by tools/gendotnet.ring)
func dnDescribe  cTypeName
	return dnRequest("describe",[cTypeName])

# Ring code callable from .NET: dnCallback("? aDotNetArgs[1]") or dnCallback("myfunc"),
# then pass it where a delegate is expected
func dnCallback  cCode
	return new DotNetCallback(cCode)

# Runs one Ring callback requested by .NET (called by the extension, don't call it directly)
func dnDispatchCallback
	aItems = dnUnpack(dotnet_callbackrequest())
	aDotNetArgs = []
	for x = 2 to len(aItems)
		aDotNetArgs + aItems[x]
	next
	try
		xDotNetResult = ""
		if dnIsIdentifier(aItems[1])
			eval("xDotNetResult = " + aItems[1] + "(aDotNetArgs)")
		else
			eval(aItems[1])
		ok
		cOut = dnPackItem(xDotNetResult)
	catch
		cOut = C_DOTNET_ERROR + len(cCatchError) + ":" + cCatchError
	done
	dotnet_callbackresult(cOut)

# True when the text is only a name (letters, digits, _), i.e. a function name and not Ring code
func dnIsIdentifier  cText
	if cText = ""
		return false
	ok
	for x = 1 to len(cText)
		n = ascii(cText[x])
		lLetter = (n >= 65 and n <= 90) or (n >= 97 and n <= 122) or n = 95
		lDigit = (n >= 48 and n <= 57)
		if not (lLetter or (x > 1 and lDigit))
			return false
		ok
	next
	return true
