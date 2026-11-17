# A small web application written in Ring on ASP.NET Core: a to-do list with a web page and a JSON API
#   ring main.ring            then open http://localhost:5080/
#   GET /api/todos   POST /api/todos (the text is the body)   DELETE /api/todos?id=1

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseWeb()
using {
	"System"
	"System.Net.Http"
	"System.Threading.Tasks"
}

aTodos = []		# [id, text]
nNextId = 1
oServer = ""
oClient = ""
cUrl = ""

func main
	cAddress = "http://localhost:5080"
	if uiSelfTestWeb()
		cAddress = "http://127.0.0.1:0"
	ok
	oServer = new WebServer(cAddress)
	oServer.onGet("/","page")
	oServer.onGet("/api/todos","listTodos")
	oServer.onPost("/api/todos","addTodo")
	oServer.onDelete("/api/todos","deleteTodo")
	cUrl = oServer.url()
	if uiSelfTestWeb()
		selfTest()
	else
		? "Serving " + cUrl + "  (Ctrl+C to stop)"
		oServer.run()
	ok

func uiSelfTestWeb
	return find(sysargv,"--selftest") > 0

# ---------------------------------------------------------------- handlers

func page oRequest
	cHtml = "<html><body><h1>To-do list</h1><ul>"
	for aTodo in aTodos
		cHtml += "<li>" + aTodo[2] + " <a href='/api/todos?id=" + aTodo[1] + "'>(json)</a></li>"
	next
	cHtml += "</ul><p>POST /api/todos adds one, DELETE /api/todos?id=N removes one.</p></body></html>"
	return cHtml

func listTodos oRequest
	aList = []
	for aTodo in aTodos
		aList + [["id",aTodo[1]],["text",aTodo[2]]]
	next
	return webJson(aList)

func addTodo oRequest
	cText = trim(oRequest.body())
	if cText = ""
		return [400,"text/plain","The text of the to-do is empty"]
	ok
	aTodos + [nNextId,cText]
	nNextId++
	return [201,"text/plain","added " + (nNextId - 1)]

func deleteTodo oRequest
	nId = number(oRequest.query("id"))
	for nIndex = 1 to len(aTodos)
		if aTodos[nIndex][1] = nId
			del(aTodos,nIndex)
			return [200,"text/plain","deleted " + nId]
		ok
	next
	return [404,"text/plain","There is no to-do " + nId]

# ---------------------------------------------------------------- self test: a .NET client talks to the server

func request cMethod, cPath, cBody
	oMessage = dnNew@("HttpRequestMessage",[ :method = new HttpMethod(cMethod), :requestUri = cUrl + cPath ])
	if cBody != ""
		oMessage.Content = new StringContent(cBody)
	ok
	oClient = new HttpClient()
	oTask = oClient.SendAsync(oMessage)
	for nTry = 1 to 50
		if oServer.serveOne(100)
			exit
		ok
	next
	oTask.Wait()
	oResponse = oTask.getProp("Result")
	oBody = oResponse.Content.ReadAsStringAsync()
	oBody.Wait()
	return [statusNumber(oResponse.StatusCode),oBody.getProp("Result")]

# enums are strings: the status names the example uses
func statusNumber cName
	switch cName
	on "OK"			return 200
	on "Created"		return 201
	on "BadRequest"		return 400
	on "NotFound"		return 404
	off
	return 0

func selfTest
	aResult = request("GET","/api/todos","")
	dnAssert("empty list",aResult[2],"[]")
	aResult = request("POST","/api/todos","write Ring code")
	dnAssert("created",aResult[1],201)
	request("POST","/api/todos","call ASP.NET")
	aResult = request("POST","/api/todos","   ")
	dnAssert("empty text is a 400",aResult[1],400)
	aResult = request("GET","/api/todos","")
	dnAssert("the JSON list",aResult[2],'[{"id":1,"text":"write Ring code"},{"id":2,"text":"call ASP.NET"}]')
	aResult = request("DELETE","/api/todos?id=1","")
	dnAssert("deleted",aResult[2],"deleted 1")
	aResult = request("DELETE","/api/todos?id=9","")
	dnAssert("missing is a 404",aResult[1],404)
	aResult = request("GET","/","")
	dnAssert("the web page lists the to-do",substr(aResult[2],"call ASP.NET") > 0,True)
	oServer.close()
	? "SELFTEST " + iif(nDotNetFail = 0,"OK (" + nDotNetPass + " checks)","FAILED")

func iif lCondition, xYes, xNo
	if lCondition
		return xYes
	ok
	return xNo
