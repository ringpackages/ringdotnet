# Tutorial 56: a tiny web framework - routes with parameters (/users/:id), templates ({{name}}) and one catch-all handler
load "dotnet.ring"
dnUseWeb()
using {
	"System.Net"
	"System.Net.Http"
}

oServer = ""
oClient = ""
oRouter = ""

func main
	oServer = new WebServer("http://127.0.0.1:0")
	oRouter = new Router()
	oRouter.add("GET","/","homePage")
	oRouter.add("GET","/users/:name","userPage")
	oRouter.add("GET","/users/:name/posts/:id","postPage")
	oServer.notFound("dispatch")                  # every request that has no ordinary route comes here: the router decides
	oClient = new HttpClient()
	oClient.Timeout = new TimeSpan().FromSeconds(5)
	for cPath in ["/","/users/ali","/users/sara/posts/7","/users/<b>sara","/nothing/here"]
		aAnswer = fetch(cPath)
		? padRight(cPath,22) + aAnswer[1] + "  " + aAnswer[2]
	next
	oServer.close()

func padRight cText, nWidth
	while len(cText) < nWidth
		cText += " "
	end
	return cText

# ---------------------------------------------------------------- the framework

# the one handler of the web server: it asks the router
func dispatch oRequest
	aMatch = oRouter.find(oRequest.method(),oRequest.path())
	if len(aMatch) = 0
		return [404,"text/plain","no page " + oRequest.path()]
	ok
	cHandler = aMatch[1]
	aParams = aMatch[2]
	return call cHandler(oRequest,aParams)

# a template: {{name}} is replaced by the value, with HTML characters escaped
func render cTemplate, aValues
	for aPair in aValues
		cTemplate = substr(cTemplate,"{{" + aPair[1] + "}}",escape(aPair[2]))
	next
	return [200,"text/html",cTemplate]

func escape cText
	cText = substr(cText,"&","&amp;")
	cText = substr(cText,"<","&lt;")
	cText = substr(cText,">","&gt;")
	return cText

# ---------------------------------------------------------------- the pages

func homePage oRequest, aParams
	return render("<h1>Welcome</h1>",[])

func userPage oRequest, aParams
	return render("<h1>User {{name}}</h1>",aParams)

func postPage oRequest, aParams
	return render("<h1>Post {{id}} of {{name}}</h1>",aParams)

# ---------------------------------------------------------------- a test client

func fetch cPath
	oTask = oClient.GetAsync(oServer.url() + cPath)
	for nTry = 1 to 50
		if oServer.serveOne(100)
			exit
		ok
	next
	oTask.Wait(NULL)
	oResponse = oTask.getProp("Result")
	oBody = oResponse.Content.ReadAsStringAsync(NULL)
	oBody.Wait(NULL)
	return [oResponse.StatusCode,oBody.getProp("Result")]

# "/users/ali" -> ["", "users", "ali"]
func splitPath cText
	return str2list(substr(cText,"/",nl))

# ---------------------------------------------------------------- the router (a class goes last: functions after it would belong to it)

class Router

	aRoutes = []              # [method, [parts of the pattern], handler name]

	func init
		return self

	func add cMethod, cPattern, cHandler
		aRoutes + [cMethod,splitPath(cPattern),cHandler]

	# the first route that fits: returns [handler, [[parameter name, value], ...]] or an empty list
	func find cMethod, cPath
		aParts = splitPath(cPath)
		for aRoute in aRoutes
			if aRoute[1] = cMethod and len(aRoute[2]) = len(aParts)
				aParams = matchParts(aRoute[2],aParts)
				if islist(aParams)
					return [aRoute[3],aParams]
				ok
			ok
		next
		return []

	# a part that starts with : is a parameter, the other parts must be equal
	func matchParts aPattern, aParts
		aParams = []
		for nIndex = 1 to len(aPattern)
			cWanted = aPattern[nIndex]
			if left(cWanted,1) = ":"
				aParams + [substr(cWanted,2),aParts[nIndex]]
			but cWanted != aParts[nIndex]
				return false
			ok
		next
		return aParams
