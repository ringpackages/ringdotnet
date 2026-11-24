# a REST client - call a JSON service, read the answer, handle the errors
#   (the service is started in the same program so that the tutorial needs no internet)
load "dotnet.ring"

using {
	"System.Net.Http"
	"System.Text"
	"System.Text.Json"
	"RingDotNet.Web"
}

oServer = ""
oClient = ""
cUrl = ""
aBooks = [[1,"The Hobbit",1937],[2,"Dune",1965],[3,"Neuromancer",1984]]

func main

	# --- the service (a stand-in for a real one on the internet)
	oServer = new WebServer("http://127.0.0.1:0")
	oServer.onGet("/api/books","listBooks")
	oServer.onGet("/api/book","oneBook")
	oServer.onPost("/api/books","addBook")
	cUrl = oServer.url()

	# --- the client
	oClient = new HttpClient()
	oClient.Timeout = new TimeSpan().FromSeconds(5)          # never wait forever for a server

	# 1. GET a list: read the JSON array
	aAnswer = request("GET","/api/books","")
	? "1. GET /api/books -> status " + aAnswer[1]
	oDocument = new JsonDocument().Parse(aAnswer[2])
	oList = oDocument.RootElement
	nLastIndex = oList.GetArrayLength() - 1
	for nIndex = 0 to nLastIndex
		oBook = oList.Item(nIndex)
		? "   " + oBook.GetProperty("id").GetInt32() + "  " + oBook.GetProperty("title").GetString() + " (" + oBook.GetProperty("year").GetInt32() + ")"
	next
	oDocument.Dispose()

	# 2. GET one item, with a query string
	aAnswer = request("GET","/api/book?id=2","")
	? nl + "2. GET /api/book?id=2 -> status " + aAnswer[1] + ", body " + aAnswer[2]

	# 3. An item that does not exist: the status says so, and the client must look at it
	aAnswer = request("GET","/api/book?id=99","")
	? nl + "3. GET /api/book?id=99 -> status " + aAnswer[1]
	if aAnswer[1] != "OK"
		? "   the service said: " + aAnswer[2]
	ok

	# 4. POST new data as JSON
	aAnswer = request("POST","/api/books",'{"title":"Foundation","year":1951}')
	? nl + "4. POST a new book -> status " + aAnswer[1] + ", body " + aAnswer[2]
	aAnswer = request("GET","/api/books","")
	? "   the list has now " + new JsonDocument().Parse(aAnswer[2]).RootElement.GetArrayLength() + " books"

	# 5. A service that is not there: the client raises an error that you catch (and then you tell the user)
	try
		new HttpClient().GetAsync("http://127.0.0.1:1/").Wait(NULL)
		? nl + "5. (unexpected: the call worked)"
	catch
		? nl + "5. No server at that address: the call raised an error, the program goes on"
	done
	oServer.close()

# ---------------------------------------------------------------- the service

func listBooks oRequest

	aList = []
	for aBook in aBooks
		aList + [["id",aBook[1]],["title",aBook[2]],["year",aBook[3]]]
	next
	return webJson(aList)

func oneBook oRequest

	nId = number(oRequest.query("id"))
	for aBook in aBooks
		if aBook[1] = nId
			return webJson([["id",aBook[1]],["title",aBook[2]],["year",aBook[3]]])
		ok
	next
	return [404,"text/plain","no book " + nId]

func addBook oRequest

	oDocument = new JsonDocument().Parse(oRequest.body())
	oRoot = oDocument.RootElement
	nId = len(aBooks) + 1
	aBooks + [nId,oRoot.GetProperty("title").GetString(),oRoot.GetProperty("year").GetInt32()]
	oDocument.Dispose()
	return [201,"application/json",'{"id":' + nId + '}']

# ---------------------------------------------------------------- the client's helper: send, wait, return [status, body]

func request cMethod, cPath, cBody

	oMessage = new HttpRequestMessage().@New([ :method = new HttpMethod(cMethod), :requestUri = cUrl + cPath ])
	if cBody != ""
		oContent = dnNew("StringContent",[ :content = cBody, :encoding = new Encoding().UTF8, :mediaType = "application/json" ])
		oMessage.Content = oContent
	ok
	oTask = oClient.SendAsync(oMessage)
	for nTry = 1 to 50
		if oServer.serveOne(100)
			exit
		ok
	next
	oTask.Wait(NULL)
	oResponse = oTask.Result
	oBody = oResponse.Content.ReadAsStringAsync(NULL)
	oBody.Wait(NULL)
	return [oResponse.StatusCode,oBody.Result]
