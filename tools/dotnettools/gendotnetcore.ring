/*
	The code of the Ring class generator (used by gendotnet.ring and wrapassembly.ring)
*/


load "../../libraries/dotnetlib/dotnetlib.ring"

# Ring keywords are not used as method names: a method that has such a name gets "@" at the start (@New, @Load), as C# writes @class
aKeywords = split("if to or and not for foreach new func from next load else see while ok class return but end give bye exit try catch done switch on other off in loop package import private step do again call elseif put get set case def endfunc endclass endpackage endif endfor endwhile endswitch endtry function endfunction break continue this self super main init operator"," ")
# The words that Ring accepts after a dot, as the name of an attribute or a method (o.From = x, o.Set(1)): they keep their names.
# The others (get and or not next end if for new load call put give see ...) are a syntax error there: methods get "@" (o.@Next()), and so do attributes: a property
# called Next is the attribute @Next, read as o.@Next (Ring calls get@Next) and written as o.@Next = x (set@Next).
aMemberOk = split("from to set step in on off other done ok"," ")
aMemberKeywords = []
for cWord in aKeywords
	if find(aMemberOk,cWord) = 0
		aMemberKeywords + cWord
	ok
next
aMemberKeywords + "init"          # init is the constructor of a generated class: a .NET method called Init is @Init (oHmac.@Init(oKey))

# true: the namespaces of the manifest :uses are not loaded together with a namespace (only the namespaces of base classes are):
# a class of another namespace is loaded when an object of it comes back, or when the program names the namespace in using { }
lLazyUses = false

aClassMap = []	# [canonical .NET name, Ring class name]
aTaken = []	# [lowercase Ring class name, .NET name]
aRenamed = []	# [class name, Ring class name given because of a clash]
aDelegateDefinitions = []	# [a generic definition, is it a delegate type]
aExtMap = []	# [.NET name of an extended type, [the extension methods as methods of that type]]
cClassPrefix = ""	# :prefix of the namespace being resolved (used for names that are already taken)
cLastRegister = ""
aPlanCache = []	# [.NET type name, plan] (see buildPlan)
lTypedGeneric = false	# true while the members of a generic definition (List`1) are described: a type parameter (T) is typed by the bridge on the real type of the object
aFolderNamespaces = []          # the namespaces that other assemblies already have in the output folder (wrapassembly): a base class there is derived from
aWantedNamespaces = []          # the namespaces of this run (empty: all of them): a base class in another namespace is not imported, it is not generated

# Value of an optional key of a manifest entry
func optValue aEntry, cKey, xDefault
	nPos = find(aEntry,cKey,1)
	if nPos > 0
		return aEntry[nPos][2]
	ok
	return xDefault

# Types of a namespace: [namespace, [[.NET name, Ring class, init parameters (-1 = automatic)], ...]]
func resolveNamespace aEntry
	cNs = aEntry[:namespace]
	cClassPrefix = optValue(aEntry,"prefix","")
	aAssemblies = optValue(aEntry,"assemblies",["System.Private.CoreLib"])
	aExclude = optValue(aEntry,"exclude",[])
	aOut = []
	aNamed = []          # the types of the manifest with a name of their own: :all does not add them again under another name
	aListedTypes = optValue(aEntry,"types",[])
	for aListed in aListedTypes
		aNamed + aListed[1]
	next
	if optValue(aEntry,"all",false)
		aListedNames = dnRequest("listtypes",dnJoin([cNs],aAssemblies))
		for cName in aListedNames
			if find(aExclude,cName) = 0 and find(aNamed,cName) = 0
				aOut + [cName,"",-1,cName]
			ok
		next
	ok
	aTypes = optValue(aEntry,"types",[])
	for aType in aTypes
		cRing = ""
		nInit = -1
		if len(aType) >= 2 cRing = aType[2] ok
		if len(aType) >= 3 nInit = aType[3] ok
		aOut + [aType[1],cRing,nInit,aType[1]]
	next
	aResult = []
	for aType in aOut
		cCanonical = aType[1]
		if substr(aType[1],"`")
			cCanonical = dnDescribe(aType[1])[1]
		ok
		cRing = aType[2]
		if cRing = ""
			cRing = className(cCanonical,cNs)
		ok
		if substr(cCanonical,"`") and not substr(cCanonical,"[")
			# a generic definition whose name another type has (ValueTuple, ValueTuple`2): the number of type arguments follows the name
			nTaken = find(aTaken,lower(cRing),1)
			if nTaken > 0 and aTaken[nTaken][2] != cCanonical
				# the number after the last backtick (a nested generic type has one for each type around it: StateMachine`2+TriggerWithParameters`3)
				nTick = 0
				for x = len(cCanonical) to 1 step -1
					if cCanonical[x] = "`"
						nTick = x
						exit
					ok
				next
				cArity = ""
				for x = nTick + 1 to len(cCanonical)
					if isdigit(cCanonical[x])
						cArity += cCanonical[x]
					else
						exit
					ok
				next
				cRing += cArity
			ok
		ok
		cRing = uniqueClassName(cRing,cCanonical,cNs)
		nPos = find(aClassMap,cCanonical,1)
		if nPos = 0
			aClassMap + [cCanonical,cRing,cNs]
		ok
		# an explicit entry replaces the automatic one of the same type
		lDup = false
		for x = 1 to len(aResult)
			if aResult[x][4] = cCanonical
				aResult[x] = [aType[1],cRing,aType[3],cCanonical]
				lDup = true
			ok
		next
		if not lDup
			aResult + [aType[1],cRing,aType[3],cCanonical]
		ok
	next
	return [cNs,aResult,optValue(aEntry,"extra",[]),optValue(aEntry,"uses",[])]

# Short class name of a .NET type name
func className cName, cNs
	cShort = cName
	if substr(cName,"+") > 0 and not substr(cName,"[")
		# a nested type: the names of the types around it come first (SqlMapper+GridReader is SqlMapperGridReader, List`1+Enumerator is ListEnumerator)
		cShort = cName
		for x = len(cShort) to 1 step -1
			if cShort[x] = "."
				cShort = substr(cShort,x + 1)
				exit
			ok
		next
		aParts = str2list(substr(cShort,"+",nl))
		cJoined = ""
		for cPart in aParts
			nTick = substr(cPart,"`")
			if nTick > 0
				cPart = left(cPart,nTick - 1)
			ok
			cJoined += cPart
		next
		return cJoined
	ok
	nPos = substr(cShort,"`")
	if nPos > 0
		cShort = left(cShort,nPos - 1)
	ok
	for x = len(cShort) to 1 step -1
		if cShort[x] = "." or cShort[x] = "+"
			cShort = substr(cShort,x + 1)
			exit
		ok
	next
	return cShort

# A class name that is not used by another type (keywords get "_", clashes get the namespace as a prefix)
func uniqueClassName cRing, cCanonical, cNs
	cOriginal = cRing
	if find(aKeywords,lower(cRing)) > 0 or find(["dotnetobject","dotnetcallback"],lower(cRing)) > 0
		cRing += "_"
	ok
	nPos = find(aTaken,lower(cRing),1)
	if nPos > 0 and aTaken[nPos][2] != cCanonical
		cPrefix = cNs
		for x = len(cPrefix) to 1 step -1
			if cPrefix[x] = "."
				cPrefix = substr(cPrefix,x + 1)
				exit
			ok
		next
		if cClassPrefix != ""
			cPrefix = cClassPrefix
		ok
		cRing = cPrefix + cRing
		nPos = find(aTaken,lower(cRing),1)
		if nPos > 0 and aTaken[nPos][2] != cCanonical
			cRing += "_"
		ok
		aRenamed + [cNs + "." + cOriginal,cRing,cOriginal]
	ok
	if find(aTaken,lower(cRing),1) = 0
		aTaken + [lower(cRing),cCanonical]
	ok
	return cRing

func genNamespace aItem
	cNs = aItem[1]
	? "Namespace " + cNs + " (" + len(aItem[2]) + " types)"
	# parents first: a class is loaded after its base class (the base can be in another namespace, which is imported first)
	aOrdered = []
	aPending = aItem[2]
	aBaseNamespaces = []
	nGuard = 0
	while len(aPending) > 0 and nGuard < 100000
		nGuard++
		aStill = []
		for aType in aPending
			cBase = ""
			try
				cBase = buildPlan(aType[1],aType[3])[8]
			catch
				cBase = ""
			done
			lWait = false
			for aOther in aPending
				if aOther[4] = cBase and aOther[4] != aType[4]
					lWait = true
				ok
			next
			if lWait
				aStill + aType
			else
				aOrdered + aType
			ok
		next
		if len(aStill) = len(aPending)
			for aType in aStill
				aOrdered + aType
			next
			aStill = []
		ok
		aPending = aStill
	end
	# the registrations go in the loader, before the files (a statement at the top of a class file would end up inside the previous class)
	cReg = ""
	cList = ""
	cFactories = ""	# the functions DotNetNew_<Class>: a function after a class would become a method of it, so they all come first
	cClasses = ""	# the classes, parents first
	for aType in aOrdered
		try
			cCode = genClass(aType[1],aType[2],aType[3])
			nClass = substr(cCode,nl + "Class ")
			if nClass = 0
				raise("no class in the generated code")
			ok
			cFactories += left(cCode,nClass) + nl
			cClasses += substr(cCode,nClass + 1) + nl
			cReg += cLastRegister
			cBase = buildPlan(aType[1],aType[3])[8]
			nBase = find(aClassMap,cBase,1)
			if cBase != "" and nBase > 0
				if aClassMap[nBase][3] != cNs and find(aBaseNamespaces,aClassMap[nBase][3]) = 0 and (len(aWantedNamespaces) = 0 or find(aWantedNamespaces,aClassMap[nBase][3]) > 0 or find(aFolderNamespaces,aClassMap[nBase][3]) > 0)
					aBaseNamespaces + aClassMap[nBase][3]
				ok
			ok
		catch
			? "  skipped " + aType[1] + ": " + cCatchError
		done
	next
	for cExtra in aItem[3]
		cList += 'load "' + cExtra + '"' + nl
	next
	# namespaces of the base classes come first, then the ones this namespace usually returns
	cUses = ""
	for cUse in aBaseNamespaces
		cUses += 'dnImport("' + cUse + '")' + nl
	next
	for cUse in aItem[4]
		if find(aBaseNamespaces,cUse) = 0 and not lLazyUses
			cUses += 'dnImport("' + cUse + '")' + nl
		ok
	next
	# two files per namespace: the loader (statements: imports, registrations, extra files) and the classes (functions and classes only).
	# One big file instead of one file for each class: loading and installing thousands of small files is slow.
	write(C_OUTDIR + cNs + ".classes.ring","# Generated by tools/dotnettools/gendotnet.ring: the classes of " + cNs + nl + cFactories + cClasses)
	write(C_OUTDIR + cNs + ".ring","# Generated by tools/dotnettools/gendotnet.ring: the classes of " + cNs + nl + cUses + cReg + 'load "' + cNs + '.classes.ring"' + nl + cList)

func makedir cPath
	if iswindows()
		system('mkdir "' + substr(cPath,"/","\\") + '" 2>nul')
	else
		system('mkdir -p "' + cPath + '"')
	ok

func split cText, cSep
	return str2list(substr(cText,cSep,nl))

# "@" for a member whose name is a word of Ring that is not accepted after a dot (Next, End, New...), else ""
func memberAt cName
	if find(aMemberKeywords,lower(cName)) > 0 and lower(cName) != "init"
		return "@"
	ok
	return ""

func ringName cName
	if find(aMemberKeywords,lower(cName)) > 0
		return "@" + cName
	ok
	return cName

# Parameter list: P1,P2,...
func paraList nCount
	cList = ""
	for x = 1 to nCount
		if x > 1 cList += "," ok
		cList += "P" + x
	next
	return cList

# Statement that returns the result of a call (the bridge result is wrapped by the runtime type, see dnWrapObject).
# A text, a number or a yes/no is read in C; an answer that is anything else (a null text, an object) is finished with dnFinish, because the declared
# type is not enough for a method: the bridge chooses the overload from the real object, and a class derived from the declared one can add an overload
# with another kind of answer. (propertyReturnCode is the one case where the declared type is trusted.)
func returnCode cRequest, cReturnType, nByRef
	if nByRef = 0 and cReturnType = "System.Void"
		return nativeCall(cRequest,"void") + nl + "		return self" + nl
	but nByRef = 0 and isPrimitiveType(cReturnType)
		return nativeCall(cRequest,"value")
	but nByRef = 0
		return objectReturnCode(cRequest)
	ok
	return "return " + sendCall(cRequest) + nl

# An indexer of numbers, yes/nos and texts (List<string>[int], Dictionary<string,int>[string]): get_Item and set_Item are methods, called by the typed
# functions like any method; the bridge decides on the real type, and a type with several indexers (several get_Item that take one argument) is the
# generic request's.
func isTypedIndexer aIndexer
	return isTypedValue(aIndexer[1]) and isTypedValue(aIndexer[2])

# The types that the typed functions pass: a number, a yes/no or a text; and, in a generic definition (List`1), a type parameter (T, TKey): the bridge decides on the real
# type of the object (List<string> takes a text, List<object> and any other type is the generic request's, which the extension makes itself).
func isTypedValue cType
	if find(["System.Int32","System.Int64","System.Double","System.Boolean","System.String","System.UInt32","System.Int16","System.UInt16","System.Byte","System.SByte","System.UInt64","System.Single"],cType) > 0
		return true
	ok
	return lTypedGeneric and isTypeParameter(cType)

# A type parameter of a generic definition: the bridge describes the definition as a type of System.Object (List<object>: T is System.Object), and a name with no
# namespace (T, TKey) is one too. A member that really has an object is safe as well: the bridge finds no typed call for an object and the generic request makes the call.
func isTypeParameter cType
	if cType = "System.Object"
		return true
	ok
	if cType = "" or substr(cType,".") or substr(cType,"`") or substr(cType,"[") or substr(cType,"+") or substr(cType,"&") or substr(cType,"*")
		return false
	ok
	return true

func typedIndexerGetCode
	return 'return dnAnswer(dotnet_callt(nHandle,"get_Item",P1))' + nl

# An instance method of at most 8 parameters of a number, a yes/no or a text, with an answer of a number, a yes/no, a text or nothing: the extension calls it
# without a request text (dotnet_callt, dotnet_calltv). The bridge decides on the real type of the object: it calls the method directly only when it is the only
# one of that name that can take these arguments, and the arguments convert exactly; otherwise the extension makes the generic request itself.
func isTypedMethod aRec
	return isTypedCall(aRec,false)

# The same for a static method: dotnet_callts (the type name replaces the handle) calls it without a request text
func isTypedStaticMethod aRec
	return isTypedCall(aRec,true)

func isTypedCall aRec, lStatic
	if (aRec[2] != lStatic) or aRec[5] > 0 or len(aRec[4]) > 8
		return false
	ok
	if aRec[3] != "System.Void" and not isPrimitiveType(aRec[3]) and not (lTypedGeneric and isTypeParameter(aRec[3]))
		return false
	ok
	for cParam in aRec[4]
		if not isTypedValue(cParam)
			return false
		ok
	next
	return true

func typedMethodCode cName, nArity, cReturnType, lNotNull
	cArgs = ""
	for x = 1 to nArity
		cArgs += ",P" + x
	next
	if cReturnType = "System.Void"
		return 'dotnet_calltv(nHandle,"' + cName + '"' + cArgs + ')' + nl + "		return self" + nl
	ok
	if lNotNull and cReturnType = "System.String"
		# a text that is declared never null: the bridge answers an empty text for a null, so there is no null to look for
		return 'return dotnet_callt(nHandle,"' + cName + '"' + cArgs + ')' + nl
	ok
	return 'return dnAnswer(dotnet_callt(nHandle,"' + cName + '"' + cArgs + '))' + nl

func typedStaticMethodCode cType, cName, nArity, cReturnType, lNotNull
	cArgs = ""
	for x = 1 to nArity
		cArgs += ",P" + x
	next
	if cReturnType = "System.Void"
		return "dotnet_calltsv('" + cType + "','" + cName + "'" + cArgs + ")" + nl + "		return self" + nl
	ok
	if lNotNull and cReturnType = "System.String"
		return "return dotnet_callts('" + cType + "','" + cName + "'" + cArgs + ")" + nl
	ok
	return "return dnAnswer(dotnet_callts('" + cType + "','" + cName + "'" + cArgs + "))" + nl

# The getter of an instance property or field of a number, a yes/no or a text: dotnet_getp (ring_dotnet.c) reads it without a request text. The bridge
# answers the value, or asks for the generic request (the property is of another kind on the real type, the handle is not valid...), which the extension
# makes itself, so every answer and every error is the one of the generic call. A text can be null: the marker list is finished by dnFinish.
func typedGetterCode cName, cType, lNotNull
	if lNotNull
		# a text (or an enum, read as the text of its name) that is declared never null: the bridge answers an empty text for a null, so there is no null to look for
		return 'return dotnet_getp(nHandle,"' + cName + '")' + nl
	ok
	if cType = "System.String" or not isPrimitiveType(cType)
		return 'return dnAnswer(dotnet_getp(nHandle,"' + cName + '"))' + nl
	ok
	return 'return dotnet_getp(nHandle,"' + cName + '")' + nl

# The setter of such a property: dotnet_setp writes a number or a text, and makes the generic request for any other value or conversion
func typedSetterCode cName
	return 'dotnet_setp(nHandle,"' + cName + '",P1)' + nl

# The same for a static property or field: dotnet_getps and dotnet_setps (ring_dotnet.c) name the type by its text, like dotnet_callts
func typedStaticGetterCode cTypeName, cName, cType, lNotNull
	if lNotNull
		return "return dotnet_getps('" + cTypeName + "','" + cName + "')" + nl
	ok
	if cType = "System.String" or not isPrimitiveType(cType)
		return "return dnAnswer(dotnet_getps('" + cTypeName + "','" + cName + "'))" + nl
	ok
	return "return dotnet_getps('" + cTypeName + "','" + cName + "')" + nl

func typedStaticSetterCode cTypeName, cName
	return "dotnet_setps('" + cTypeName + "','" + cName + "',P1)" + nl

# The statement that returns the value of a property. A property has no overloads, so its declared type is what it answers: a number or a yes/no is
# returned as it is, with nothing to finish. (The indexer is not a property: it is described by the first indexer that .NET lists, which is not always
# the one that is called, so it uses returnCode.)
func propertyReturnCode cRequest, cReturnType
	if isPrimitiveType(cReturnType) and cReturnType != "System.String"
		return nativeCall(cRequest,"number")
	ok
	return returnCode(cRequest,cReturnType,0)

# Types whose answers the extension reads itself (a text, a number or a yes/no): dotnet_call returns them as Ring values
func isPrimitiveType cType
	return find(["System.String","System.Boolean","System.Byte","System.SByte","System.Int16","System.UInt16","System.Int32","System.UInt32","System.Int64","System.UInt64","System.Single","System.Double","System.Decimal"],cType) > 0

# The same request with the native functions (ring_dotnet.c): dotnet_call (an answer that is a text, a number or a yes/no), dotnet_callv (nothing)
# and dotnet_callo (an object) pack the request and read the answer in C.
#   "call",[new DotNetObject(nHandle),"Contains",P1]  -->  dotnet_call("s4:call",nHandle,"s8:Contains",P1)
func nativeCall cRequest, cMode
	aParts = requestParts(cRequest)
	cNative = aParts[1] + "," + aParts[5] + "," + aParts[3]
	for cArg in aParts[4]
		cNative += "," + cArg
	next
	switch cMode
	on "void"
		return "dotnet_callv(" + cNative + ")" + nl
	on "object"
		return "dotnet_callo(" + cNative + ")"
	on "any"
		return "dn_x = dotnet_calla(" + cNative + ")" + nl + "		if islist(dn_x) return dnAny(dn_x) ok" + nl + "		return dn_x" + nl
	on "number"
		# a number or a yes/no (not a text): the answer is never null, so there is nothing to finish in Ring
		return "return dotnet_call(" + cNative + ")" + nl
	off
	# a text, a number or a yes/no: any other answer (null...) comes back as a list that dnFinish reads
	return "dn_x = dotnet_call(" + cNative + ")" + nl + "		if islist(dn_x) return dnFinish(dn_x[2]) ok" + nl + "		return dn_x" + nl

# The statements that return the object that a call answers. A call on an object ("call" with the handle of the object) asks the extension with the operation "calls":
# when the method answered the object itself (StringBuilder.Append, every fluent method), the answer is -1 and the method returns self, so no new wrapper is made
# (and no new handle: the wrapper of the receiver is the answer). Any other object is wrapped by dnObj, as before.
func objectReturnCode cRequest
	cCall = nativeCall(cRequest,"object")
	cPrefix = 'dotnet_callo("s4:call",nHandle,'
	if left(cCall,len(cPrefix)) = cPrefix
		cCall = 'dotnet_callo("s5:calls",nHandle,' + right(cCall,len(cCall) - len(cPrefix))
		return "dn_x = " + cCall + nl + "		if isnumber(dn_x) and dn_x = -1" + nl + "			return self" + nl + "		ok" + nl + "		return dnObj(dn_x)" + nl
	ok
	return "return dnObj(" + cCall + ")" + nl

# The code of a request for a member of an object. The generated method does not make the target object and the list of the request:
# it passes the handle as a number and the pieces that never change (the operation and the name) as ready wire items, so that the
# request is one text that dnSend finishes. Written for the request text of this generator:  "call",[TARGET,"Name",P1,P2]
#   "call",[new DotNetObject(nHandle),"Append",P1]   -->   dnSend("s4:call",nHandle,"s6:Append",dnPackItem(P1))
func sendCall cRequest
	aParts = requestParts(cRequest)
	cArgs = '""'
	if len(aParts[4]) > 0
		cArgs = ""
		for cArg in aParts[4]
			if len(cArgs) > 0
				cArgs += " + "
			ok
			cArgs += "dnPackItem(" + cArg + ")"
		next
	ok
	return "dnSend(" + aParts[1] + "," + aParts[2] + "," + aParts[3] + "," + cArgs + ")"

# The pieces of a request text:  [operation item, handle expression, name item, [argument names], handle expression for the native call]
func requestParts cRequest
	nOpEnd = substr(cRequest,'",[')
	cOperation = substr(cRequest,2,nOpEnd - 2)
	cRest = right(cRequest,len(cRequest) - nOpEnd - 2)
	nTargetEnd = substr(cRest,',"')
	cTarget = left(cRest,nTargetEnd - 1)
	cRest = right(cRest,len(cRest) - nTargetEnd - 1)
	nNameEnd = substr(cRest,'"')
	cName = left(cRest,nNameEnd - 1)
	cTail = right(cRest,len(cRest) - nNameEnd)
	cTail = left(cTail,len(cTail) - 1)
	cHandle = "nHandle"
	cNativeHandle = "nHandle"
	if left(cTarget,13) = "dnTypeCached("
		cHandle = "dnTypeHandle(" + right(cTarget,len(cTarget) - 13)          # dnTypeCached('X')  -->  dnTypeHandle('X')
		cNativeHandle = right(cTarget,len(cTarget) - 13)                       # the extension finds the handle of the type by its name
		cNativeHandle = left(cNativeHandle,len(cNativeHandle) - 1)
	ok
	aArgs = []
	if len(cTail) > 0
		aArgs = str2list(substr(right(cTail,len(cTail) - 1),",",nl))
	ok
	return ['"s' + len(cOperation) + ":" + cOperation + '"',cHandle,'"s' + len(cName) + ":" + cName + '"',aArgs,cNativeHandle]

# The plan of a type: everything the generated class needs, as text blocks keyed by Ring method name.
# [aInfo, qualified type name, init parameters, can init create, constructors text, [attribute lower, attribute], blocks, base type, attribute names]
func buildPlan cTypeName, nForceInit
	nCached = find(aPlanCache,cTypeName,1)
	if nCached > 0 and nForceInit < 0
		return aPlanCache[nCached][2]
	ok
	cOriginalName = cTypeName
	aInfo = dnDescribe(cTypeName)
	cTypeName = aInfo[1] + ", " + aInfo[9]	# assembly qualified: the type may live in an assembly that is not named after its namespace
	lStatic = aInfo[2]
	aCtors = aInfo[3]
	aMethods = aInfo[4]
	aMembers = aInfo[5]
	# compiler generated members of records and the like (<Clone>$) have names that are not Ring identifiers
	aGood = []
	for aMethod in aMethods
		if isIdent(aMethod[1])
			aGood + aMethod
		ok
	next
	aMethods = aGood
	# the extension methods of this type. An extension method never changes the Ring signature of a method that the type already has:
	# when the type has a method with the same name (an overloaded name is one Ring method with the parameters of the longest overload),
	# the extension is added only when its number of parameters is one that the method already takes, and then without shorter forms.
	aExtTargets = [aInfo[1]]          # the type, and the interfaces that it implements and its base class does not
	if len(aInfo) >= 11
		for cInterface in aInfo[11]
			aExtTargets + cInterface
		next
	ok
	for cExtTarget in aExtTargets
	nExtPos = find(aExtMap,cExtTarget,1)
	if nExtPos > 0
		aMemberNames = []
		for aMember in aMembers
			aMemberNames + lower(aMember[1])
		next
		for aExt in aExtMap[nExtPos][2]
			lAdd = true
			# a property or field of the type with the same name keeps its attribute: the extension method would replace it
			if find(aMemberNames,lower(aExt[1])) > 0
				lAdd = false
			ok
			nLen = len(aExt[4])
			lSameName = false
			lCovered = false
			for aMethod in aMethods
				lInjected = len(aMethod) >= 7 and isstring(aMethod[7])          # an extension method that was added: only the methods of the type count
				if lInjected
					loop
				but lower(aMethod[1]) = lower(aExt[1])
					lSameName = true
					if aMethod[6] <= nLen and nLen <= len(aMethod[4])
						lCovered = true
					ok
					if (not aMethod[2]) and len(aMethod[4]) = nLen
						lSame = true
						for nParam = 1 to nLen
							if aMethod[4][nParam] != aExt[4][nParam]
								lSame = false
							ok
						next
						if lSame lAdd = false ok
					ok
				ok
			next
			if lSameName and not lCovered
				lAdd = false
			ok
			if lAdd
				if lSameName
					aMethods + [aExt[1],false,aExt[3],aExt[4],aExt[5],nLen]          # a name of the type: found by the bridge when the assembly is loaded
				else
					aMethods + aExt
				ok
			ok
		next
	ok
	next
	aGood = []
	for aMember in aMembers
		if isIdent(aMember[1])
			aGood + aMember
		ok
	next
	aMembers = aGood
	# a method with optional parameters is also available with fewer parameters (down to the required ones)
	aExpanded = []
	for aMethod in aMethods
		aExpanded + aMethod
		for nCut = len(aMethod[4]) - 1 to aMethod[6] step -1
			aShort = []
			for nType = 1 to nCut
				aShort + aMethod[4][nType]
			next
			if len(aMethod) >= 7
				aExpanded + [aMethod[1],aMethod[2],aMethod[3],aShort,aMethod[5],aMethod[6],aMethod[7]]
			else
				aExpanded + [aMethod[1],aMethod[2],aMethod[3],aShort,aMethod[5],aMethod[6]]
			ok
		next
	next
	aMethods = aExpanded
	cReserved = "|callmethod|getprop|setprop|typename|tolist|release|isnull|"

	aBlocks = []	# [Ring name (lower case), text]
	cB = ""
	nInit = -1	# parameterless init() when the type has such a constructor, else the shortest constructor
	for aCtor in aCtors
		if (nInit = -1) or (len(aCtor) < nInit)
			nInit = len(aCtor)
		ok
	next
	if aInfo[8]
		nInit = 0	# structs: init() makes the default value, the other constructors are @New
	ok
	if nForceInit >= 0
		nInit = nForceInit
	ok
	# no constructor with that many parameters: init() only wraps (the class is used for its static members)
	lCreate = (nInit = 0) and aInfo[8]	# structs always have a parameterless constructor
	for aCtor in aCtors
		if len(aCtor) = nInit
			lCreate = true
		ok
	next
	# A generic definition (List`1): init takes the named list that has the type arguments, new List([ :typeArguments = ["System.String"] ]),
	# and the constructor parameters by name in the same list. The object it wraps can be of any closed type of the definition.
	lGenericDef = substr(aInfo[1],"`") > 0 and not substr(aInfo[1],"[")
	lTypedGeneric = lGenericDef
	if lGenericDef
		nInit = 1
		lCreate = false
	ok
	# Properties and fields become attributes, so that oObj.Text = "x" calls setText() and oObj.Text calls getText()
	aMethodNames = ["init","nhandle"]
	for aMethod in aMethods
		aMethodNames + lower(aMethod[1])
	next
	aAttrs = []
	aAttrList = []
	for aMember in aMembers
		cLowerName = lower(aMember[1])
		if (find(aMethodNames,cLowerName) = 0) and (find(aAttrs,cLowerName) = 0) and (not substr(cReserved,"|" + cLowerName + "|"))
			aAttrs + cLowerName
			aAttrList + [cLowerName,memberAt(aMember[1]) + aMember[1]]
		ok
	next
	cCode = ""

	# The code of the class body runs for "new X" (no parentheses, so no call to init) and for "new X()": it makes the default object
	# (only for this class: a class that inherits from it, like a user class, has its own init). init then keeps it.
	# When init takes one parameter (forced by the manifest, so that new StringBuilder("text") works) and the type also has a
	# parameterless constructor, new X(value) makes the default object too, and init replaces it (an extra object, only for a few classes).
	lDefaultRegion = false
	if lCreate and nInit = 0
		lDefaultRegion = true
	ok
	if lCreate and nInit = 1
		for aCtor in aCtors
			if len(aCtor) = 0
				lDefaultRegion = true
				exit
			ok
		next
	ok
	if lDefaultRegion
		cCode += "	if nDotNetWrapHandle = 0 and nHandle = 0 and lower(classname(self)) = '%CLASS%'          # new X without parentheses: the default object" + nl
		# (a method makes the object and its guard: a managed pointer that is assigned directly in the class body is never freed by Ring)
		cCode += "		dnDefaultObject('" + cTypeName + "')" + nl
		cCode += "	ok" + nl + nl
	ok

	# Constructors: init uses the overload with fewer parameters, @New the others
	cCode += "	Func init " + paraList(maxz(nInit)) + nl
	cCode += "		if nDotNetWrapHandle != 0" + nl
	cCode += "			nHandle = nDotNetWrapHandle" + nl
	cCode += "			nDotNetWrapHandle = 0" + nl
	cCode += "			oDotNetGuard = dotnet_guard(nHandle)          # this object owns the handle: it is released when the last copy is gone" + nl
	cCode += "			return self" + nl
	cCode += "		ok" + nl
	if lCreate and lDefaultRegion and nInit = 0
		cCode += "		if nHandle != 0          # made by the class body" + nl
		cCode += "			return self" + nl
		cCode += "		ok" + nl
	ok
	if lGenericDef
		cCode += "		if dotnet_isnamed(P1)" + nl
		cCode += "			nHandle = dnCreateNamed('" + cTypeName + "',P1)" + nl
		cCode += "			oDotNetGuard = dotnet_guard(nHandle)" + nl
		cCode += "		ok" + nl
	ok
	if lCreate
		# init has one parameter and the type also has a parameterless constructor: init(NULL) (an empty text) calls that one
		for aCtor in aCtors
			if (nInit = 1) and (len(aCtor) = 0)
				cCode += "		if isstring(P1) and P1 = " + '""' + nl
				cCode += "			if nHandle = 0" + nl
				cCode += "				nHandle = dnCreate('" + cTypeName + "',[])" + nl
				cCode += "				oDotNetGuard = dotnet_guard(nHandle)" + nl
				cCode += "			ok" + nl
				cCode += "			return self" + nl
				cCode += "		ok" + nl
				exit
			ok
		next
		if lDefaultRegion
		ok
		cCode += "		nHandle = dnCreate('" + cTypeName + "',[" + paraList(nInit) + "])" + nl
		cCode += "		oDotNetGuard = dotnet_guard(nHandle)" + nl
	ok
	cCode += "		return self" + nl + nl
	# The other constructors: ONE method @New that takes one parameter, like the methods with overloads:
	# @New(NULL) calls the parameterless constructor, @New([ :param = value ]) chooses the constructor by the parameter names,
	# @New(value) calls the constructor with one parameter. Example: new WpfBinding().@New([ :path = "Value" ])  (New is a Ring keyword, so the method is @New)
	lOtherCtor = false
	for aCtor in aCtors
		if len(aCtor) != nInit and not lGenericDef
			lOtherCtor = true
		ok
	next
	if lOtherCtor
		cCode += "	Func @New P1" + nl
		if lDefaultRegion
			cCode += "		nHandle = 0          # the default object made for the class body is not needed: its guard is dropped when oDotNetGuard gets a new one, and the handle is released in a group" + nl
		ok
		cCode += "		if dotnet_isnamed(P1)" + nl
		cCode += "			nHandle = dnCreateNamed('" + cTypeName + "',P1)" + nl
		cCode += "			oDotNetGuard = dotnet_guard(nHandle)" + nl
		cCode += "			return self" + nl
		cCode += "		ok" + nl
		cCode += "		if isstring(P1) and P1 = " + '""' + nl
		cCode += "			nHandle = dnCreate('" + cTypeName + "',[])" + nl
		cCode += "			oDotNetGuard = dotnet_guard(nHandle)" + nl
		cCode += "			return self" + nl
		cCode += "		ok" + nl
		cCode += "		nHandle = dnCreate('" + cTypeName + "',[P1])" + nl
		cCode += "		oDotNetGuard = dotnet_guard(nHandle)" + nl
		cCode += "		return self" + nl + nl
	ok

	# Methods: the overload with the fewest parameters gets the plain name, others get Name_N
	# names that exist both as static and as instance methods (same number of parameters)
	aBoth = []
	aStaticSeen = []
	aInstanceSeen = []
	for aMethod in aMethods
		cBothKey = lower(aMethod[1]) + "|" + len(aMethod[4])
		if aMethod[2]
			aStaticSeen + cBothKey
		else
			aInstanceSeen + cBothKey
		ok
	next
	for cBothKey in aStaticSeen
		if find(aInstanceSeen,cBothKey) > 0
			aBoth + cBothKey
		ok
	next
	aAccessors = []
	for aMember in aMembers
		if aMember[2] aAccessors + lower("get" + aMember[1]) ok
		if aMember[3] aAccessors + lower("set" + aMember[1]) ok
	next
	aNames = ["init","@new"]	# @New is the method of the constructors with parameters (a .NET method called New is not wrapped: use callMethod)
	aSeen = []	# "static|name|arity"
	# The preferred arity of each name: the shortest overload that has parameters (and no array/delegate/comparer parameters), or 0 when
	# the type has a parameterless form. A name with two or more arities becomes ONE dispatcher method (below): Name(NULL), Name(value),
	# Name([ :param = value ]); the preferred arity is only used for the names that are not dispatchers.
	aMin = []	# [name, preferred arity, is it from a simple overload]
	for aMethod in aMethods
		cKey = lower(aMethod[1])
		nArity = len(aMethod[4])
		lSimple = true
		for cType in aMethod[4]
			if isExoticType(cType)
				lSimple = false
			ok
		next
		nPos = find(aMin,cKey,1)
		if nPos = 0
			aMin + [cKey,nArity,lSimple]
		else
			nOld = aMin[nPos][2]
			lOldSimple = aMin[nPos][3]
			if (lSimple and not lOldSimple) or ((lSimple = lOldSimple) and (rankArity(nArity) < rankArity(nOld)))
				aMin[nPos][2] = nArity
				aMin[nPos][3] = lSimple
			ok
		ok
	next
	# the parameterless form wins when the type has one (Cancel(), Wait(), Reverse()), except for Write*/WriteLine
	for aMethod in aMethods
		if len(aMethod[4]) = 0 and lower(left(aMethod[1],5)) != "write"
			nPos = find(aMin,lower(aMethod[1]),1)
			if nPos > 0
				aMin[nPos][2] = 0
			ok
		ok
	next
	# ToString() keeps its parameterless form when the type has one
	for aMethod in aMethods
		if lower(aMethod[1]) = "tostring" and len(aMethod[4]) = 0
			aMin[find(aMin,"tostring",1)][2] = 0
		ok
	next
	for aMethod in aMethods
		cName = aMethod[1]
		nArity = len(aMethod[4])
		cLower = lower(cName)
		if substr(cReserved,"|" + cLower + "|")
			loop
		ok
		# A name with overloads of different arities is ONE method that takes one parameter: Name(NULL) calls the parameterless
		# overload, Name([ :param = value ]) chooses the overload by the parameter names, Name(value) calls the overload with one parameter.
		# (No Name_1, Name_2... methods. ToString keeps its parameterless form; its other forms are Format([ :format = "..." ]).)
		cDispatch = ringName(cName)
		if cLower = "tostring"
			cDispatch = "Format"
		ok
		# getX()/setX() of a property or field are used by Ring for oObject.X: a method with that name (Array.GetLength(i) vs Length,
		# GetType(name) vs Type) gets "@" at the start instead
		if find(aAccessors,lower(cDispatch)) > 0
			cDispatch = "@" + cName
		ok
		if find(["tolist","release","isnull","typename","getprop","setprop","callmethod"],cLower) = 0
			aFamilyAll = familyInfo(aMethods,cLower)
			if cLower = "tostring"
				# only the forms with parameters go to Format
				aFormArities = []
				for nFormArity in aFamilyAll[1]
					if nFormArity > 0
						aFormArities + nFormArity
					ok
				next
				lHasFormat = false	# a class with its own method called Format (String.Format) keeps it
				for aOther in aMethods
					if lower(aOther[1]) = "format"
						lHasFormat = true
					ok
				next
				if len(aFormArities) > 0 and not lHasFormat and find(aNames,"format") = 0 and not substr(cReserved,"|format|")
					aNames + "format"
					aBlocks + ["format",dispatcherBlock("Format",cName,cTypeName,aMethods,[aFormArities,aFamilyAll[2],aFamilyAll[3]])]
				ok
			but len(aFamilyAll[1]) >= 2 or needsTypeArguments(aMethods,cLower)
				if find(aNames,lower(cDispatch)) = 0
					aNames + lower(cDispatch)
					aBlocks + [lower(cDispatch),dispatcherBlock(cDispatch,cName,cTypeName,aMethods,aFamilyAll)]
				ok
				loop
			ok
		ok
		cKey = "" + aMethod[2] + "|" + cLower + "|" + nArity
		if find(aSeen,cKey) > 0
			loop
		ok
		aSeen + cKey
		cRing = ringName(cName)
		if cLower = "tostring" and nArity > 0 and find(aAccessors,"format") = 0
			loop	# the forms of ToString with parameters are the method Format (above)
		but nArity != aMin[find(aMin,cLower,1)][2]
			cRing = cName + "_" + nArity
		ok
		# getX()/setX() of a property or field are used by Ring for oObject.X: a method with that name (Array.GetLength(i) vs Length) is renamed
		if find(aAccessors,lower(cRing)) > 0
			cRing = "@" + cName
		ok
		if find(aNames,lower(cRing)) > 0
			loop
		ok
		aNames + lower(cRing)
		# A method with overloads of different arities whose plain form takes 0 or 1 parameter becomes a dispatcher:
		# Name(NULL) calls the parameterless overload, Name([ :param = value ]) chooses the overload by the parameter names,
		# Name(value) calls the overload with one parameter
		nPlainArity = aMin[find(aMin,cLower,1)][2]
		# (names that DotNetObject already has - ToString, ToList... - keep their plain form)
		if cRing = ringName(cName) and nArity = nPlainArity and nPlainArity <= 1 and find(["tostring","tolist","release","isnull","typename","getprop","setprop","callmethod"],cLower) = 0
			aFamily = familyInfo(aMethods,cLower)
			if len(aFamily[1]) >= 2
				aBlocks + [lower(cRing),dispatcherBlock(cRing,cName,cTypeName,aMethods,aFamily)]
				loop
			ok
		ok
		if aMethod[2]
			cTarget = "dnTypeCached('" + cTypeName + "')"
		else
			cTarget = "new DotNetObject(nHandle)"
		ok
		cReq = '"call",[' + cTarget + ',"' + cName + '"'
		if nArity > 0
			cReq += "," + paraList(nArity)
		ok
		cReq += "]"
		cB = "	Func " + cRing + " " + paraList(nArity) + nl
		cHint = extensionHint(aMethods,cName)
		if cHint != ""
			cB += '		dnEnsureExt("' + cHint + '")' + nl
		ok
		if find(aBoth,cLower + "|" + nArity) > 0
			# a static and an instance method with the same name: a class used without an object (nHandle = 0) calls the static one
			aStaticRec = aMethod
			aInstanceRec = aMethod
			for aRec in aMethods
				if lower(aRec[1]) = cLower and len(aRec[4]) = nArity
					if aRec[2]
						aStaticRec = aRec
					else
						aInstanceRec = aRec
					ok
				ok
			next
			cStaticReq = '"call",[dnTypeCached(' + "'" + cTypeName + "'" + '),"' + cName + '"'
			if nArity > 0
				cStaticReq += "," + paraList(nArity)
			ok
			cStaticReq += "]"
			cB += "		if nHandle = 0" + nl
			cB += "			" + returnCode(cStaticReq,aStaticRec[3],aStaticRec[5])
			cB += "		ok" + nl
			cReq = '"call",[new DotNetObject(nHandle),"' + cName + '"'
			if nArity > 0
				cReq += "," + paraList(nArity)
			ok
			cReq += "]"
			aMethod = aInstanceRec
		ok
		cAlt = ""          # the text that the method had before a type parameter was typed (a class derived from a closed type of this one has this text, and inherits the method)
		if cHint = "" and isTypedMethod(aMethod) and find(aBoth,cLower + "|" + nArity) = 0
			if lTypedGeneric
				lTypedGeneric = false
				lPlain = isTypedMethod(aMethod)
				lTypedGeneric = true
				if not lPlain
					cAlt = cB + "		" + returnCode(cReq,aMethod[3],aMethod[5]) + nl
				ok
			ok
			cB += "		" + typedMethodCode(cName,nArity,aMethod[3],len(aMethod) >= 9 and aMethod[9] = 1) + nl
		but cHint = "" and isTypedStaticMethod(aMethod) and find(aBoth,cLower + "|" + nArity) = 0
			cB += "		" + typedStaticMethodCode(cTypeName,cName,nArity,aMethod[3],len(aMethod) >= 9 and aMethod[9] = 1) + nl
		else
			cB += "		" + returnCode(cReq,aMethod[3],aMethod[5]) + nl
		ok
		if cAlt = ""
			aBlocks + [lower(cRing),cB]
		else
			aBlocks + [lower(cRing),cB,cAlt]
		ok
	next

	# Indexer: Item(index) / SetItem(index,value). An indexer with several indexes takes them as a list: Item([row,column]) / SetItem([row,column],value)
	aIndexer = aInfo[6]
	lMulti = len(aInfo) >= 13 and len(aInfo[13]) > 0
	lMultiWrite = false
	if lMulti
		for aMulti in aInfo[13]
			if aMulti[3]
				lMultiWrite = true
			ok
		next
	ok
	if len(aIndexer) = 3 or lMulti
		if find(aNames,"item") = 0
			cB = "	Func Item P1" + nl
			if lMulti
				cB += "		if islist(P1)" + nl
				cB += '			return callMethod("get_Item",P1)' + nl
				cB += "		ok" + nl
			ok
			cAlt = ""
			if len(aIndexer) = 3 and isTypedIndexer(aIndexer)
				if lTypedGeneric
					lTypedGeneric = false
					lPlain = isTypedIndexer(aIndexer)
					lTypedGeneric = true
					if not lPlain
						cAlt = cB + "		" + returnCode('"call",[new DotNetObject(nHandle),"get_Item",P1]',aIndexer[2],0) + nl
					ok
				ok
				cB += "		" + typedIndexerGetCode() + nl
			but len(aIndexer) = 3
				cB += "		" + returnCode('"call",[new DotNetObject(nHandle),"get_Item",P1]',aIndexer[2],0) + nl
			else
				cB += '		raise("DotNet Error: this indexer takes its indexes as a list: Item([index1,index2])")' + nl + nl
			ok
			if cAlt = ""
				aBlocks + ["item",cB]
			else
				aBlocks + ["item",cB,cAlt]
			ok
		ok
		if (len(aIndexer) = 3 and aIndexer[3] or lMultiWrite) and find(aNames,"setitem") = 0
			cB = "	Func SetItem P1,P2" + nl
			if lMulti
				cB += "		if islist(P1)" + nl
				cB += "			aIndexes = P1" + nl
				cB += "			aIndexes + P2" + nl
				cB += '			callMethod("set_Item",aIndexes)' + nl
				cB += "			return self" + nl
				cB += "		ok" + nl
			ok
			cAlt = ""
			if len(aIndexer) = 3 and aIndexer[3] and isTypedIndexer(aIndexer)
				if lTypedGeneric
					lTypedGeneric = false
					lPlain = isTypedIndexer(aIndexer)
					lTypedGeneric = true
					if not lPlain
						cAlt = cB + "		" + nativeCall('"call",[new DotNetObject(nHandle),"set_Item",P1,P2]',"void") + "		return self" + nl + nl
					ok
				ok
				cB += "		" + 'dotnet_calltv(nHandle,"set_Item",P1,P2)' + nl
				cB += "		return self" + nl + nl
			but len(aIndexer) = 3 and aIndexer[3]
				cB += "		" + nativeCall('"call",[new DotNetObject(nHandle),"set_Item",P1,P2]',"void")
				cB += "		return self" + nl + nl
			else
				cB += '		raise("DotNet Error: this indexer takes its indexes as a list: SetItem([index1,index2],value)")' + nl + nl
			ok
			if cAlt = ""
				aBlocks + ["setitem",cB]
			else
				aBlocks + ["setitem",cB,cAlt]
			ok
		ok
		aNames + "item"
		aNames + "setitem"
	ok

	# Events: setClickEvent(cRingCode) / clearClickEvent()
	for aEvent in aInfo[7]
		cName = aEvent[1]
		if aEvent[2]
			cTarget = "dnTypeCached('" + cTypeName + "')"
		else
			cTarget = "new DotNetObject(nHandle)"
		ok
		if find(aNames,lower("set" + cName + "Event")) = 0
			aNames + lower("set" + cName + "Event")
			cB = "	Func set" + cName + "Event P1" + nl
			cB += '		dnRequest("setevent",[' + cTarget + ',"' + cName + '",dnCallback(P1)])' + nl
			cB += "		return self" + nl + nl
			aBlocks + [lower("set" + cName + "Event"),cB]
			cB = "	Func clear" + cName + "Event" + nl
			cB += '		dnRequest("clearevent",[' + cTarget + ',"' + cName + '"])' + nl
			cB += "		return self" + nl + nl
			aBlocks + [lower("clear" + cName + "Event"),cB]
		ok
	next

	# Properties and fields: getName() / setName(value)
	# (the target is "self" here, not "new DotNetObject(nHandle)": creating an object inside a getter or a setter breaks the assignment that
	#  is running, oMessage.Text = "" ends with a null target. Methods can create the small target object, it saves copying the whole object.)
	for aMember in aMembers
		cName = aMember[1]
		if aMember[4]
			cTarget = "dnTypeCached('" + cTypeName + "')"
		else
			cTarget = "self"
		ok
		# an instance property or field of a number, a yes/no or a text is read and written by the typed functions of the extension
		# (an enum is read as the text of its member name, and written from a text or a number: aMember[6] is true for it)
		lEnum = (len(aMember) >= 6) and aMember[6]
		lTyped = (not aMember[4]) and (isPrimitiveType(aMember[5]) or lEnum)
		lTypedStatic = aMember[4] and (isPrimitiveType(aMember[5]) or lEnum)
		cAt = memberAt(cName)          # a property called like a word of Ring is the attribute @Next: Ring calls get@Next and set@Next, which call getNext and setNext
		if aMember[2] and (find(aNames,lower("get" + cName)) = 0)
			aNames + lower("get" + cName)
			cB = "	Func get" + cName + nl
			if lTyped
				cB += "		" + typedGetterCode(cName,aMember[5],len(aMember) >= 7 and aMember[7] = 1) + nl
			but lTypedStatic
				cB += "		" + typedStaticGetterCode(cTypeName,cName,aMember[5],len(aMember) >= 7 and aMember[7] = 1) + nl
			else
				cB += "		" + propertyReturnCode('"get",[' + cTarget + ',"' + cName + '"]',aMember[5]) + nl
			ok
			aBlocks + [lower("get" + cName),cB]
			if cAt != "" and find(aAttrs,lower(cName)) > 0
				aBlocks + [lower("get@" + cName),"	Func get@" + cName + nl + "		return get" + cName + "()" + nl + nl]
			ok
		ok
		if aMember[3] and (find(aNames,lower("set" + cName)) = 0)
			aNames + lower("set" + cName)
			cB = "	Func set" + cName + " P1" + nl
			if lTyped
				cB += "		" + typedSetterCode(cName)
			but lTypedStatic
				cB += "		" + typedStaticSetterCode(cTypeName,cName)
			else
				cB += "		" + nativeCall('"set",[' + cTarget + ',"' + cName + '",P1]',"void")
			ok
			cB += "		return self" + nl + nl
			aBlocks + [lower("set" + cName),cB]
			if cAt != "" and find(aAttrs,lower(cName)) > 0
				aBlocks + [lower("set@" + cName),"	Func set@" + cName + " P1" + nl + "		return set" + cName + "(P1)" + nl + nl]
			ok
		but (not aMember[3]) and (find(aAttrs,lower(cName)) > 0) and (find(aNames,lower("set" + cName)) = 0)
			# read-only property: assigning to the attribute is an error
			aNames + lower("set" + cName)
			cB = "	Func set" + cName + " P1" + nl
			cB += '		raise("DotNet Error: ' + cName + ' is a read-only property")' + nl + nl
			aBlocks + [lower("set" + cName),cB]
			if cAt != ""
				aBlocks + [lower("set@" + cName),"	Func set@" + cName + " P1" + nl + "		return set" + cName + "(P1)" + nl + nl]
			ok
		ok
	next

	# The target of a call is made with "this.nHandle": in "new DotNetObject(nHandle)" the argument is read together with the new object
	# (Ring uses braces on it to call init), and after an error that was caught Ring could look for nHandle in the new object, whose nHandle is 0
	for nBlock = 1 to len(aBlocks)
		aBlocks[nBlock][2] = substr(aBlocks[nBlock][2],"new DotNetObject(nHandle)","new DotNetObject(this.nHandle)")
	next

	aPlan = [aInfo,cTypeName,nInit,lCreate,cCode,aAttrList,aBlocks,aInfo[10],aAttrs]
	if nForceInit < 0
		aPlanCache + [cOriginalName,aPlan]
	ok
	return aPlan


# The overloads of a method name: [available arities (optional parameters count), any static, any instance]
# True when every method of the name is generic with a type argument that its parameters do not show (JsonConvert.DeserializeObject<T>): the
# type arguments are given in the named form, Name([ :typeArguments = [ "System.String" ], :json = "..." ]). A name that also has a plain overload
# is a dispatcher only when it has more than one arity; the generic form of a name with one arity is called with callGeneric.
func needsTypeArguments aNtMethods, cNtLower
	lGeneric = false
	for aNtRec in aNtMethods
		if lower(aNtRec[1]) = cNtLower
			if len(aNtRec) >= 8 and aNtRec[8] = 1
				lGeneric = true
			else
				return false          # a name that also has a plain overload keeps its positional form when it has one arity (Eval(text) and Eval<T>(text)): the generic one is callGeneric
			ok
		ok
	next
	return lGeneric

func familyInfo aFiMethods, cFiLower
	aFiArities = []
	lFiStatic = false
	lFiInstance = false
	for aFiRec in aFiMethods
		if lower(aFiRec[1]) = cFiLower
			for nFiA = aFiRec[6] to len(aFiRec[4])
				if find(aFiArities,nFiA) = 0
					aFiArities + nFiA
				ok
			next
			if aFiRec[2]
				lFiStatic = true
			else
				lFiInstance = true
			ok
		ok
	next
	return [aFiArities,lFiStatic,lFiInstance]

# Ring code that calls the overload of a family with nFiArity parameters (static, instance, or the one that fits the object)
func arityCall aFiMethods, cFiName, cFiType, nFiArity, cFiOperation, cFiIndent
	cFiLower = lower(cFiName)
	lFiStatic = false
	lFiInstance = false
	aFiFirst = []
	aFiStaticRec = []
	aFiInstanceRec = []
	for aFiRec in aFiMethods
		if lower(aFiRec[1]) = cFiLower and nFiArity >= aFiRec[6] and nFiArity <= len(aFiRec[4])
			if len(aFiFirst) = 0
				aFiFirst = aFiRec
			ok
			if aFiRec[2]
				lFiStatic = true
				if len(aFiStaticRec) = 0
					aFiStaticRec = aFiRec
				ok
			else
				lFiInstance = true
				if len(aFiInstanceRec) = 0
					aFiInstanceRec = aFiRec
				ok
			ok
		ok
	next
	if len(aFiFirst) = 0
		return ""
	but len(aFiStaticRec) = 0
		aFiStaticRec = aFiFirst
	ok
	if len(aFiInstanceRec) = 0
		aFiInstanceRec = aFiFirst
	ok
	cFiArgs = ""
	if nFiArity > 0
		cFiArgs = ",P1"
	ok
	cFiStaticTarget = "dnTypeCached('" + cFiType + "')"
	cFiCode = ""
	if lFiStatic and lFiInstance
		cFiCode += cFiIndent + "if nHandle = 0" + nl
		cFiCode += cFiIndent + "	" + returnCode('"' + cFiOperation + '",[' + cFiStaticTarget + ',"' + cFiName + '"' + cFiArgs + ']',aFiStaticRec[3],aFiStaticRec[5])
		cFiCode += cFiIndent + "ok" + nl
		cFiTarget = "new DotNetObject(nHandle)"
	but lFiStatic
		cFiTarget = cFiStaticTarget
	else
		cFiTarget = "new DotNetObject(nHandle)"
	ok
	if lFiInstance
		cFiCode += cFiIndent + returnCode('"' + cFiOperation + '",[' + cFiTarget + ',"' + cFiName + '"' + cFiArgs + ']',aFiInstanceRec[3],aFiInstanceRec[5])
	else
		cFiCode += cFiIndent + returnCode('"' + cFiOperation + '",[' + cFiTarget + ',"' + cFiName + '"' + cFiArgs + ']',aFiStaticRec[3],aFiStaticRec[5])
	ok
	return cFiCode

# How the answers of the overloads of a name are read: "void", "value" (a text, a number, a yes/no), "object", "any" (the overloads differ),
# or "ring" (no overload found)
func dispatcherMode aMethods, cName
	cLower = lower(cName)
	cMode = ""
	for aRec in aMethods
		if lower(aRec[1]) = cLower
			if aRec[5] > 0
				cMode = "any"          # a method with out/ref parameters answers a list: dnFinish reads it
				loop
			but aRec[3] = "System.Void"
				cKind = "void"
			but isPrimitiveType(aRec[3])
				cKind = "value"
			else
				cKind = "object"
			ok
			if cMode = ""
				cMode = cKind
			but cMode != cKind
				cMode = "any"
			ok
		ok
	next
	if cMode = ""
		return "ring"
	ok
	return cMode

# The code of the named form of a dispatcher: the call of the family with the list of names, at the indent cIndent (the first line is
# written after the indent of the caller)
func namedCall cRequest, cMode, cIndent
	switch cMode
	on "ring"
		return "return " + sendCall(cRequest) + nl
	on "void"
		return nativeCall(cRequest,"void") + cIndent + "return self" + nl
	on "object"
		return objectReturnCode(cRequest)
	off
	return nativeCall(cRequest,cMode)

# The plain method of an overloaded family
# The static class (assembly qualified) of an extension method that the type does not have under that name: its assembly may not be loaded
# when the method is called, so the generated method asks the bridge to load it first (dnEnsureExt)
func extensionHint aHintMethods, cHintName
	cHintLower = lower(cHintName)
	for aHintRec in aHintMethods
		if len(aHintRec) >= 7 and isstring(aHintRec[7]) and lower(aHintRec[1]) = cHintLower
			return aHintRec[7]
		ok
	next
	return ""

# The body of a dispatcher whose call is made by the extension from its argument: dotnet_calltd (an answer of a number, a yes/no or a text) or dotnet_calltdv
# (nothing). A call that cannot be made directly (several overloads can take the argument, a list of named arguments...) is the generic request, made by the
# extension, so every answer and every error is the generic one; an answer that is not a number or a text is finished by dnAnswer.
func typedDispatchCode cName, cMode, lNoArgument
	# (a name with an overload without parameters reads NULL, an empty text, as no argument; any other name takes it as the one argument)
	cFunction = "dotnet_calltd"
	if not lNoArgument
		cFunction = "dotnet_calltd1"
	ok
	if cMode = "void"
		return "		" + cFunction + 'v(nHandle,"' + cName + '",P1)' + nl + "		return self" + nl
	ok
	return "		" + 'return dnAnswer(' + cFunction + '(nHandle,"' + cName + '",P1))' + nl

func dispatcherBlock cDiRing, cDiName, cDiType, aDiMethods, aDiFamily
	aDiArities = aDiFamily[1]
	cDiB = "	Func " + cDiRing + " P1" + nl
	cDiHint = extensionHint(aDiMethods,cDiName)
	if cDiHint != ""
		cDiB += '		dnEnsureExt("' + cDiHint + '")' + nl
	ok
	cDiMode = dispatcherMode(aDiMethods,cDiName)
	# an instance method that can be called with one argument (and perhaps with none), whose overloads answer a number, a yes/no, a text or nothing: the extension
	# looks at the argument (NULL, a value, a list of pairs) and calls the method directly when it can (see typedDispatchCode)
	if cDiHint = "" and not aDiFamily[2] and aDiFamily[3] and find(aDiArities,1) > 0 and (cDiMode = "void" or cDiMode = "value")
		return cDiB + typedDispatchCode(cDiName,cDiMode,find(aDiArities,0) > 0) + nl
	ok
	cDiB += "		if dotnet_isnamed(P1)" + nl
	# the named form: the bridge chooses the overload by the parameter names; static methods are reachable from an object
	if aDiFamily[2] and not aDiFamily[3]
		cDiTarget = "dnTypeCached('" + cDiType + "')"
	else
		cDiTarget = "new DotNetObject(nHandle)"
	ok
	if aDiFamily[2] and aDiFamily[3]
		cDiB += "			if nHandle = 0" + nl
		cDiB += "				" + namedCall('"callnamed",[dnTypeCached(' + "'" + cDiType + "'" + '),"' + cDiName + '",P1]',cDiMode,"				")
		cDiB += "			ok" + nl
	ok
	cDiB += "			" + namedCall('"callnamed",[' + cDiTarget + ',"' + cDiName + '",P1]',cDiMode,"			")
	cDiB += "		ok" + nl
	if find(aDiArities,0) > 0
		cDiB += "		if isstring(P1) and P1 = " + '""' + nl
		cDiB += arityCall(aDiMethods,cDiName,cDiType,0,"call","			")
		cDiB += "		ok" + nl
	ok
	if find(aDiArities,1) > 0
		cDiB += arityCall(aDiMethods,cDiName,cDiType,1,"call","		") + nl
	but needsTypeArguments(aDiMethods,lower(cDiName))
		cDiB += '		raise("DotNet Error: ' + cDiName + ' needs its type arguments: ' + cDiName + '([ :typeArguments = [ type names ], :parameter = value, ... ])")' + nl + nl
	else
		cDiB += '		raise("DotNet Error: ' + cDiName + ' does not take one argument: use named arguments, ' + cDiName + '([ :parameter = value, ... ])")' + nl + nl
	ok
	return cDiB

# The Ring source of a class: members that the generated base class already has are inherited
func genClass cTypeName, cClass, nForceInit
	aPlan = buildPlan(cTypeName,nForceInit)
	aInfo = aPlan[1]
	cLastRegister = 'dnRegisterClass("' + aInfo[1] + '","' + cClass + '",' + maxz(aPlan[3]) + ')' + nl
	# the base class: only when it is generated (otherwise all its members are in this class)
	cBaseRing = "DotNetObject"
	aBasePlan = []
	if aPlan[8] != ""
		nBase = find(aClassMap,aPlan[8],1)
		if nBase > 0 and len(aWantedNamespaces) > 0 and find(aWantedNamespaces,aClassMap[nBase][3]) = 0 and find(aFolderNamespaces,aClassMap[nBase][3]) = 0
			nBase = 0          # a base class of a namespace that this run does not generate: all its members are in this class
		ok
		if nBase > 0
			cBaseRing = aClassMap[nBase][2]
			aBasePlan = buildPlan(aPlan[8],-1)
		ok
	ok
	cCode = "# Generated by tools/dotnettools/gendotnet.ring from " + aInfo[1] + " (do not edit)" + nl + nl
	# creates an object of this class around an existing .NET object (dnWrapObject calls it with "call", no eval needed)
	cCode += "Func DotNetNew_" + cClass + nl
	cCode += "	oDotNetNew = new " + cClass + "(" + copyParams(maxz(aPlan[3])) + ")" + nl + nl
	cCode += "Class " + cClass + " from " + cBaseRing + nl + nl
	cAttrs = ""
	for aAttr in aPlan[6]
		if len(aBasePlan) = 0 or find(aBasePlan[9],aAttr[1]) = 0
			cAttrs += "	" + aAttr[2] + nl
		ok
	next
	if cAttrs != ""
		cCode += cAttrs + nl
	ok
	cCode += substr(aPlan[5],"%CLASS%",lower(cClass))
	for aBlock in aPlan[7]
		lInherited = false
		if len(aBasePlan) > 0
			for aOther in aBasePlan[7]
				if aOther[1] = aBlock[1] and (aOther[2] = aBlock[2] or (len(aOther) >= 3 and aOther[3] = aBlock[2]))
					lInherited = true
					exit
				ok
			next
		ok
		if not lInherited
			cCode += aBlock[2]
		ok
	next
	# the operators of the type (op_Addition ...): Ring calls operator() for o + x, o < x, x + o ("r+") ...
	if len(aInfo) >= 12 and len(aInfo[12]) > 0
		cCode += "	# the operators of " + aInfo[1] + ": " + operatorList(aInfo[12]) + nl
		cCode += "	Func operator cOperator, Para" + nl
		cCode += '		return dnRequest("operator",[self,cOperator,Para])' + nl + nl
	ok
	return cCode

# The operator methods of a type as the operators of Ring (op_Addition --> +)
func operatorList aOps
	aMap = [["op_Addition","+"],["op_Subtraction","-"],["op_Multiply","*"],["op_Division","/"],["op_Modulus","%"],["op_Equality","="],["op_Inequality","!="],
		["op_LessThan","<"],["op_GreaterThan",">"],["op_LessThanOrEqual","<="],["op_GreaterThanOrEqual",">="],["op_BitwiseAnd","&"],["op_BitwiseOr","|"],
		["op_ExclusiveOr","^"],["op_LeftShift","<<"],["op_RightShift",">>"],["op_UnaryNegation","-x"],["op_OnesComplement","~"],["op_LogicalNot","not"],["IComparable","< > <= >= (CompareTo)"]]
	cList = ""
	for cOp in aOps
		for aPair in aMap
			if aPair[1] = cOp
				cList += aPair[2] + " "
			ok
		next
	next
	return trim(cList)

func copyParams nCount
	cList = ""
	for x = 1 to nCount
		if x > 1 cList += "," ok
		cList += "0"
	next
	return cList

func maxz nValue
	if nValue < 0
		return 0
	ok
	return nValue

# On equal counts prefer the lowest arity, but a method with parameters beats a parameterless one
func rankArity nArity
	if nArity = 0
		return 99
	ok
	return nArity

func isExoticType cType
	if cType = "System.Byte[]" or cType = "System.Char[]"
		return false	# byte[] and char[] are plain Ring strings
	ok
	for cPart in ["[]","Comparison","Func`","Action","Comparer","Predicate","Converter","Span","Memory","IFormatProvider","CancellationToken"]
		if substr(cType,cPart)
			return true
		ok
	next
	return false

# The extension methods of the static classes of the plan: each one becomes a method of the class of the type that it extends
# (Table.AddColumn("Name") is TableExtensions.AddColumn(table, "Name")). The bridge finds them after the methods of the object itself.
# Types with a Ring class in this run are extended, and so are the classes that implement the interface that a method extends (the generic
# types of System are not, LINQ is called with dnQuery). A closed generic DELEGATE type outside System (Sprache's Parser<IEnumerable<char>>)
# extends the class of its generic definition (isDelegateDefinition): the delegate has a class only because extension methods extend it.
func findExtensions aPlan
	aExtMap = []
	nCount = 0
	# only the static classes with extension methods are described: the bridge lists them for the assemblies of the manifest
	aExtClasses = []
	aSeen = []
	for aEntry in aDotNetManifest
		aEntryAssemblies = optValue(aEntry,"assemblies",["System.Private.CoreLib"])
		for cAssemblyName in aEntryAssemblies
			if find(aSeen,cAssemblyName) = 0
				aSeen + cAssemblyName
				aFound = dnRequest("extensionclasses",[cAssemblyName])
				for cExtClass in aFound
					aExtClasses + cExtClass
				next
			ok
		next
	next
	for aItem in aPlan
		for aType in aItem[2]
			if find(aExtClasses,aType[4]) = 0
				loop
			ok
			try
				aInfo = dnDescribe(aType[1])
			catch
				aInfo = []
			done
			if len(aInfo) >= 9 and aInfo[2]
				cQualified = aInfo[1] + ", " + aInfo[9]
				for aMethod in aInfo[4]
					if len(aMethod) >= 8 and aMethod[7] = 1 and len(aMethod[4]) >= 1 and isIdent(aMethod[1])
						cTarget = aMethod[4][1]
						# a target with no class of its own (System.IServiceProvider) still counts: the classes that implement it get the methods
						lTarget = (not substr(cTarget,"[")) and not (substr(cTarget,"`") and left(cTarget,7) = "System.")          # a generic definition counts (IValidator`1), the generic types of System do not (LINQ)
						# a closed generic delegate type outside System (Sprache's Parser<IEnumerable<char>>) extends the class of its generic definition
						nClosed = substr(cTarget,"[[")
						if (not lTarget) and nClosed > 1 and substr(cTarget,"`") and left(cTarget,7) != "System." and right(cTarget,2) != "[]"
							if isDelegateDefinition(left(cTarget,nClosed - 1))
								cTarget = left(cTarget,nClosed - 1)
								lTarget = true
							but closedOfInterfaces(cTarget,nClosed)
								# a closed generic type outside System (ML.NET's IEstimator<ITransformer>: Append is an extension of it): the classes that implement the generic definition
								# get the method, and the bridge finds it for an object only when the object is of the closed type (a covariant IEstimator<T> is). Only when the type
								# arguments are interfaces or abstract classes (ITransformer): that is what a covariant type takes; a sealed class (IDiagnosticsLogger<DbLoggerCategory.Query>) would give the
								# method to every class of the definition, and most of them can not take it
								cTarget = left(cTarget,nClosed - 1)
								lTarget = true
							ok
						ok
						if lTarget
							aRest = []
							for nParam = 2 to len(aMethod[4])
								aRest + aMethod[4][nParam]
							next
							nRequired = aMethod[6] - 1
							if nRequired < 0 nRequired = 0 ok
							nPos = find(aExtMap,cTarget,1)
							if nPos = 0
								aExtMap + [cTarget,[]]
								nPos = len(aExtMap)
							ok
							aExtMap[nPos][2] + [aMethod[1],false,aMethod[3],aRest,aMethod[5],nRequired,cQualified,aMethod[8]]
							nCount++
						ok
					ok
				next
			ok
		next
	next
	? "Extension methods: " + nCount + " (" + len(aExtMap) + " extended types)"

# Can all the type arguments of a closed generic type have other types: are they interfaces or abstract classes? cTarget is  Definition`1[[Argument, Assembly, ...]]
# (nClosed: where the arguments start). The bridge tells what each type is (the request "typekind").
func closedOfInterfaces cTarget, nClosed
	cArguments = substr(cTarget,nClosed + 2)
	aParts = str2list(substr(cArguments,"],[",nl))
	if len(aParts) = 0
		return false
	ok
	for cPart in aParts
		cName = cPart
		nComma = substr(cName,",")
		if nComma > 0
			cName = left(cName,nComma - 1)
		ok
		cKind = dnRequest("typekind",[trim(cName)])
		if cKind != "interface" and cKind != "abstract"
			return false
		ok
	next
	return true

# Is the generic definition (Sprache.Parser`1) a delegate type? (remembered)
func isDelegateDefinition cDefinition
	nFound = find(aDelegateDefinitions,cDefinition,1)
	if nFound > 0
		return aDelegateDefinitions[nFound][2]
	ok
	lDelegate = false
	try
		aDefinition = dnDescribe(cDefinition)
		if len(aDefinition) >= 14
			lDelegate = aDefinition[14]
		ok
	catch
		lDelegate = false
	done
	aDelegateDefinitions + [cDefinition,lDelegate]
	return lDelegate

# Generate the namespaces of aDotNetManifest (all of them when aWanted is empty) into C_OUTDIR
func genAll aWanted
	aWantedNamespaces = aWanted
	# Windows Forms / WPF types need the desktop runtime, it must be selected before any other .NET call
	lDesktop = false
	lWeb = false
	lData = false
	for aEntry in aDotNetManifest
		if len(aWanted) = 0 or find(aWanted,aEntry[:namespace]) > 0
			if optValue(aEntry,"desktop",false) lDesktop = true ok
			if optValue(aEntry,"web",false) lWeb = true ok
			if optValue(aEntry,"data",false) lData = true ok
		ok
	next
	if lDesktop and lWeb
		dnUseAll()
	but lDesktop
		dnUseDesktop()
	but lWeb
		dnUseWeb()
	ok
	if lData
		dnUseData()
	ok
	# Pass 1: resolve the types of every namespace and choose the Ring class names (global, so names never clash)
	# explicit Ring class names are reserved first, so an automatic name never takes one of them
	for aEntry in aDotNetManifest
		aTypes = optValue(aEntry,"types",[])
		for aType in aTypes
			if len(aType) >= 2 and aType[2] != ""
				cCanonical = aType[1]
				if substr(cCanonical,"`")
					cCanonical = dnDescribe(cCanonical)[1]
				ok
				aTaken + [lower(aType[2]),cCanonical]
			ok
		next
	next
	aPlan = []
	for aEntry in aDotNetManifest
		aPlan + resolveNamespace(aEntry)
	next
	findExtensions(aPlan)
	# The index of all classes (type --> namespace): dnWrapObject imports a namespace when an object of its types is returned.
	# It is written as ONE call with the whole list: a program that loads thousands of separate "list + item" statements starts much slower.
	aIndexItems = []
	for aItem in aPlan
		for aType in aItem[2]
			aIndexItems + ('["' + aType[4] + '","' + aItem[1] + '"]')
		next
	next
	# Only a run for every namespace writes the index: a run for a few namespaces cannot see the types of the namespaces that need another
	# runtime mode (Windows Forms, WPF, ASP.NET), so its index would be incomplete.
	if len(aWanted) = 0
		# wrapassembly.ring (lMergeIndex): another assembly may have been wrapped into the same folder, and its types stay in the index
		if lMergeIndex and fexists(C_OUTDIR + "classindex.ring")
			aOldLines = str2list(read(C_OUTDIR + "classindex.ring"))
			for cOldLine in aOldLines
				cOldLine = trim(cOldLine)
				cOldItem = ""
				if left(cOldLine,2) = '["'
					cOldItem = cOldLine
					if right(cOldItem,1) = ","
						cOldItem = left(cOldItem,len(cOldItem) - 1)
					ok
				but left(cOldLine,20) = "aDotNetClassIndex + "          # the older format: one statement for each class
					cOldItem = substr(cOldLine,21)
				ok
				if cOldItem != "" and find(aIndexItems,cOldItem) = 0
					aIndexItems + cOldItem
				ok
			next
		ok
		cIndex = "# Generated by tools/dotnettools/gendotnet.ring: [.NET type, namespace] of every generated class" + nl
		cIndex += "dnAddClassIndex([" + nl
		for nItem = 1 to len(aIndexItems)
			cIndex += aIndexItems[nItem]
			if nItem < len(aIndexItems)
				cIndex += ","
			ok
			cIndex += nl
		next
		cIndex += "])" + nl
		write(C_OUTDIR + "classindex.ring",cIndex)
	ok
	# Pass 2: generate the requested namespaces
	for aItem in aPlan
		if len(aWanted) = 0 or find(aWanted,aItem[1]) > 0
			genNamespace(aItem)
		ok
	next


# letters, digits and _ only
func isIdent cName
	for x = 1 to len(cName)
		n = ascii(cName[x])
		if not ((n >= 65 and n <= 90) or (n >= 97 and n <= 122) or n = 95 or (n >= 48 and n <= 57))
			return false
		ok
	next
	return len(cName) > 0
