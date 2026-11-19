# HttpClient in depth - headers both ways, status codes, errors, time limits, cancelling and saving a download
#   (a small server runs inside the program, so no internet is needed; the client code is what you write for a real service)
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Net.Http"
	"System.Threading"
	"RingDotNet.Web"
}

oServer = ""
oClient = ""

func main
	oServer = new WebServer("http://127.0.0.1:0")
	oServer.onGet("/echo","echoPage")
	oServer.onGet("/status","statusPage")
	oServer.onGet("/slow","slowPage")
	oServer.onGet("/file","filePage")

	# One HttpClient for the whole program: it keeps connections open. DefaultRequestHeaders are sent with EVERY request.
	oClient = new HttpClient()
	oClient.Timeout = new TimeSpan().FromSeconds(10)
	oClient.DefaultRequestHeaders.Add("X-Client","ringdotnet-tutorial")
	oClient.DefaultRequestHeaders.Add("Accept","text/plain")

	# 1. Headers in both directions. The client sent X-Client; the server answers with its own header X-Server and a content type.
	oResponse = fetchPage("/echo?name=Ann")
	? "1. status: " + oResponse.StatusCode + ", body: " + bodyOf(oResponse)
	? "   the server's header X-Server: " + oResponse.Headers.GetValues("X-Server").toList()[1]
	? "   content type: " + oResponse.Content.Headers.ContentType.ToString()

	# 2. Status codes. A code of the 200s means success; anything else is an ANSWER, not an error: the call itself worked.
	? nl + "2. what the server says for different codes:"
	for nCode in [200,201,404,500]
		oResponse = fetchPage("/status?code=" + nCode)
		? "   " + nCode + " -> " + oResponse.StatusCode + " (" + oResponse.ReasonPhrase + "), success: " + yesNo(oResponse.IsSuccessStatusCode)
	next

	# 3. EnsureSuccessStatusCode turns a bad status into an error. Use it when "not OK" means "stop here".
	oResponse = fetchPage("/status?code=404")
	try
		oResponse.EnsureSuccessStatusCode()
		? nl + "3. (no error)"
	catch
		? nl + "3. EnsureSuccessStatusCode raised: " + substr(left(cCatchError,70),nl," ")
	done

	# 4. Cancelling. A request that takes too long can be cancelled: CancelAfter(ms) on a CancellationTokenSource, and its Token goes
	#    with the request. The slow page is never served (nobody calls serveOne), so the request has to be cancelled.
	oSource = new CancellationTokenSource()
	oSource.CancelAfter(300)
	oTask = oClient.GetAsync([ :requestUri = oServer.url() + "/slow", :cancellationToken = oSource.Token ])
	lCancelled = False
	try
		oTask.Wait(NULL)
	catch
		lCancelled = True
	done
	? nl + "4. a request cancelled after 300 ms: cancelled = " + yesNo(lCancelled) + ", the task says cancelled: " + yesNo(oTask.IsCanceled)
	oSource.Dispose()

	# 5. Save a download to a file: copy the content to a FileStream. The whole body is never held in memory.
	cFile = new Path().Combine([new Path().GetTempPath(),"tutorial84.txt"])
	oResponse = fetchPage("/file")
	oStream = new File().Create(cFile)
	oCopy = oResponse.Content.CopyToAsync(oStream)
	oCopy.Wait(NULL)
	oStream.Dispose()
	? nl + "5. the download was saved: " + new FileInfo(cFile).Length + " bytes, the first line is '" + new File().ReadAllLines(cFile).toList()[1] + "'"
	new File().Delete(cFile)

	oServer.close()

# send a GET request, serve it (the server lives in this program) and return the HttpResponseMessage
func fetchPage cPath
	oTask = oClient.GetAsync(oServer.url() + cPath)
	for nTry = 1 to 100
		oServer.serveOne(50)                   # serve what is waiting (also requests that nobody waits for any more)
		if oTask.IsCompleted
			exit
		ok
	next
	oTask.Wait(NULL)
	return oTask.Result

func bodyOf oResponse
	oBody = oResponse.Content.ReadAsStringAsync(NULL)
	oBody.Wait(NULL)
	return oBody.Result

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"

# ---------------------------------------------------------------- the pages of the little server

func echoPage oRequest
	oRequest.setHeader("X-Server","ring")
	return [200,"text/plain","hello " + oRequest.query("name") + ", your header X-Client was: " + oRequest.header("X-Client")]

func statusPage oRequest
	return [number(oRequest.query("code")),"text/plain","status page"]

func slowPage oRequest
	return [200,"text/plain","never sent"]

func filePage oRequest
	cText = "first line of the file" + nl
	for nLine = 2 to 400
		cText += "line number " + nLine + " of a long file" + nl
	next
	return [200,"text/plain",cText]
