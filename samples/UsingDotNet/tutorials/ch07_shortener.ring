# a project: a link shortener - a web service that makes short codes, redirects with 302, counts the visits and refuses bad addresses
load "dotnet.ring"

using {
	"System"
	"System.Net.Http"
	"System.Text"
	"RingDotNet.Web"
}

oServer = ""
oClient = ""
cUrl = ""
aLinks = []                       # [code, address, visits]
nCounter = 1000                   # the next number to turn into a code

func main

	oServer = new WebServer("http://127.0.0.1:0")
	oServer.onPost("/shorten","shorten")
	oServer.onGet("/stats","statsOverview")
	oServer.notFound("visit")                    # any other address is a short code
	cUrl = oServer.url()

	# The client does NOT follow redirects, so that the test can see the answer 302 and its Location header
	oHandler = new HttpClientHandler()
	oHandler.AllowAutoRedirect = False
	oClient = new HttpClient
	oClient.@New(oHandler)

	# 1. A code is a number written in base 62 (0-9, a-z, A-Z): short and made of safe characters. The numbers start at 1000 so that the
	#    codes have at least two characters.
	? "1. numbers as codes: 1000 -> " + toCode(1000) + ", 1001 -> " + toCode(1001) + ", 3844 -> " + toCode(3844) + ", 238328 -> " + toCode(238328)

	# 2. Make short links
	? nl + "2. POST /shorten"
	for cAddress in [ "https://example.com/a/very/long/address?with=parameters&and=more", "https://example.org/", "https://example.com/a/very/long/address?with=parameters&and=more" ]
		oUriType = new Uri
		aResult = post("/shorten","address=" + oUriType.EscapeDataString(cAddress))
		? "   " + aResult[1] + "  " + aResult[2]
	next

	# 3. Visit a short link: the answer is a redirect, and the header Location has the address
	? nl + "3. GET /" + toCode(1000) + " (a redirect: the client does not follow it)"
	aResult = fetch("/" + toCode(1000))
	? "   " + aResult[1] + ", Location: " + aResult[3]

	# 4. Visits are counted
	fetch("/" + toCode(1000))
	fetch("/" + toCode(1001))
	? nl + "4. GET /stats"
	aResult = fetch("/stats")
	? "   " + aResult[2]

	# 5. Errors: an unknown code is 404, a missing or bad address is 400, and the wrong method is not found
	? nl + "5. errors:"
	? "   GET /zzzz                   -> " + fetch("/zzzz")[1]
	? "   POST /shorten, no address   -> " + post("/shorten","")[1]
	? "   POST /shorten, not a URL    -> " + post("/shorten","address=hello+world")[1]
	oUriType = new Uri
	? "   POST /shorten, a script     -> " + post("/shorten","address=" + oUriType.EscapeDataString("javascript:alert(1)"))[1]
	oServer.close()

# ---------------------------------------------------------------- the service

# the code of a number: its digits in base 62
func toCode nNumber

	cDigits = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	cCode = ""
	n = nNumber
	while n > 0
		cCode = substr(cDigits,n % 62 + 1,1) + cCode
		n = floor(n / 62)
	end
	return cCode

# Only http and https addresses are accepted. An address like "javascript:..." in a redirect would run a script in the browser of
# the visitor: a shortener must check what it redirects to.
func isAllowed cAddress

	oUriType = new Uri
	oAbsolute = oUriType.TryCreate(cAddress,"Absolute")
	if not oAbsolute[1]
		return False
	ok
	cScheme = oAbsolute[2].Scheme
	return cScheme = "http" or cScheme = "https"

func shorten oRequest

	cAddress = trim(oRequest.form("address"))
	if cAddress = ""
		return [400,"text/plain","the field address is needed"]
	but not isAllowed(cAddress)
		return [400,"text/plain","the address must be a http or https address"]
	ok
	# the same address gets the same code
	for aLink in aLinks
		if aLink[2] = cAddress
			return [200,"text/plain",aLink[1] + "  (already known)"]
		ok
	next
	cCode = toCode(nCounter)
	nCounter++
	aLinks + [ cCode, cAddress, 0 ]
	return [201,"text/plain",cCode + "  " + shortAddress(cAddress)]

func shortAddress cAddress

	if len(cAddress) <= 28
		return cAddress
	ok
	return left(cAddress,25) + "..."

# any other path: its text after the first / is the code
func visit oRequest

	cCode = substr(oRequest.path(),2)
	for i = 1 to len(aLinks)
		if aLinks[i][1] = cCode
			aLinks[i][3] = aLinks[i][3] + 1
			oRequest.setHeader("Location",aLinks[i][2])
			return [302,"text/plain",""]
		ok
	next
	return [404,"text/plain","no such code"]

func statsOverview oRequest

	cText = ""
	for aLink in aLinks
		if cText != ""
			cText += "; "
		ok
		cText += aLink[1] + ": " + aLink[3] + " visits"
	next
	return cText

# ---------------------------------------------------------------- the client for the test

# one request is sent, the server answers it (serveOne), and the answer comes back as [status, text, location]
func fetch cPath

	return exchange(oClient.GetAsync(cUrl + cPath))

func post cPath,cForm

	oContent = new StringContent
	oContent.@New([ :content = cForm, :encoding = new UTF8Encoding(), :mediaType = "application/x-www-form-urlencoded" ])
	return exchange(oClient.PostAsync([ :requestUri = cUrl + cPath, :content = oContent ]))

func exchange oTask

	for nTry = 1 to 50
		if oServer.serveOne(100)
			exit
		ok
	next
	oTask.Wait(NULL)
	oResponse = oTask.Result
	oBody = oResponse.Content.ReadAsStringAsync(NULL)
	oBody.Wait(NULL)
	cLocation = ""
	aFound = oResponse.Headers.TryGetValues("Location")
	if aFound[1]
		cLocation = aFound[2].toList()[1]
	ok
	return [ "" + oResponse.StatusCode, oBody.Result, cLocation ]
