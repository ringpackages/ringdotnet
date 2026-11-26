# a small web site - HTML pages, a form, links and a guestbook (ASP.NET Core)
load "dotnet.ring"

using {
	"System.Net.Http"
	"System.Text"
	"RingDotNet.Web"
}

oServer = ""
oClient = ""
cUrl = ""
aEntries = []                 # the guestbook: [name, message]

# Run it as a web site:   ring ch07_website.ring --serve     then open http://localhost:5090/
func main

	cAddress = "http://127.0.0.1:0"
	if find(sysargv,"--serve") > 0
		cAddress = "http://localhost:5090"
	ok
	oServer = new WebServer(cAddress)
	oServer.onGet("/","homePage")
	oServer.onGet("/guestbook","guestbookPage")
	oServer.onPost("/guestbook","signGuestbook")
	oServer.onGet("/about","aboutPage")
	cUrl = oServer.url()

	if find(sysargv,"--serve") > 0
		? "Open " + cUrl + "   (Ctrl+C to stop)"
		oServer.run()
		return
	ok

	# a test: a client visits the pages
	oClient = new HttpClient()
	? "GET /           -> " + summary(fetchPage("/"))
	? "GET /about      -> " + summary(fetchPage("/about"))
	? "POST /guestbook -> " + summary(postForm("/guestbook","name=Ann&message=Hello+from+Ann"))
	? "POST /guestbook -> " + summary(postForm("/guestbook","name=&message=no+name"))
	? "GET /guestbook  -> " + summary(fetchPage("/guestbook"))
	? "entries stored  : " + len(aEntries)
	oServer.close()

# ---------------------------------------------------------------- the pages

# every page has the same frame: a function builds it
func page cTitle, cBody

	return "<html><head><title>" + cTitle + "</title><style>body{font-family:Segoe UI,Arial;max-width:560px;margin:30px auto;color:#222}" +
		"nav a{margin-right:14px}h1{color:#5b3fd1}.entry{border-left:4px solid #5b3fd1;padding:4px 10px;margin:8px 0}</style></head><body>" +
		"<nav><a href='/'>Home</a><a href='/guestbook'>Guestbook</a><a href='/about'>About</a></nav>" +
		"<h1>" + cTitle + "</h1>" + cBody + "</body></html>"

func homePage oRequest

	return page("Welcome","<p>This site is written in Ring and served by ASP.NET Core.</p><p>Visit the <a href='/guestbook'>guestbook</a>.</p>")

func aboutPage oRequest

	return page("About","<p>" + len(aEntries) + " entries so far.</p>")

func guestbookPage oRequest

	cList = ""
	for aEntry in aEntries
		cList += "<div class='entry'><b>" + htmlText(aEntry[1]) + "</b><br>" + htmlText(aEntry[2]) + "</div>"
	next
	if cList = ""
		cList = "<p>No entries yet. Be the first!</p>"
	ok
	cForm = "<h2>Sign</h2><form method='post' action='/guestbook'>" +
		"<p><input name='name' placeholder='Your name'></p>" +
		"<p><textarea name='message' placeholder='Your message' rows='3' cols='40'></textarea></p>" +
		"<p><button type='submit'>Send</button></p></form>"
	return page("Guestbook",cList + cForm)

func signGuestbook oRequest

	cName = trim(oRequest.form("name"))
	cMessage = trim(oRequest.form("message"))
	if cName = "" or cMessage = ""
		return [400,"text/html",page("Oops","<p>Please give a name and a message.</p><p><a href='/guestbook'>Back</a></p>")]
	ok
	aEntries + [cName,cMessage]
	return [200,"text/html",page("Thank you","<p>Thanks, " + htmlText(cName) + "!</p><p><a href='/guestbook'>See the guestbook</a></p>")]

# NEVER put text typed by a visitor into HTML as it is: "<script>" would run in other visitors' browsers.
func htmlText cText

	cText = substr(cText,"&","&amp;")
	cText = substr(cText,"<","&lt;")
	return substr(cText,">","&gt;")

# ---------------------------------------------------------------- a client for the test

func fetchPage cPath

	return send(oClient.GetAsync(cUrl + cPath))

func postForm cPath, cForm

	return send(oClient.PostAsync([ :requestUri = cUrl + cPath, :content = (new StringContent).@New([ :content = cForm, :encoding = new Encoding().UTF8, :mediaType = "application/x-www-form-urlencoded" ]) ]))

func send oTask

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

func summary aResult

	cBody = aResult[2]
	nStart = substr(cBody,"<h1>")
	cTitle = ""
	if nStart > 0
		cTitle = substr(cBody,nStart + 4,substr(cBody,"</h1>") - nStart - 4)
	ok
	return aResult[1] + ", page title '" + cTitle + "', " + len(cBody) + " characters"
