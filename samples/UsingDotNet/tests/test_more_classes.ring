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
	dnTestSummary()
