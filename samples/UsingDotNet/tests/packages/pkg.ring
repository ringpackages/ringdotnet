# Package tests: real programs against NuGet packages (Markdig, Dapper, Polly ...)
#   load "pkg.ring"
#   pkgUse("markdig",[["Markdig","1.6.0"]],[["Markdig.dll",["Markdig"]]])    the packages (pinned versions), the DLLs to wrap with their namespaces
#                                                                            (a DLL with no namespaces is only loaded: a sink, a provider)
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
	# the packages and versions of the test: a cache that was made for other ones is made again
	cSpec = ""
	for aPackage in aPackages
		cSpec += aPackage[1] + " " + aPackage[2] + ";"
	next
	if fexists(cFolder + "packages.txt") and read(cFolder + "packages.txt") != cSpec
		pkgRemoveDir(cFolder)
	ok
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
		write(cFolder + "packages.txt",cSpec)
	ok
	pkgWrapAndLoad(cFolder,aWraps)

# wraps the DLLs of a cache folder (the namespaces of each one) into its classes folder, and loads them
func pkgWrapAndLoad cFolder, aWraps

	cLibs = cFolder + "libs/"
	for aWrap in aWraps
		cDll = cLibs + aWrap[1]
		cClasses = cFolder + "classes/"
		cArgs = ""
		for cNamespace in aWrap[2]
			cArgs += " " + cNamespace
		next
		# the classes are made again when the list of namespaces of the test changed
		if len(aWrap[2]) > 0 and (not direxists(cClasses) or not fexists(cClasses + aWrap[1] + ".namespaces") or read(cClasses + aWrap[1] + ".namespaces") != cArgs)
			pkgMakeDir(cClasses)
			chdir(cPkgHere + "/../../../../tools/dotnettools")
			system(exefilename() + ' wrapassembly.ring "' + cDll + '" "' + cClasses + '"' + cArgs + " " + pkgQuiet())
			chdir(cPkgHere)
			write(cClasses + aWrap[1] + ".namespaces",cArgs)
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

# A test that needs a class written in .NET (a validator that derives from AbstractValidator<T>, a mapping profile, request handlers) has a helper
# project in helpers/<name>/: pkgUseProject("fluent","helpers/PkgHelpers",[["PkgHelpers.dll",["PkgHelpers"]],["FluentValidation.dll",["FluentValidation"]]])
# publishes it into the cache (the packages it needs come with it) and wraps and loads the DLLs like pkgUse. The cache is made again when a
# file of the project changed.
func pkgUseProject cName, cProject, aWraps

	cFolder = cPkgCache + cName + "/"
	cProjectFolder = cPkgHere + "/" + cProject + "/"
	cSpec = ""
	for aFile in dir(cProjectFolder)
		if not aFile[2] and (right(aFile[1],3) = ".cs" or right(aFile[1],7) = ".csproj")
			cSpec += aFile[1] + ":" + read(cProjectFolder + aFile[1]) + ";"
		ok
	next
	if fexists(cFolder + "packages.txt") and read(cFolder + "packages.txt") != cSpec
		pkgRemoveDir(cFolder)
	ok
	cLibs = cFolder + "libs/"
	if not fexists(cLibs + aWraps[1][1])
		pkgMakeDir(cFolder)
		system('dotnet publish "' + cProjectFolder + '" -c Release -o "' + cLibs + '" -nologo -v q ' + pkgQuiet())
		if not fexists(cLibs + aWraps[1][1])
			? "SKIPPED: the helper project " + cProject + " could not be built (the first run needs nuget.org)"
			bye
		ok
		write(cFolder + "packages.txt",cSpec)
	ok
	pkgWrapAndLoad(cFolder,aWraps)

# the classes of a namespace of a wrapped DLL (the DLLs of a test share one folder of classes, so that a class name that two of them have is made unique)
func pkgImport cName, cDll, cNamespace

	dnImportFrom(cPkgCache + cName + "/classes/",cNamespace)

func pkgQuiet

	if iswindows()
		return "> nul"
	ok
	return "> /dev/null 2>&1"

func pkgRemoveDir cPath

	if iswindows()
		system('rmdir /s /q "' + substr(cPath,"/","\") + '" 2>nul')
	else
		system('rm -rf "' + cPath + '"')
	ok

func pkgMakeDir cPath

	if iswindows()
		system('mkdir "' + substr(cPath,"/","\") + '" 2>nul')
	else
		system('mkdir -p "' + cPath + '"')
	ok
