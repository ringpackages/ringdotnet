/*
	DotNetLib - Functions

	The functions of this file are of two kinds:
	  - the ones that a program calls: dnNew, dnStatic, dnType, dnCallback, dnImport, dnImportFrom, dnNull, dnBuffer, dnFlush, dnVersion,
	    dnLoad, dnUseDesktop / dnUseWeb / dnUseAll / dnUseData, dnAssert ...
	  - the ones that the library and the generated classes use: dnRequest and the packing of values, dnCreate, dnWrapObject ...

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

# Send a request to the bridge: dnRequest("call", [oTarget, "Method", arg1, ...]), returns one value.
# The common answers (a text, a number, a yes/no, one object) are read directly, without making a list of items.
func dnRequest  cOperation, aParameters
	return dnExchange(C_DOTNET_STRING + len(cOperation) + ":" + cOperation + dnPack(aParameters))

# The request of a generated method for a member of an object: the operation and the name are ready wire items ("s4:call", "s6:Append"),
# the handle is a number (0 is the null object) and the arguments are packed. It makes the same request text as dnRequest, without a list
# and a DotNetObject for the target (about 40% of the time of a call).
func dnSend  cOperation, nHandle, cName, cArgs
	if nHandle = 0
		return dnExchange(cOperation + C_DOTNET_NULL + "0:" + cName + cArgs)
	ok
	dn_cHandle = string(nHandle)
	return dnExchange(cOperation + C_DOTNET_OBJECT + len(dn_cHandle) + ":" + dn_cHandle + cName + cArgs)

# Send a request text to the bridge and read the answer
func dnExchange  cRequest
	return dnFinish(dotnet_invoke(cRequest))

# The answer of the bridge (one item, or a list of items) as a Ring value
func dnFinish  dn_cResponse
	dn_cTag = left(dn_cResponse,1)
	dn_nColon = substr(dn_cResponse,":")
	if dn_nColon > 0 and (dn_cTag = C_DOTNET_STRING or dn_cTag = C_DOTNET_NUMBER or dn_cTag = C_DOTNET_BOOL or dn_cTag = C_DOTNET_OBJECT)
		dn_nLen = number(substr(dn_cResponse,2,dn_nColon - 2))
		if len(dn_cResponse) = dn_nColon + dn_nLen
			if dn_nLen > 0
				dn_cBody = substr(dn_cResponse,dn_nColon + 1,dn_nLen)
			else
				dn_cBody = ""
			ok
			switch dn_cTag
			on C_DOTNET_STRING
				return dn_cBody
			on C_DOTNET_NUMBER
				return number(dn_cBody)
			on C_DOTNET_BOOL
				return (dn_cBody = "1")
			on C_DOTNET_OBJECT
				dnWrapInto(dn_cBody)
				dn_oObject = oDotNetNew          # a copy: the next wrapped object replaces oDotNetNew, and a chained call (a.B().C()) may still be running on this one
				oDotNetNew = ""          # (the global must not keep the object alive: it owns the handle)
				return dn_oObject
			off
		ok
	ok
	dn_aItems = dnUnpack(dn_cResponse)
	return dn_aItems[1]

# The handles of the objects that Ring freed are released in groups (the next .NET call does it when 32 are waiting).
# dnFlush() releases them now. Ring frees an object a little after the last variable that held it is gone; callgc() (called in the
# same function) makes it free the objects at once. So to let go of a big object now (or before you look at the memory of .NET with
# GC.GetTotalMemory) write:  oBig = NULL  callgc()  dnFlush()
func dnFlush
	dotnet_flush()

# The number of .NET objects that Ring holds now (handles in the table of the bridge): a test of the release of handles compares it before
# and after the objects were dropped (call callgc() and dnFlush() first)
func dnHandleCount
	return dnRequest("handlecount",[])

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
# The arguments can be named: dnNew("StringBuilder",[ :value = "Hello", :capacity = 64 ]) chooses the constructor by the parameter names
# (the order does not matter). The class is a full .NET type name or the name of a generated Ring class (see dnImport)
func dnNew  cTypeName, aParameters
	if not islist(aParameters)
		aParameters = []
	ok
	dn_cType = cTypeName
	dn_cFound = aDotNetNameMap[lower(cTypeName)]          # the registered type of a Ring class name
	if dn_cFound != ""
		dn_cType = dn_cFound
	ok
	if len(aParameters) > 0 and dnIsNamed(aParameters)
		return dnRequest("newnamed",[dnTypeCached(dn_cType),aParameters])
	ok
	return dnRequest("new",dnJoin([dnType(dn_cType)],aParameters))

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
	dn_oType = aDotNetTypes[cTypeName]
	if isobject(dn_oType)
		return dn_oType
	ok
	dn_oType = dnType(cTypeName)
	aDotNetTypes[cTypeName] = dn_oType
	return dn_oType

# Create a .NET object and return its handle (used by the generated classes)
func dnCreate  cTypeName, aParameters
	return dnNewHandle("s9:newhandle",cTypeName,dnPack(aParameters))

# The answer of dotnet_callo (a call that returns an object): the extension answers the text "<handle>|<type>|<base type>..." and the Ring
# function wraps it as the generated class of the type; null is 0; any other answer is the list [1, answer] that dnFinish reads.
func dnObj  dn_xInfo
	if isstring(dn_xInfo)
		dn_nBar = substr(dn_xInfo,"|")
		if dn_nBar > 0
			dn_cChain = substr(dn_xInfo,dn_nBar + 1)
			dn_cFactory = aDotNetWrapCache[dn_cChain]
			if dn_cFactory = ""
				dn_cFactory = dnFindFactory(dn_cChain)
				aDotNetWrapCache[dn_cChain] = dn_cFactory
			ok
			if dn_cFactory != "-"
				# a ready object of the class (made once, with no handle) is copied: a copy is cheaper than new, which runs the class bodies
				# and init of every parent class (a Button has about 110 attributes)
				dn_oObject = aDotNetPrototypes[dn_cFactory]
				if not isobject(dn_oObject)
					dnMakePrototype(dn_cFactory)
					dn_oObject = aDotNetPrototypes[dn_cFactory]
				ok
				dn_nHandle = number(left(dn_xInfo,dn_nBar - 1))
				dn_oObject.nHandle = dn_nHandle
				dn_oObject.oDotNetGuard = dotnet_guard(dn_nHandle)          # this object owns the handle: it is released when the last copy is gone
				return dn_oObject
			ok
		ok
		dnWrapInto(dn_xInfo)
		dn_oObject = oDotNetNew          # a copy: the next wrapped object replaces oDotNetNew, and a method of this object may be running (a global that is replaced while
		oDotNetNew = ""          # its method runs is an error). The global must not keep the object alive: it owns the handle
		return dn_oObject
	ok
	if isnumber(dn_xInfo)
		return new DotNetObject(0)
	ok
	return dnFinish(dn_xInfo[2])

# Make the ready object of the class of a factory function (no handle, no guard) once, and keep it in aDotNetPrototypes
func dnMakePrototype  dn_cFactory
	nDotNetWrapHandle = -1          # a handle that is not released (the guard of a negative handle queues nothing)
	call dn_cFactory()
	dn_oProto = oDotNetNew
	oDotNetNew = ""
	dn_oProto.oDotNetGuard = ""
	dn_oProto.nHandle = 0
	aDotNetPrototypes[dn_cFactory] = dn_oProto

# The answer of dotnet_calla (any answer): the extension answers a text, a number or a yes/no itself and an object as the list [2, "<handle>|<type>..."]
func dnAny  dn_aAnswer
	if dn_aAnswer[1] = 2
		return dnObj(dn_aAnswer[2])
	ok
	return dnFinish(dn_aAnswer[2])

# The handle of the type object of a type name, made once (the generated static methods pass it as a number: returning the cached
# type object itself would copy it at every call)
func dnTypeHandle  cTypeName
	dn_nTypeHandle = aDotNetTypeHandles[cTypeName]
	if isnumber(dn_nTypeHandle)
		return dn_nTypeHandle
	ok
	dn_nTypeHandle = dnTypeCached(cTypeName).nHandle
	aDotNetTypeHandles[cTypeName] = dn_nTypeHandle
	return dn_nTypeHandle

# The wire item of a type (its handle), made once for each type name
func dnTypeItem  cTypeName
	dn_cItem = aDotNetTypeItems[cTypeName]
	if dn_cItem != ""
		return dn_cItem
	ok
	dn_cHandle = string(dnTypeCached(cTypeName).nHandle)
	dn_cItem = C_DOTNET_OBJECT + len(dn_cHandle) + ":" + dn_cHandle
	aDotNetTypeItems[cTypeName] = dn_cItem
	return dn_cItem

# Make an object and read its handle from the answer: the answer is a number, so the object is not wrapped for Ring (0: a value such as an
# Int32 has no object, its class is used for static members)
func dnNewHandle  cOperation, cTypeName, cArgs
	dn_cResponse = dotnet_invoke(cOperation + dnTypeItem(cTypeName) + cArgs)
	if left(dn_cResponse,1) = C_DOTNET_NUMBER
		return number(substr(dn_cResponse,substr(dn_cResponse,":") + 1,len(dn_cResponse)))
	ok
	dn_aItems = dnUnpack(dn_cResponse)          # an error answer raises it
	return 0

# True for a list of [name, value] pairs, the way Ring passes named arguments: [ :server = "x", :port = 80 ]  ([] too)
func dnIsNamed  aValue
	if not islist(aValue)
		return false
	ok
	for dn_aItem in aValue
		if not (islist(dn_aItem) and len(dn_aItem) = 2 and isstring(dn_aItem[1]))
			return false
		ok
	next
	return true

# The handle of an object created with named arguments (used by generated code)
func dnCreateNamed  cTypeName, aNamed
	return dnNewHandle("s14:newnamedhandle",cTypeName,dnPackItem(aNamed))

# Public API of a type (used by tools/dotnettools/gendotnet.ring)
func dnDescribe  cTypeName
	return dnRequest("describe",[cTypeName])

# Ring code callable from .NET: dnCallback("? aDotNetArgs[1]") or dnCallback("myfunc"), then pass it where a delegate is expected.
# Code in a text reads the arguments from aDotNetArgs and sets xDotNetResult. The NAME of a function is called with the list of the
# arguments (func myfunc aArgs) and its return value is the result. The code is compiled once into a function (the same code gives
# the same function). A callback runs on the Ring thread, while a call from Ring is running (see the page "Rules and limits").
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

# Runs one Ring callback that .NET asked for (called by the extension: a program does not call it). The arguments are in aDotNetArgs,
# and the answer is what the callback puts in xDotNetResult (or returns, for a callback that is a function name).
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
	cDotNetMode = "desktop"
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

# Load the generated Ring classes of a .NET namespace: dnImport("System.IO"). using { "System.IO" } calls it for each name.
func dnImport  cNamespace
	if find(aDotNetImported,cNamespace) > 0
		return true
	ok
	dn_cFile = cDotNetLibFolder + "generated/" + cNamespace + ".ring"
	if not fexists(dn_cFile)
		# a namespace of an assembly that was wrapped with wrapassembly.ring: its loader asks for the other namespaces of the same assembly,
		# and they are in the folder that the program gave to dnImportFrom
		for dn_cFolder in aDotNetUserFolders
			if fexists(dn_cFolder + cNamespace + ".ring")
				return dnImportFrom(dn_cFolder,cNamespace)
			ok
		next
		raise("DotNet Error: No generated classes for the namespace " + cNamespace + " (see tools/dotnettools/dotnetmanifest.ring)")
	ok
	aDotNetImported + cNamespace
	eval('load "' + dn_cFile + '"')
	aDotNetWrapCache = []
	return true

# Load classes generated by tools/dotnettools/wrapassembly.ring for your own assembly: dnImportFrom("myclasses/","MyCompany.Tools")
func dnImportFrom  cFolder, cNamespace
	dn_cFile = cFolder + cNamespace + ".ring"
	if find(aDotNetImported,dn_cFile) > 0
		return true
	ok
	if not fexists(dn_cFile)
		raise("DotNet Error: File not found: " + dn_cFile)
	ok
	if find(aDotNetUserFolders,cFolder) = 0
		aDotNetUserFolders + cFolder
		# the index of the classes of the folder ([type, namespace]): an object of a type of another namespace of the same assembly
		# is wrapped when it comes back, and its namespace is loaded from this folder
		dn_cIndex = cFolder + "classindex.ring"
		if fexists(dn_cIndex)
			eval('load "' + dn_cIndex + '"')
			dnBuildIndexMap()
		ok
	ok
	aDotNetImported + dn_cFile
	eval('load "' + dn_cFile + '"')
	aDotNetWrapCache = []
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

# Simple test helpers: dnAssert("name",actual,expected) ... dnTestSummary(). Numbers are compared with a small tolerance, texts exactly
# (binary data too: a text can hold any byte). A failure prints one line: FAIL: name expected <..> got <..>
func dnAssert  dn_cName, xActual, xExpected
	if (isnumber(xActual) and isnumber(xExpected) and fabs(xActual - xExpected) < 0.000001) or (isstring(xActual) and isstring(xExpected) and xActual = xExpected)
		nDotNetPass++
	else
		nDotNetFail++
		? "FAIL: " + dn_cName + " expected <" + dnShow(xExpected) + "> got <" + dnShow(xActual) + ">"
	ok

# A value for a message: a text or a number as it is, anything else as its type
func dnShow  dn_xValue
	if isstring(dn_xValue) or isnumber(dn_xValue)
		return "" + dn_xValue
	ok
	return "(" + type(dn_xValue) + ")"

# Print "TESTS: n passed, m failed" and return the number of failures
func dnTestSummary
	? "TESTS: " + nDotNetPass + " passed, " + nDotNetFail + " failed"
	return nDotNetFail

# Register a generated class: objects of this .NET type are returned as instances of the Ring class
func dnRegisterClass  cType, cClass, nInit
	if aDotNetClassMap[cType] = ""
		cDummies = ""
		for dn_x = 1 to nInit
			if dn_x > 1 cDummies += "," ok
			cDummies += "0"
		next
		aDotNetClasses + [cType,cClass,cDummies]
		aDotNetClassMap[cType] = cClass
		if aDotNetNameMap[lower(cClass)] = ""
			aDotNetNameMap[lower(cClass)] = cType
		ok
	ok

# The index of the generated classes as a hash table (type --> namespace); built once, when it is first needed
func dnBuildIndexMap
	for dn_aItem in aDotNetClassIndex
		aDotNetIndexMap[dn_aItem[1]] = dn_aItem[2]
	next
	aDotNetIndexMap["#built"] = "1"

# A .NET object received from the bridge ("<handle>|<type>|<base type>|...") as the generated class of its type. The new object owns the
# handle: its managed pointer (a guard) releases the handle when Ring drops the object.
# When no class is registered yet, the namespace of the first known type of the chain is imported automatically.
# The answer for a chain of types is remembered (aDotNetWrapCache): most objects come from a few types.
func dnWrapObject  cInfo
	dnWrapInto(cInfo)
	dn_oObject = oDotNetNew
	oDotNetNew = ""
	return dn_oObject

# The same, but the object is left in the global oDotNetNew (returning it would copy it once more: a class can have 100 attributes)
func dnWrapInto  cInfo
	dn_nBar = substr(cInfo,"|")
	if dn_nBar = 0
		oDotNetNew = new DotNetOwned(number(cInfo))
		return
	ok
	nHandle = number(left(cInfo,dn_nBar - 1))
	dn_cChain = substr(cInfo,dn_nBar + 1)
	dn_cFactory = aDotNetWrapCache[dn_cChain]
	if dn_cFactory = ""
		dn_cFactory = dnFindFactory(dn_cChain)
		aDotNetWrapCache[dn_cChain] = dn_cFactory
	ok
	if dn_cFactory = "-"
		oDotNetNew = new DotNetOwned(nHandle)
		return
	ok
	nDotNetWrapHandle = nHandle
	call dn_cFactory()

# The factory function for a chain "type|base type|..." (the most specific type first: a type that is not imported yet is
# imported on demand before a less specific one is used), or "-" when no class is known
func dnFindFactory  dn_cChain
	if aDotNetIndexMap["#built"] = ""
		dnBuildIndexMap()
	ok
	dn_aParts = str2list(substr(dn_cChain,"|",nl))
	for dn_x = 1 to len(dn_aParts)
		dn_cClass = aDotNetClassMap[dn_aParts[dn_x]]
		if dn_cClass = ""
			dn_cNamespace = aDotNetIndexMap[dn_aParts[dn_x]]
			if dn_cNamespace != "" and find(aDotNetImported,dn_cNamespace) = 0
				dnImport(dn_cNamespace)
				dn_cClass = aDotNetClassMap[dn_aParts[dn_x]]
			ok
		ok
		if dn_cClass != ""
			return "dotnetnew_" + dn_cClass
		ok
	next
	return "-"

# The .NET null: oPictureBox.Image = dnNull()
func dnNull
	return new DotNetObject(0)

# A byte buffer that .NET can fill: oBuffer = dnBuffer(1024) makes a byte[] of 1024 bytes, dnBuffer("bytes") one with the bytes of a text.
# A byte[] that .NET returns is a Ring text (a copy), and a Ring text passed in is a new array, so a method that FILLS an array
# (Stream.Read, Socket.Receive...) needs this object: pass it as the byte[] parameter and read what was written with dnBufferBytes.
#   n = oStream.Read(oBuffer,0,1024)         cBytes = dnBufferBytes(oBuffer,n)
func dnBuffer  xSizeOrBytes
	return dnNew("RingDotNet.ByteBuffer",[xSizeOrBytes])

# The first nCount bytes of a buffer as a Ring text (use the number that Read or Receive returned; dnBufferSize(oBuffer) for all of them)
func dnBufferBytes  oBuffer, nCount
	return oBuffer.callMethod("GetBytes",[nCount])

# The size of a buffer in bytes
func dnBufferSize  oBuffer
	return oBuffer.getProp("Length")

# Use ASP.NET Core (adds the ASP.NET runtime and loads the web server of RingDotNet). Call it before any other .NET call.
func dnUseWeb
	dotnet_start("web")
	cDotNetMode = "web"
	dnLoad(dnRequest("bridgefolder",[]) + "/RingDotNet.Web.dll")
	return 1

# Windows Forms / WPF and ASP.NET Core together (using { } starts it when the names of both are used). Call it before any other .NET call.
func dnUseAll
	dotnet_start("all")
	cDotNetMode = "all"
	dnLoad(dnRequest("bridgefolder",[]) + "/RingDotNet.Web.dll")
	return 1

# Use Entity Framework Core with SQLite (loads the data assembly of RingDotNet and its packages)
func dnUseData
	dnLoad(dnRequest("bridgefolder",[]) + "/RingDotNet.Data.dll")
	return 1

# The checks of a program with a window are kept in a file of their own, so the sample stays a clean program: next to the program, the file
# selftest/<name of the program>.ring defines func selfTest(). When the program runs with --selftest, uiRun() (or wpfRun()) loads that file,
# runs selfTest() once the window is shown, closes the window and prints the result. Returns True when such a file was loaded.
func dnLoadSelfTest
	if len(sysargv) < 2
		return False
	ok
	dn_cScript = substr(sysargv[2],"\\","/")
	dn_nSlash = 0
	for dn_nPos = len(dn_cScript) to 1 step -1
		if dn_cScript[dn_nPos] = "/"
			dn_nSlash = dn_nPos
			exit
		ok
	next
	dn_cFile = left(dn_cScript,dn_nSlash) + "selftest/" + substr(dn_cScript,dn_nSlash + 1)
	if not fexists(dn_cFile)
		return False
	ok
	eval(read(dn_cFile))
	return True
