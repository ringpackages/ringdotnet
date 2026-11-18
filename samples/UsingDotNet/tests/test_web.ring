# ASP.NET Core: a Kestrel web server whose requests are handled by Ring functions
load "dotnet.ring"
dnUseWeb()
dnImport("System")
dnImport("System.Net.Http")
dnImport("System.Threading.Tasks")
dnImport("System.Text")
dnImport("Microsoft.AspNetCore.Http")
dnImport("Microsoft.Net.Http.Headers")

oServer = ""
oClient = ""
cUrl = ""

func main
	oServer = new WebServer("http://127.0.0.1:0")
	oServer.onGet("/","home")
	oServer.onGet("/api/info","apiInfo")
	oServer.onPost("/api/echo","echo")
	oServer.onGet("/search","search")
	oServer.onGet("/boom","boom")
	oServer.onGet("/ctx","ctxInfo")
	oServer.onPost("/form","formInfo")
	oClient = new HttpClient()
	cUrl = oServer.url()
	dnAssert("the server got a real port",substr(cUrl,"127.0.0.1:") > 0,1)

	dnAssert("GET /",fetch("GET","/",""),"<h1>Hello from Ring</h1>")
	dnAssert("JSON handler",fetch("GET","/api/info",""),'{"name":"ring","tags":["a","b"],"n":3}')
	dnAssert("POST body",fetch("POST","/api/echo","some data"),"you sent: some data")
	dnAssert("query string",fetch("GET","/search?q=dotnet&page=2",""),"q=dotnet page=2")
	dnAssert("not found",fetch("GET","/nothing",""),"Not found: GET /nothing")
	dnAssert("a handler error is a 500",left(fetch("GET","/boom",""),6),"Error:")
	dnAssert("the ASP.NET HttpContext is available to the handler",fetch("GET","/ctx?a=1",""),"GET /ctx http 127.0.0.1")
	dnAssert("an HTML form is read",fetchForm("/form","a=1&b=two+words"),"1,two words")
	dnAssert("requests served",oServer.nRequests,8)
	oServer.close()

	# ASP.NET types can be used on their own
	oPath = new PathString().New_1("/api/items")
	dnAssert("PathString",oPath.Value,"/api/items")
	dnAssert("PathString.StartsWithSegments",oPath.StartsWithSegments(new PathString().New_1("/api")),1)
	oQuery = new QueryString().Create_2("name","ring dotnet")
	dnAssert("QueryString encodes",oQuery.Value,"?name=ring%20dotnet")
	oMedia = new AspMediaTypeHeaderValue("text/html")
	dnAssert("MediaTypeHeaderValue",oMedia.MediaType.ToString(),"text/html")
	dnTestSummary()

# one request: the .NET client sends it in a task, the Ring thread serves it; returns the text of the response (any status)
func fetch cMethod, cPath, cBody
	if cMethod = "GET"
		oTask = oClient.GetAsync(cUrl + cPath)
	else
		oContent = new StringContent(cBody)
		oTask = oClient.PostAsync(cUrl + cPath,oContent)
	ok
	for nTry = 1 to 50
		if oServer.serveOne(100)
			exit
		ok
	next
	oTask.Wait(NULL)
	oResponse = oTask.getProp("Result")
	oBody = oResponse.Content.ReadAsStringAsync(NULL)
	oBody.Wait(NULL)
	return oBody.getProp("Result")

func home oRequest
	return "<h1>Hello from Ring</h1>"

func apiInfo oRequest
	return webJson([["name","ring"],["tags",["a","b"]],["n",3]])

func echo oRequest
	return [200,"text/plain","you sent: " + oRequest.body()]

func search oRequest
	return "q=" + oRequest.query("q") + " page=" + oRequest.query("page")

func ctxInfo oRequest
	oContext = oRequest.context()
	return oContext.Request.Method + " " + oContext.Request.Path.Value + " " + oContext.Request.Scheme + " " + oContext.Request.Host.Host

func boom oRequest
	raise("something failed")

# a form post (application/x-www-form-urlencoded): oRequest.form("name") reads its fields
func fetchForm cPath, cForm
	oContent = dnNew("StringContent",[ :content = cForm, :encoding = new Encoding().UTF8, :mediaType = "application/x-www-form-urlencoded" ])
	oTask = oClient.PostAsync(cUrl + cPath,oContent)
	for nTry = 1 to 50
		if oServer.serveOne(100)
			exit
		ok
	next
	oTask.Wait(NULL)
	oBody = oTask.getProp("Result").Content.ReadAsStringAsync(NULL)
	oBody.Wait(NULL)
	return oBody.getProp("Result")

func formInfo oRequest
	return oRequest.form("a") + "," + oRequest.form("b")
