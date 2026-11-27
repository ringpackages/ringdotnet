# Coverage audit: the public types of the shared .NET framework that have no generated Ring class
#   ring auditcoverage.ring            prints the namespaces (of the manifest) with missing types, and totals
# A type is "missing" when its namespace is in tools/dotnettools/dotnetmanifest.ring but classindex.ring has no class for it. Enums (texts in Ring), delegates (callbacks),
# ref structs and obsolete types have no class on purpose; the other kinds are the gaps: usually an assembly of the namespace that the manifest does not list.
load "../../libraries/dotnetlib/dotnetlib.ring"
using { "System.IO" "System.Reflection" }
load "dotnetmanifest.ring"

func main
	aNamespaces = []
	for aEntry in aDotNetManifest
		aNamespaces + aEntry[:namespace]
	next
	# the types that have a class: the index of generated classes
	aHave = []
	dnLoadClassIndex()
	for aItem in aDotNetClassIndex
		aHave[aItem[1]] = "1"
	next
	cFolder = dnRequest("call",[dnType("System.Runtime.InteropServices.RuntimeEnvironment"),"GetRuntimeDirectory"])
	aFiles = new Directory().GetFiles([ :path = cFolder, :searchPattern = "System*.dll" ]).toList()
	aMissing = []
	oDelegateType = dnStatic("System.Type","GetType",["System.Delegate"])
	oObsoleteType = dnStatic("System.Type","GetType",["System.ObsoleteAttribute"])
	aOther = []
	aOtherNames = []
	nTypes = 0
	for cFile in aFiles
		try
			oAssembly = dnStatic("System.Reflection.Assembly","LoadFrom",[cFile])
			aTypes = oAssembly.GetExportedTypes().toList()
		catch
			loop
		done
		for oType in aTypes
			cNamespace = oType.Namespace
			if isobject(cNamespace)
				loop
			but find(aNamespaces,cNamespace) = 0
				# a namespace that has no wrapper at all: count its public classes (not enums, delegates, attributes, exceptions)
				cShort = oType.FullName
				if not oType.IsEnum and not oType.IsNested and right(cShort,9) != "Attribute" and right(cShort,9) != "Exception" and substr(cShort,"`") = 0
					aOther[cNamespace] = "" + (number(aOther[cNamespace]) + 1)
					if find(aOtherNames,cNamespace) = 0
						aOtherNames + cNamespace
					ok
				ok
				loop
			but oType.IsNested
				loop
			ok
			nTypes++
			cName = oType.FullName
			if aHave[cName] = ""
				# the kinds that need no class: enums are texts, delegates are callbacks, ref structs cannot be objects, obsolete types are not wrapped
				# (the generator skips them: Bridge.Describe.cs), attributes and exceptions are rarely used from Ring
				cKind = "class"
				if oType.IsEnum
					cKind = "enum"
				but oDelegateType.IsAssignableFrom(oType)
					cKind = "delegate"
				but oType.IsByRefLike
					cKind = "ref struct"
				but dnStatic("System.Attribute","IsDefined",[ oType, oObsoleteType, 0 ])
					cKind = "obsolete"
				but substr(cName,"`") > 0
					cKind = "generic"
				but right(cName,9) = "Attribute"
					cKind = "attribute"
				but right(cName,9) = "Exception"
					cKind = "exception"
				but left(substr(cName,len(cNamespace) + 2),1) = "I" and isupper(substr(substr(cName,len(cNamespace) + 2),2,1))
					cKind = "interface"
				ok
				oOwner = oType.Assembly
				oOwnerName = oOwner.GetName(NULL)
				aMissing + [cNamespace,cName,cKind,oOwnerName.Name]
			ok
		next
	next
	aKinds = ["enum","delegate","ref struct","obsolete","generic","attribute","exception","interface","class"]
	nOpen = 0
	for aItem in aMissing
		if aItem[3] = "class" or aItem[3] = "interface" or aItem[3] = "generic" or aItem[3] = "attribute" or aItem[3] = "exception"
			nOpen++
		ok
	next
	? "public types in the manifest namespaces: " + nTypes + ", without a Ring class that is not excluded on purpose: " + nOpen + " (without a Ring class on purpose: " + (len(aMissing) - nOpen) + ")"
	for cKind in aKinds
		nCount = 0
		for aItem in aMissing
			if aItem[3] = cKind
				nCount++
			ok
		next
		? "   " + cKind + ": " + nCount
	next
	? nl + "types that have no Ring class and are not excluded on purpose (the ones to look at):"
	for aItem in aMissing
		if aItem[3] = "class" or aItem[3] = "interface" or aItem[3] = "generic" or aItem[3] = "attribute" or aItem[3] = "exception"
			? "   " + aItem[3] + " " + aItem[2] + "   (" + aItem[4] + ")"
		ok
	next
	? nl + "namespaces without a wrapper (public classes):"
	for cNamespace in aOtherNames
		if number(aOther[cNamespace]) >= 3
			? "   " + cNamespace + " " + aOther[cNamespace]
		ok
	next
