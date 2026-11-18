# Classes added after the coverage audit (tools/auditcoverage.ring): DriveInfo, FileVersionInfo, WebProxy, PropertyChangedEventArgs,
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
	oDrive = new DriveInfo("C")
	dnAssert("DriveInfo: a fixed drive",oDrive.DriveType,"Fixed")
	dnAssert("DriveInfo: the drive is ready",oDrive.IsReady,True)
	dnAssert("DriveInfo: it has a size",oDrive.TotalSize > oDrive.AvailableFreeSpace,True)
	aDrives = oDrive.GetDrives().toList()
	dnAssert("DriveInfo.GetDrives",len(aDrives) > 0,True)

	oVersion = new FileVersionInfo().GetVersionInfo("C:\Windows\System32\notepad.exe")
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
