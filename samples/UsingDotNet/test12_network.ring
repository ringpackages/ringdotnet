load "dotnetlib.ring"
using {
	"System"
	"System.Text"
	"System.Net"
	"System.Net.Http"
	"System.Threading.Tasks"
}

# A tiny web server and client in one Ring program: .NET runs the requests on its thread pool,
# Ring waits for the tasks and answers
cPrefix = "http://localhost:" + (20000 + random(20000)) + "/"
oServer = new HttpListener()
oServer.Prefixes.Add(cPrefix)
oServer.Start()
? "Listening on " + cPrefix

oWaiting = oServer.GetContextAsync()
oClient = new HttpClient()
oRequest = oClient.GetStringAsync(cPrefix + "greet?name=Ring")

oWaiting.Wait(NULL)
oContext = oWaiting.getProp("Result")
? "Request        : " + oContext.Request.HttpMethod + " " + oContext.Request.Url.PathAndQuery
cReply = "Hello " + oContext.Request.QueryString.Item("name") + ", this is .NET speaking Ring!"
aBytes = new UTF8Encoding().GetBytes(cReply)
oContext.Response.OutputStream.Write(aBytes,0,len(aBytes))
oContext.Response.Close(NULL)

oRequest.Wait(NULL)
? "Response       : " + oRequest.getProp("Result")
oServer.Stop()

# URL and address helpers
? "UrlEncode      : " + new WebUtility().UrlEncode("ring & .net = fun")
? "Loopback       : " + new IPAddress().Loopback.ToString()
? "Host name set  : " + (len(new Dns().GetHostName()) > 0)
