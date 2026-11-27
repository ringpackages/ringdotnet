# Classes added after the coverage audit (tools/dotnettools/auditcoverage.ring): DriveInfo, FileVersionInfo, WebProxy, PropertyChangedEventArgs,
# TransactionScope, expression trees
load "dotnet.ring"

func main

	using {
		"System"
		"System.IO"
		"System.Net"
		"System.Diagnostics"
		"System.ComponentModel"
		"System.Linq.Expressions"
		"System.Transactions"
		"System.Net.Sockets"
		"System.Security.Principal"
		"System.Drawing"
		"System.Text"
	}
	cDriveName = "C"          # (the root of the file system on Linux and macOS)
	if not iswindows()
		cDriveName = "/"
	ok
	oDrive = new DriveInfo(cDriveName)
	dnAssert("DriveInfo: a fixed drive",oDrive.DriveType,"Fixed")
	dnAssert("DriveInfo: the drive is ready",oDrive.IsReady,True)
	dnAssert("DriveInfo: it has a size",oDrive.TotalSize > oDrive.AvailableFreeSpace,True)
	aDrives = oDrive.GetDrives().toList()
	dnAssert("DriveInfo.GetDrives",len(aDrives) > 0,True)

	cVersionFile = "C:\Windows\System32\notepad.exe"          # (a file with version information: a program of Windows, or the core library of .NET)
	if not iswindows()
		cVersionFile = new Type().GetType("System.Object").getProp("Assembly").getProp("Location")
	ok
	oVersion = new FileVersionInfo().GetVersionInfo(cVersionFile)
	dnAssert("FileVersionInfo: a description",len(oVersion.FileDescription) > 0,True)

	oChanged = new PropertyChangedEventArgs("Name")
	dnAssert("PropertyChangedEventArgs",oChanged.PropertyName,"Name")

	oProxy = dnNew("WebProxy",[ :address = "http://127.0.0.1:8080" ])
	dnAssert("WebProxy: the address",oProxy.Address.Port,8080)

	oScope = new TransactionScope()
	oScope.Complete()
	oScope.Dispose()
	dnAssert("TransactionScope runs",True,True)

	oConstant = new ExpressionsExpression().Constant(5)
	dnAssert("Expression.Constant",oConstant.NodeType,"Constant")
	# a compiled lambda is a delegate: it has the methods of Delegate (DynamicInvoke, Method, Target)
	oExpression = new ExpressionsExpression()
	oA = oExpression.Parameter([ :type = dnType("System.Double"), :name = "a" ])
	oB = oExpression.Parameter([ :type = dnType("System.Double"), :name = "b" ])
	oAdd = oExpression.Lambda([ :body = oExpression.Add([ :left = oA, :right = oB ]), :parameters = [oA,oB] ]).Compile(NULL)
	dnAssert("a compiled lambda: DynamicInvoke",oAdd.DynamicInvoke([2,3.5]),5.5)
	dnAssert("a compiled lambda: Method",oAdd.Method.Name != "",True)
	# classes of assemblies that the manifest did not list before: the other assemblies of a namespace (System.Net.Primitives, System.Security.Claims,
	# System.ComponentModel.TypeConverter, System.Text.Encoding.CodePages)
	oSocketError = (new SocketException).@New(10061)
	dnAssert("SocketException: the error code",oSocketError.ErrorCode,10061)
	dnAssert("SocketException: the error as a text",oSocketError.SocketErrorCode,"ConnectionRefused")
	oIdentity = new GenericIdentity("ann")
	dnAssert("GenericIdentity: the name",oIdentity.Name,"ann")
	dnAssert("GenericIdentity: authenticated",oIdentity.IsAuthenticated,True)
	oPrincipal = new GenericPrincipal(oIdentity,["admin","user"])
	dnAssert("GenericPrincipal: a role that it has",oPrincipal.IsInRole("admin"),True)
	dnAssert("GenericPrincipal: a role that it has not",oPrincipal.IsInRole("guest"),False)
	oColorConverter = new ColorConverter()
	oRed = oColorConverter.ConvertFromString("Red")
	dnAssert("ColorConverter: a name gives a color",oRed.R,255)
	oProvider = new CodePagesEncodingProvider()
	oEncodingType = new Encoding()
	oEncodingType.RegisterProvider(oProvider.Instance)
	oWindows1252 = oEncodingType.GetEncoding(1252)
	dnAssert("CodePagesEncodingProvider: windows-1252 is available",oWindows1252.WebName,"windows-1252")
	dnTestSummary()
