/*
	The code of the Ring class generator (used by gendotnet.ring and wrapassembly.ring)
*/


load "../../libraries/dotnetlib/dotnetlib.ring"

# Ring keywords are not used as method names: a method that has such a name gets "_" at the end
aKeywords = split("if to or and not for foreach new func from next load else see while ok class return but end give bye exit try catch done switch on other off in loop package import private step do again call elseif put get set case def endfunc endclass endpackage endif endfor endwhile endswitch endtry function endfunction break continue this self super main init operator"," ")
# The words that Ring accepts after a dot, as the name of an attribute or a method (o.From = x, o.Set(1)): they keep their names.
# The others (get and or not next end if for new load call put give see ...) are a syntax error there: methods get "_", attributes are left out.
aMemberOk = split("from to set step in on off other done ok"," ")
aMemberKeywords = []
for cWord in aKeywords
	if find(aMemberOk,cWord) = 0
		aMemberKeywords + cWord
	ok
next

# true: the namespaces of the manifest :uses are not loaded together with a namespace (only the namespaces of base classes are):
# a class of another namespace is loaded when an object of it comes back, or when the program names the namespace in using { }
lLazyUses = false

aClassMap = []	# [canonical .NET name, Ring class name]
aTaken = []	# [lowercase Ring class name, .NET name]
cClassPrefix = ""	# :prefix of the namespace being resolved (used for names that are already taken)
cLastRegister = ""
aPlanCache = []	# [.NET type name, plan] (see buildPlan)

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
	if optValue(aEntry,"all",false)
		for cName in dnRequest("listtypes",dnJoin([cNs],aAssemblies))
			if find(aExclude,cName) = 0
				aOut + [cName,"",-1,cName]
			ok
		next
	ok
	for aType in optValue(aEntry,"types",[])
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
				if aClassMap[nBase][3] != cNs and find(aBaseNamespaces,aClassMap[nBase][3]) = 0
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

func ringName cName
	if find(aMemberKeywords,lower(cName)) > 0
		return cName + "_"
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

# Statement that returns the result of a call (the bridge result is wrapped by the runtime type, see dnWrapObject)
func returnCode cRequest, cReturnType, nByRef
	if nByRef = 0 and cReturnType = "System.Void"
		return sendCall(cRequest) + nl + "		return self" + nl
	ok
	return "return " + sendCall(cRequest) + nl

# The code of a request for a member of an object. The generated method does not make the target object and the list of the request:
# it passes the handle as a number and the pieces that never change (the operation and the name) as ready wire items, so that the
# request is one text that dnSend finishes. Written for the request text of this generator:  "call",[TARGET,"Name",P1,P2]
#   "call",[new DotNetObject(nHandle),"Append",P1]   -->   dnSend("s4:call",nHandle,"s6:Append",dnPackItem(P1))
func sendCall cRequest
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
	if left(cTarget,13) = "dnTypeCached("
		cHandle = cTarget + ".nHandle"
	ok
	cArgs = '""'
	if len(cTail) > 0
		aArgs = str2list(substr(right(cTail,len(cTail) - 1),",",nl))
		cArgs = ""
		for cArg in aArgs
			if len(cArgs) > 0
				cArgs += " + "
			ok
			cArgs += "dnPackItem(" + cArg + ")"
		next
	ok
	return 'dnSend("s' + len(cOperation) + ":" + cOperation + '",' + cHandle + ',"s' + len(cName) + ":" + cName + '",' + cArgs + ")"

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
			aExpanded + [aMethod[1],aMethod[2],aMethod[3],aShort,aMethod[5],aMethod[6]]
		next
	next
	aMethods = aExpanded
	cReserved = "|callmethod|getprop|setprop|typename|tolist|release|isnull|init|"

	aBlocks = []	# [Ring name (lower case), text]
	cB = ""
	nInit = -1	# parameterless init() when the type has such a constructor, else the shortest constructor
	for aCtor in aCtors
		if (nInit = -1) or (len(aCtor) < nInit)
			nInit = len(aCtor)
		ok
	next
	if aInfo[8]
		nInit = 0	# structs: init() makes the default value, the other constructors are New_N
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
	# Properties and fields become attributes, so that oObj.Text = "x" calls setText() and oObj.Text calls getText()
	aMethodNames = ["init","nhandle"]
	for aMethod in aMethods
		aMethodNames + lower(aMethod[1])
	next
	aAttrs = []
	aAttrList = []
	for aMember in aMembers
		cLowerName = lower(aMember[1])
		if (find(aMethodNames,cLowerName) = 0) and (find(aAttrs,cLowerName) = 0) and (find(aMemberKeywords,cLowerName) = 0) and (not substr(cReserved,"|" + cLowerName + "|"))
			aAttrs + cLowerName
			aAttrList + [cLowerName,aMember[1]]
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

	# Constructors: init uses the overload with fewer parameters, New_N the others
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
			cCode += "		if nHandle != 0          # the default object made for the class body is not needed" + nl
			cCode += "			dotnet_unguard(oDotNetGuard)" + nl
			cCode += "			dnRequest(" + '"release"' + ",[nHandle])" + nl
			cCode += "		ok" + nl
		ok
		cCode += "		nHandle = dnCreate('" + cTypeName + "',[" + paraList(nInit) + "])" + nl
		cCode += "		oDotNetGuard = dotnet_guard(nHandle)" + nl
	ok
	cCode += "		return self" + nl + nl
	# The other constructors: ONE method New_ that takes one parameter, like the methods with overloads:
	# New_(NULL) calls the parameterless constructor, New_([ :param = value ]) chooses the constructor by the parameter names,
	# New_(value) calls the constructor with one parameter. Example: new WpfBinding().New_([ :path = "Value" ])  (New is a Ring keyword, so the method is New_)
	lOtherCtor = false
	for aCtor in aCtors
		if len(aCtor) != nInit
			lOtherCtor = true
		ok
	next
	if lOtherCtor
		cCode += "	Func New_ P1" + nl
		if lDefaultRegion
			cCode += "		if nHandle != 0          # the default object made for the class body is not needed" + nl
			cCode += "			dotnet_unguard(oDotNetGuard)" + nl
			cCode += "			dnRequest(" + '"release"' + ",[nHandle])" + nl
			cCode += "			nHandle = 0" + nl
			cCode += "		ok" + nl
		ok
		cCode += "		if dnIsNamed(P1)" + nl
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
	aNames = ["init","new_"]	# New_ is the method of the constructors with parameters (a .NET method called New is not wrapped: use callMethod)
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
		# GetType(name) vs Type) gets an underscore at the end instead
		if find(aAccessors,lower(cDispatch)) > 0
			cDispatch = cName + "_"
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
			but len(aFamilyAll[1]) >= 2
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
		ok
		if nArity != aMin[find(aMin,cLower,1)][2]
			cRing = cName + "_" + nArity
		ok
		# getX()/setX() of a property or field are used by Ring for oObject.X: a method with that name (Array.GetLength(i) vs Length) is renamed
		if find(aAccessors,lower(cRing)) > 0
			cRing = cName + "_"
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
		cB += "		" + returnCode(cReq,aMethod[3],aMethod[5]) + nl
		aBlocks + [lower(cRing),cB]
	next

	# Indexer: Item(index) / SetItem(index,value)
	aIndexer = aInfo[6]
	if len(aIndexer) = 3
		if find(aNames,"item") = 0
			cB = "	Func Item P1" + nl
			cB += "		" + returnCode('"call",[new DotNetObject(nHandle),"get_Item",P1]',aIndexer[2],0) + nl
			aBlocks + ["item",cB]
		ok
		if aIndexer[3] and find(aNames,"setitem") = 0
			cB = "	Func SetItem P1,P2" + nl
			cB += "		" + sendCall('"call",[new DotNetObject(nHandle),"set_Item",P1,P2]') + nl
			cB += "		return self" + nl + nl
			aBlocks + ["setitem",cB]
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
		if aMember[2] and (find(aNames,lower("get" + cName)) = 0)
			aNames + lower("get" + cName)
			cB = "	Func get" + cName + nl
			cB += "		" + returnCode('"get",[' + cTarget + ',"' + cName + '"]',aMember[5],0) + nl
			aBlocks + [lower("get" + cName),cB]
		ok
		if aMember[3] and (find(aNames,lower("set" + cName)) = 0)
			aNames + lower("set" + cName)
			cB = "	Func set" + cName + " P1" + nl
			cB += "		" + sendCall('"set",[' + cTarget + ',"' + cName + '",P1]') + nl
			cB += "		return self" + nl + nl
			aBlocks + [lower("set" + cName),cB]
		but (not aMember[3]) and (find(aAttrs,lower(cName)) > 0) and (find(aNames,lower("set" + cName)) = 0)
			# read-only property: assigning to the attribute is an error
			aNames + lower("set" + cName)
			cB = "	Func set" + cName + " P1" + nl
			cB += '		raise("DotNet Error: ' + cName + ' is a read-only property")' + nl + nl
			aBlocks + [lower("set" + cName),cB]
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
	ok
	if len(aFiStaticRec) = 0
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

# The plain method of an overloaded family
func dispatcherBlock cDiRing, cDiName, cDiType, aDiMethods, aDiFamily
	aDiArities = aDiFamily[1]
	cDiB = "	Func " + cDiRing + " P1" + nl
	cDiB += "		if dnIsNamed(P1)" + nl
	# the named form: the bridge chooses the overload by the parameter names; static methods are reachable from an object
	lDiVoid = true
	for aDiRec in aDiMethods
		if lower(aDiRec[1]) = lower(cDiName) and (aDiRec[3] != "System.Void" or aDiRec[5] > 0)
			lDiVoid = false
		ok
	next
	if aDiFamily[2] and not aDiFamily[3]
		cDiTarget = "dnTypeCached('" + cDiType + "')"
	else
		cDiTarget = "new DotNetObject(nHandle)"
	ok
	if aDiFamily[2] and aDiFamily[3]
		cDiB += "			if nHandle = 0" + nl
		cDiB += "				return " + sendCall('"callnamed",[dnTypeCached(' + "'" + cDiType + "'" + '),"' + cDiName + '",P1]') + nl
		cDiB += "			ok" + nl
	ok
	if lDiVoid
		cDiB += "			" + sendCall('"callnamed",[' + cDiTarget + ',"' + cDiName + '",P1]') + nl + "			return self" + nl
	else
		cDiB += "			return " + sendCall('"callnamed",[' + cDiTarget + ',"' + cDiName + '",P1]') + nl
	ok
	cDiB += "		ok" + nl
	if find(aDiArities,0) > 0
		cDiB += "		if isstring(P1) and P1 = " + '""' + nl
		cDiB += arityCall(aDiMethods,cDiName,cDiType,0,"call","			")
		cDiB += "		ok" + nl
	ok
	if find(aDiArities,1) > 0
		cDiB += arityCall(aDiMethods,cDiName,cDiType,1,"call","		") + nl
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
				if aOther[1] = aBlock[1] and aOther[2] = aBlock[2]
					lInherited = true
					exit
				ok
			next
		ok
		if not lInherited
			cCode += aBlock[2]
		ok
	next
	return cCode

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

# Generate the namespaces of aDotNetManifest (all of them when aWanted is empty) into C_OUTDIR
func genAll aWanted
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
		for aType in optValue(aEntry,"types",[])
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
	# The index of all classes (type --> namespace): dnWrapObject imports a namespace when an object of its types is returned
	cIndex = "# Generated by tools/dotnettools/gendotnet.ring: [.NET type, namespace] of every generated class" + nl
	for aItem in aPlan
		for aType in aItem[2]
			cIndex += 'aDotNetClassIndex + ["' + aType[4] + '","' + aItem[1] + '"]' + nl
		next
	next
	# Only a run for every namespace writes the index: a run for a few namespaces cannot see the types of the namespaces that need another
	# runtime mode (Windows Forms, WPF, ASP.NET), so its index would be incomplete.
	if len(aWanted) = 0
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
