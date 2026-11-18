# Tutorial 16: a web service with a database - JSON over HTTP, stored with Entity Framework
load "dotnet.ring"
dnUseWeb()                                   # ASP.NET Core
dnUseData()                                  # Entity Framework
using {
	"System.Net.Http"
}

oServer = ""
oClient = ""
cUrl = ""
oDb = ""

func main
	# 1. The database: one table, kept in memory for this tutorial (use "Data Source=notes.db" for a file)
	oDb = new RingDatabase("Data Source=:memory:",[
		["Notes",[["Id","int",1],["Text","string",0,[["required",1],["maxlength",200]]],["Done","int",0,[["default",0]]]]]
	])

	# 2. The web service: each address is a Ring function
	oServer = new WebServer("http://127.0.0.1:0")
	oServer.onGet("/notes","listNotes")
	oServer.onPost("/notes","addNote")
	oServer.onDelete("/notes","deleteNote")
	cUrl = oServer.url()

	# 3. A client uses the service (the same program, so that you can see the whole conversation)
	oClient = new HttpClient()
	? "POST /notes   -> " + send("POST","/notes","Buy milk")
	? "POST /notes   -> " + send("POST","/notes","Learn Ring and .NET")
	? "POST /notes   -> " + send("POST","/notes","")
	? "GET  /notes   -> " + send("GET","/notes","")
	? "DELETE        -> " + send("DELETE","/notes?id=1","")
	? "GET  /notes   -> " + send("GET","/notes","")
	? "DELETE (nothing)-> " + send("DELETE","/notes?id=99","")
	oServer.close()
	oDb.close()

# ---------------------------------------------------------------- the handlers

func listNotes oRequest
	aList = []
	for aRow in oDb.all("Notes")
		aList + [["id",dbValue(aRow,"Id")],["text",dbValue(aRow,"Text")]]
	next
	return webJson(aList)

func addNote oRequest
	cText = trim(oRequest.body())
	if cText = ""
		return [400,"text/plain","The text of the note is empty"]
	ok
	nId = oDb.insert("Notes",[["Text",cText]])
	return [201,"application/json",'{"id":' + nId + '}']

func deleteNote oRequest
	nId = number(oRequest.query("id"))
	if oDb.remove("Notes",nId) = 0
		return [404,"text/plain","There is no note " + nId]
	ok
	return [200,"text/plain","deleted " + nId]

# ---------------------------------------------------------------- the client

func send cMethod, cPath, cBody
	oMessage = dnNew("HttpRequestMessage",[ :method = new HttpMethod(cMethod), :requestUri = cUrl + cPath ])
	if cBody != ""
		oMessage.Content = new StringContent(cBody)
	ok
	oTask = oClient.SendAsync(oMessage)
	for nTry = 1 to 50
		if oServer.serveOne(100)
			exit
		ok
	next
	oTask.Wait(NULL)
	oResponse = oTask.getProp("Result")
	oBody = oResponse.Content.ReadAsStringAsync(NULL)
	oBody.Wait(NULL)
	return oResponse.StatusCode + " " + oBody.getProp("Result")
