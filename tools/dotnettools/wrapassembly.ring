/*
	Generate Ring classes for your own .NET assembly (or any .dll) :

		ring wrapassembly.ring <assembly.dll> <output folder> [namespace ...]

	Then in your program:

		load "dotnet.ring"
		dnLoad("path/to/assembly.dll")
		dnImportFrom("<output folder>/","Your.Namespace")
		oObject = new YourClass()
*/

load "gendotnetcore.ring"

load "dotnetmanifest.ring"          # the manifest of the library: its class names are reserved (reserveLibraryNames)
aLibraryManifest = aDotNetManifest
C_OUTDIR = ""
lMergeIndex = true          # the index of the classes keeps the types of the assemblies that were wrapped into the same folder
aDotNetManifest = []

func main
	if len(sysargv) < 4
		? "Usage: ring wrapassembly.ring <assembly.dll> <output folder> [namespace ...]"
		return
	ok
	cDll = sysargv[3]
	C_OUTDIR = sysargv[4] + "/"
	if not direxists(sysargv[4])
		makedir(sysargv[4])
	ok
	cAssembly = dnLoad(cDll)
	aWanted = []
	for x = 5 to len(sysargv)
		aWanted + sysargv[x]
	next
	for cNamespace in dnRequest("listnamespaces",[cAssembly])
		aDotNetManifest + [ :namespace = cNamespace, :assemblies = [cAssembly], :all = true ]
	next
	? "Assembly " + cAssembly
	reserveLibraryNames()
	genAll(aWanted)
	for aRename in aRenamed
		? "  renamed: " + aRename[1] + " --> " + aRename[2] + "   (the library has a class " + aRename[3] + ")"
	next

# Ring class names are global, so a class of the assembly that has the name of a class of the library (YamlDotNet.Core.Version and
# System.Version) would be defined twice when the library loads its own class, and the program stops. The names of the library are reserved
# first: such a class gets the last part of its namespace as a prefix (CoreVersion), the way the library names its own clashes.
# The namespaces that need Windows Forms, WPF, ASP.NET or Entity Framework are left out: they are loaded only by programs that use them.
func reserveLibraryNames
	rl_aSkip = []
	for rl_aEntry in aLibraryManifest
		if optValue(rl_aEntry,"desktop",false) or optValue(rl_aEntry,"web",false) or optValue(rl_aEntry,"data",false)
			rl_aSkip + rl_aEntry[:namespace]
		ok
	next
	rl_cFolder = "../../libraries/dotnetlib/generated/"
	rl_aLines = []
	for rl_aFile in dir(rl_cFolder)
		rl_cName = rl_aFile[1]
		if right(rl_cName,5) = ".ring" and not substr(rl_cName,".classes.ring")
			if find(rl_aSkip,left(rl_cName,len(rl_cName) - 5)) = 0
				rl_aFileLines = str2list(read(rl_cFolder + rl_cName))          # a list in a variable: for ... in function() calls the function for every item
				for rl_cLine in rl_aFileLines
					if left(rl_cLine,16) = 'dnRegisterClass('
						rl_aLines + trim(rl_cLine)
					ok
				next
			ok
		ok
	next
	# the classes that other assemblies already have in the output folder (several assemblies can share a folder: Spectre.Console and
	# Spectre.Console.Testing both have a StringExtensions): their names are reserved too, except for the namespaces of this assembly,
	# which are made again
	rl_aOwn = []
	for rl_aEntry in aDotNetManifest
		rl_aOwn + rl_aEntry[:namespace]
	next
	if direxists(C_OUTDIR)
		for rl_aFile in dir(C_OUTDIR)
			rl_cName = rl_aFile[1]
			if right(rl_cName,5) = ".ring" and not substr(rl_cName,".classes.ring") and rl_cName != "classindex.ring"
				if find(rl_aOwn,left(rl_cName,len(rl_cName) - 5)) = 0
					rl_aFileLines = str2list(read(C_OUTDIR + rl_cName))
					rl_cFolderNamespace = left(rl_cName,len(rl_cName) - 5)
					aFolderNamespaces + rl_cFolderNamespace
					for rl_cLine in rl_aFileLines
						if left(rl_cLine,16) = 'dnRegisterClass('
							rl_aLines + trim(rl_cLine)
							# a class of an assembly that was wrapped into this folder before can be a base class of a class of this one
							# (PersonValidator derives from the AbstractValidator of the package): its type is known
							rl_nQuote = substr(rl_cLine,'","')
							if rl_nQuote > 0
								rl_cBaseType = substr(left(rl_cLine,rl_nQuote - 1),18)
								rl_cBaseRest = substr(rl_cLine,rl_nQuote + 3)
								if find(aClassMap,rl_cBaseType,1) = 0
									aClassMap + [rl_cBaseType,left(rl_cBaseRest,substr(rl_cBaseRest,'"') - 1),rl_cFolderNamespace]
								ok
							ok
						ok
					next
				ok
			ok
		next
	ok
	rl_aReserved = []
	rl_aNames = []          # the reserved names alone: find on a list of texts is fast
	for rl_cLine in rl_aLines
		rl_nMiddle = substr(rl_cLine,'","')
		if rl_nMiddle > 0
			rl_cType = substr(left(rl_cLine,rl_nMiddle - 1),17)
			rl_cRest = substr(rl_cLine,rl_nMiddle + 3)
			rl_cClass = left(rl_cRest,substr(rl_cRest,'"') - 1)
			if find(rl_aNames,lower(rl_cClass)) = 0
				rl_aNames + lower(rl_cClass)
				rl_aReserved + [lower(rl_cClass),rl_cType]
			ok
		ok
	next
	for rl_aTakenItem in aTaken
		rl_aReserved + rl_aTakenItem
	next
	aTaken = rl_aReserved
