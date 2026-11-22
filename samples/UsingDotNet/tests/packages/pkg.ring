# Package tests: real programs against NuGet packages (Markdig, Dapper, Polly ...)
#   load "pkg.ring"
#   pkgUse("markdig",[["Markdig","1.6.0"]],[["Markdig.dll",["Markdig"]]])    the packages (pinned versions), the DLLs to wrap with their namespaces
#   dnImport...                                                              the namespaces are then imported with pkgImport("markdig","Markdig.dll","Markdig")
# The first run restores the packages from nuget.org (dotnet publish) and makes the Ring classes of the DLLs (wrapassembly.ring); both are kept in
# the folder .cache next to the test, so the next runs only load them. A computer without nuget.org on its first run skips the test (SKIPPED), it does
# not fail it. The versions are pinned: a test says what works with those versions; tools/dotnettools/auditpackages.py is for the newest ones.
load "dotnet.ring"

cPkgHere = currentdir()
cPkgCache = cPkgHere + "/.cache/"
aPkgExtra = []          # the DLLs of a package that are not wrapped but are loaded (a native provider ...): a test adds them before pkgUse

func pkgUse cName, aPackages, aWraps
	cFolder = cPkgCache + cName + "/"
	cLibs = cFolder + "libs/"
	if not fexists(cLibs + aWraps[1][1])
		pkgMakeDir(cFolder)
		cRefs = ""
		for aPackage in aPackages
			cRefs += '<PackageReference Include="' + aPackage[1] + '" Version="' + aPackage[2] + '" />'
		next
		write(cFolder + "Pkg.csproj",'<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><TargetFramework>net9.0</TargetFramework><AssemblyName>Pkg</AssemblyName><SatelliteResourceLanguages>en</SatelliteResourceLanguages></PropertyGroup><ItemGroup>' + cRefs + '</ItemGroup></Project>')
		write(cFolder + "Empty.cs","class Empty { }")
		system('dotnet publish "' + cFolder + 'Pkg.csproj" -c Release -o "' + cLibs + '" -nologo -v q ' + pkgQuiet())
		if not fexists(cLibs + aWraps[1][1])
			? "SKIPPED: the package " + aPackages[1][1] + " could not be restored (the first run needs nuget.org)"
			bye
		ok
	ok
	for aWrap in aWraps
		cDll = cLibs + aWrap[1]
		cClasses = cFolder + "classes/" + aWrap[1] + "/"
		cArgs = ""
		for cNamespace in aWrap[2]
			cArgs += " " + cNamespace
		next
		# the classes are made again when the list of namespaces of the test changed
		if not direxists(cClasses) or not fexists(cClasses + "namespaces.txt") or read(cClasses + "namespaces.txt") != cArgs
			pkgMakeDir(cClasses)
			chdir(cPkgHere + "/../../../../tools/dotnettools")
			system(exefilename() + ' wrapassembly.ring "' + cDll + '" "' + cClasses + '"' + cArgs + " " + pkgQuiet())
			chdir(cPkgHere)
			write(cClasses + "namespaces.txt",cArgs)
		ok
		dnLoad(cDll)
	next
	for cExtra in pkgExtraDlls(cLibs)
		dnLoad(cExtra)
	next

func pkgExtraDlls cLibs
	aFound = []
	for cDll in aPkgExtra
		aFound + (cLibs + cDll)
	next
	return aFound

# the classes of a namespace of a wrapped DLL
func pkgImport cName, cDll, cNamespace
	dnImportFrom(cPkgCache + cName + "/classes/" + cDll + "/",cNamespace)

func pkgQuiet
	if iswindows()
		return "> nul"
	ok
	return "> /dev/null 2>&1"

func pkgMakeDir cPath
	if iswindows()
		system('mkdir "' + substr(cPath,"/","\") + '" 2>nul')
	else
		system('mkdir -p "' + cPath + '"')
	ok
