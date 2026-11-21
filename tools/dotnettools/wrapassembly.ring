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
	aSkip = []
	for aEntry in aLibraryManifest
		if optValue(aEntry,"desktop",false) or optValue(aEntry,"web",false) or optValue(aEntry,"data",false)
			aSkip + aEntry[:namespace]
		ok
	next
	cFolder = "../../libraries/dotnetlib/generated/"
	for cFile in dir(cFolder)
		cName = cFile[1]
		if right(cName,5) = ".ring" and not substr(cName,".classes.ring")
			cNamespace = left(cName,len(cName) - 5)
			if find(aSkip,cNamespace) = 0
				for cLine in str2list(read(cFolder + cName))
					cLine = trim(cLine)
					if left(cLine,16) = 'dnRegisterClass('
						nMiddle = substr(cLine,'","')
						if nMiddle > 0
							cType = substr(left(cLine,nMiddle - 1),17)
							cRest = substr(cLine,nMiddle + 3)
							nEnd = substr(cRest,'"')
							cClass = left(cRest,nEnd - 1)
							if find(aTaken,lower(cClass),1) = 0
								aTaken + [lower(cClass),cType]
							ok
						ok
					ok
				next
			ok
		ok
	next
