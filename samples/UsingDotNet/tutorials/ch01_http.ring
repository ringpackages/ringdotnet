# HTTP - a web server and a web client in one program
load "dotnet.ring"
using {
	"System.Net.Http"
	"System.Threading.Tasks"
	"RingDotNet.Web"
}

oServer = ""
oClient = ""
cUrl = ""

func main
	# 1. A web server: a Ring function answers each address
	oServer = new WebServer("http://127.0.0.1:0")          # port 0: Windows picks a free port
	oServer.onGet("/hello","hello")
	oServer.onGet("/time","clock")
	oServer.onPost("/echo","echo")
	cUrl = oServer.url()
	? "The server listens at " + cUrl

	# 2. A web client: HttpClient sends requests. Asking is asynchronous: it returns a Task
	oClient = new HttpClient()
	? nl + "GET /hello  -> " + fetch("GET","/hello","")
	? "GET /time   -> " + fetch("GET","/time","")
	? "POST /echo  -> " + fetch("POST","/echo","some data")
	? "GET /nothing-> " + fetch("GET","/nothing","")
	oServer.close()

# The handlers: each gets the request and returns the answer
func hello oRequest
	return "Hello from a Ring handler"

func clock oRequest
	return webJson([["hour",12],["minute",30]])

func echo oRequest
	return [201,"text/plain","you sent: " + oRequest.body()]

# Send one request and return the answer. The server runs on .NET threads, but Ring code may only run on the Ring thread:
# serveOne() hands one waiting request to its Ring handler.
func fetch cMethod, cPath, cBody
	if cMethod = "GET"
		oTask = oClient.GetAsync(cUrl + cPath)
	else
		oContent = new StringContent(cBody)
		oTask = oClient.PostAsync([ :requestUri = cUrl + cPath, :content = oContent ])
	ok
	for nTry = 1 to 50
		if oServer.serveOne(100)
			exit
		ok
	next
	oTask.Wait(NULL)
	oResponse = oTask.Result
	oBody = oResponse.Content.ReadAsStringAsync(NULL)
	oBody.Wait(NULL)
	return oResponse.StatusCode + " " + oBody.Result
