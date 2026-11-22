# MediatR: the requests and their handlers are written in .NET (a helper project); Ring builds the mediator (dependency injection), sends a request and
# publishes a notification
load "pkg.ring"
pkgUseProject("mediatr","helpers/PkgHelpers",[["PkgHelpers.dll",["PkgHelpers"]],["MediatR.dll",["MediatR"]]])
pkgImport("mediatr","PkgHelpers.dll","PkgHelpers")
pkgImport("mediatr","MediatR.dll","MediatR")

oMediator = dnStatic("PkgHelpers.Mediation","Build",[])

# a request goes to its handler, and the answer is a task
oPing = dnNew("PkgHelpers.Ping",["hello"])
dnAssert("a request has its text",oPing.Text,"hello")
oTask = oMediator.callMethod("Send",[oPing])
dnAssert("the answer of the handler",oTask.Result,"pong: hello")
dnAssert("another request",oMediator.callMethod("Send",[dnNew("PkgHelpers.Ping",["again"])]).Result,"pong: again")

# a notification goes to every handler
oLog = dnType("PkgHelpers.AddedLog")
oMediator.callMethod("Publish",[dnNew("PkgHelpers.Added",["first"])]).Wait(NULL)
oMediator.callMethod("Publish",[dnNew("PkgHelpers.Added",["second"])]).Wait(NULL)
oSeen = oLog.getProp("Seen")
dnAssert("both notifications were handled",oSeen.Count,2)
dnAssert("in order",oSeen.Item(1),"second")

# a request with no handler is an error
try
	oMediator.callMethod("Send",[dnNew("System.Object",[])])
	dnAssert("an object that is no request is an error",1,0)
catch
	dnAssert("an object that is no request is an error",len(cCatchError) > 0,1)
done

dnTestSummary()
