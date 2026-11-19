/*
	A web server for Ring programs (ASP.NET Core / Kestrel); the requests are handled by Ring functions.

	load "dotnet.ring"
	using { "RingDotNet.Web" }			# starts the ASP.NET Core mode (the namespaces Microsoft.AspNetCore.* do it too)

	oServer = new WebServer("http://localhost:5000")
	oServer.onGet("/","home")
	oServer.onGet("/api/time","timeApi")
	oServer.onPost("/api/echo","echoApi")
	oServer.run()					# serve until stop() is called

	func home oRequest
		return "<h1>Hello from Ring</h1><p>You asked for " + oRequest.path() + "</p>"
	func timeApi oRequest
		return webJson([["time","now"]])
	func echoApi oRequest
		return [201,"text/plain","you sent: " + oRequest.body()]

	A handler gets a RingRequest (method(), path(), query("name"), body(), header("name"), form("name"), setHeader(name, value),
	context() = the ASP.NET HttpContext) and returns: a text (200, text/html), [status, contentType, text], or webJson(list).
	notFound("handler") answers the paths that no route has (a catch-all handler).
	The server runs in .NET threads, the handlers run on the Ring thread: call serveOne(nMilliseconds) in your own loop
	(for example next to a GUI) or run().
*/

# The response of a handler as JSON: a Ring list, or a list of [name, value] pairs for a JSON object
func webJson  xValue
	return [200,"application/json",dnRequest("call",[dnTypeCached("System.Text.Json.JsonSerializer, System.Text.Json"),"Serialize",webPlain(xValue)])]

# A list of [name, value] pairs (the name is a string) is turned into a dictionary (a JSON object), other lists stay arrays; nested values too
func webPlain  xValue
	if islist(xValue) and len(xValue) > 0 and islist(xValue[1]) and len(xValue[1]) = 2 and isstring(xValue[1][1])
		wb_oDict = dnNew("System.Collections.Generic.Dictionary`2[[System.String],[System.Object]]",[])
		for wb_aPair in xValue
			wb_oDict.callMethod("Add",[wb_aPair[1],webPlain(wb_aPair[2])])
		next
		return wb_oDict
	ok
	if islist(xValue)
		wb_aArray = []
		for wb_xItem in xValue
			wb_aArray + webPlain(wb_xItem)
		next
		return wb_aArray
	ok
	return xValue

# One request as Ring sees it
class RingRequest

	nHandle = 0
	oOwner = ""          # the object that owns the handle (its guard releases the handle when this request is gone)

	func init  pHandle
		nHandle = pHandle

	func method
		return dnRequest("get",[self,"Method"])

	func path
		return dnRequest("get",[self,"Path"])

	func queryString
		return dnRequest("get",[self,"QueryString"])

	# a query string value: /search?q=ring --> query("q")
	func query  cName
		return dnRequest("call",[self,"Query",cName])

	func body
		return dnRequest("get",[self,"Body"])

	func header  cName
		return dnRequest("call",[self,"Header",cName])

	func form  cName
		return dnRequest("call",[self,"Form",cName])

	func setHeader  cName, cValue
		dnRequest("call",[self,"SetHeader",cName,cValue])

	# the ASP.NET HttpContext for everything else
	func context
		return dnRequest("get",[self,"Context"])

	func respond  nStatus, cType, cBody
		dnRequest("call",[self,"Respond",nStatus,cType,cBody])

class WebServer

	wb_oServer = ""
	wb_aRoutes = []		# [method, path, wrapper function]
	wb_lRunning = false
	wb_cNotFound = ""
	nRequests = 0

	func init  cUrl
		wb_oServer = dnRequest("call",[dnType("RingDotNet.RingWebServer, RingDotNet.Web"),"Start",cUrl])

	# the real address (when the port was 0)
	func url
		return dnRequest("get",[wb_oServer,"Url"])

	# handler: the name of a Ring function that receives a RingRequest and returns the response
	func route  cMethod, cPath, cHandler
		wb_aRoutes + [upper(cMethod),cPath,webWrapper(cHandler)]
		return self

	func onGet  cPath, cHandler
		return route("GET",cPath,cHandler)

	func onPost  cPath, cHandler
		return route("POST",cPath,cHandler)

	func onPut  cPath, cHandler
		return route("PUT",cPath,cHandler)

	func onDelete  cPath, cHandler
		return route("DELETE",cPath,cHandler)

	func notFound  cHandler
		wb_cNotFound = webWrapper(cHandler)
		return self

	# handle one request if one is waiting (waits up to nMilliseconds); true when a request was handled
	func serveOne  nMilliseconds
		wb_oRaw = dnRequest("call",[wb_oServer,"Next",nMilliseconds])
		if not isobject(wb_oRaw) or wb_oRaw.nHandle = 0
			return false
		ok
		oWebRequest = new RingRequest(wb_oRaw.nHandle)
		oWebRequest.oOwner = wb_oRaw
		nRequests++
		wb_cFound = ""
		wb_cMethod = oWebRequest.method()
		wb_cPath = oWebRequest.path()
		for wb_aRoute in wb_aRoutes
			if wb_aRoute[1] = wb_cMethod and wb_aRoute[2] = wb_cPath
				wb_cFound = wb_aRoute[3]
				exit
			ok
		next
		if wb_cFound = ""
			wb_cFound = wb_cNotFound
		ok
		xWebResponse = [404,"text/plain","Not found: " + wb_cMethod + " " + wb_cPath]
		if wb_cFound != ""
			try
				call wb_cFound()
			catch
				xWebResponse = [500,"text/plain","Error: " + cCatchError]
			done
		ok
		sendResponse(xWebResponse)
		return true

	func sendResponse  xResponse
		if isstring(xResponse)
			oWebRequest.respond(200,"text/html",xResponse)
		but islist(xResponse) and len(xResponse) = 3
			oWebRequest.respond(xResponse[1],xResponse[2],xResponse[3])
		else
			oWebRequest.respond(500,"text/plain","The handler must return a text or [status, contentType, text]")
		ok

	func run
		wb_lRunning = true
		while wb_lRunning
			serveOne(100)
		end

	func stop
		wb_lRunning = false

	func close
		wb_lRunning = false
		dnRequest("call",[wb_oServer,"Stop"])

# Compile once a function that calls the handler with the current request (see dnCallback)
func webWrapper  cHandler
	wb_nPos = find(aDotNetCallbacks,"web:" + cHandler,1)
	if wb_nPos = 0
		wb_cName = "dnweb" + (len(aDotNetCallbacks) + 1)
		eval("func " + wb_cName + nl + "xWebResponse = " + cHandler + "(oWebRequest)" + nl)
		aDotNetCallbacks + ["web:" + cHandler,wb_cName]
		wb_nPos = len(aDotNetCallbacks)
	ok
	return aDotNetCallbacks[wb_nPos][2]
