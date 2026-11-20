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
	genAll(aWanted)
