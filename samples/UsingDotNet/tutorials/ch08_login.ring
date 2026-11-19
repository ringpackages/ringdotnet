# login, sessions and cookies - a web site that knows who you are
load "dotnet.ring"
using {
	"System"
	"System.Net.Http"
	"System.Security.Cryptography"
	"System.Text"
	"RingDotNet.Web"
	"RingDotNet.Data"
}

oServer = ""
oClient = ""
cUrl = ""
oDb = ""
aSessions = []            # [token, user name]: who is logged in

func main
	# THE USERS: a table; the password is never stored, only a salted slow hash of it (the tutorial "Hashing and encryption")
	oDb = new RingDatabase("Data Source=:memory:",[
		["Users",[["Id","int",1],["Name","string",0,[["required",1],["unique",1]]],["Salt","string",0],["Hash","string",0]]]
	])

	oServer = new WebServer("http://127.0.0.1:0")
	oServer.onPost("/register","registerUser")
	oServer.onPost("/login","loginUser")
	oServer.onGet("/profile","profilePage")
	oServer.onPost("/logout","logoutUser")
	cUrl = oServer.url()
	oClient = new HttpClient()

	# A browser would keep the cookie by itself; this test client keeps it in the variable cCookie.
	cCookie = ""
	aResult = visit("POST","/register","name=ann&password=s3cret",cCookie)
	? "register ann              -> " + aResult[1] + " " + aResult[2]
	aResult = visit("POST","/register","name=ann&password=other",cCookie)
	? "register ann again        -> " + aResult[1] + " " + aResult[2]
	aResult = visit("GET","/profile","",cCookie)
	? "profile, not logged in    -> " + aResult[1] + " " + aResult[2]
	aResult = visit("POST","/login","name=ann&password=wrong",cCookie)
	? "login, wrong password     -> " + aResult[1] + " " + aResult[2]
	aResult = visit("POST","/login","name=ann&password=s3cret",cCookie)
	? "login, right password     -> " + aResult[1] + " " + aResult[2] + "   (a cookie was sent: " + (len(aResult[3]) > 0) + ")"
	cCookie = aResult[3]
	aResult = visit("GET","/profile","",cCookie)
	? "profile, with the cookie  -> " + aResult[1] + " " + aResult[2]
	aResult = visit("POST","/logout","",cCookie)
	? "logout                    -> " + aResult[1] + " " + aResult[2]
	aResult = visit("GET","/profile","",cCookie)
	? "profile, old cookie       -> " + aResult[1] + " " + aResult[2]
	oServer.close()

# ---------------------------------------------------------------- the handlers

func registerUser oRequest
	cName = lower(trim(oRequest.form("name")))
	cPassword = oRequest.form("password")
	if cName = "" or len(cPassword) < 4
		return [400,"text/plain","name and a password of 4 or more characters are required"]
	ok
	cSalt = randomHex(16)
	try
		oDb.insert("Users",[["Name",cName],["Salt",cSalt],["Hash",hashPassword(cPassword,cSalt)]])
	catch
		return [409,"text/plain","that name is taken"]
	done
	return [201,"text/plain","welcome, " + cName]

func loginUser oRequest
	cName = lower(trim(oRequest.form("name")))
	aUsers = oDb.where("Users","Name = {0}",[cName])
	# the same answer for a wrong name and a wrong password: do not tell an attacker which one was wrong
	if len(aUsers) = 0 or hashPassword(oRequest.form("password"),dbValue(aUsers[1],"Salt")) != dbValue(aUsers[1],"Hash")
		return [401,"text/plain","wrong name or password"]
	ok
	cToken = randomHex(16)
	aSessions + [cToken,cName]
	# the cookie: the browser sends it back with every later request. HttpOnly: scripts in the page can not read it.
	oRequest.setHeader("Set-Cookie","session=" + cToken + "; HttpOnly; Path=/")
	return [200,"text/plain","logged in as " + cName]

func profilePage oRequest
	cUser = userOf(oRequest)
	if cUser = ""
		return [401,"text/plain","please log in"]
	ok
	return [200,"text/plain","this is the profile of " + cUser]

func logoutUser oRequest
	cToken = tokenOf(oRequest)
	for nIndex = 1 to len(aSessions)
		if aSessions[nIndex][1] = cToken
			del(aSessions,nIndex)
			exit
		ok
	next
	oRequest.setHeader("Set-Cookie","session=; Max-Age=0; Path=/")
	return [200,"text/plain","logged out"]

# ---------------------------------------------------------------- sessions

# the token in the "Cookie" header of the request: "session=abc123; other=1"
func tokenOf oRequest
	cHeader = oRequest.header("Cookie")
	for cPart in str2list(substr(cHeader,";",nl))
		cPart = trim(cPart)
		if left(cPart,8) = "session="
			return substr(cPart,9)
		ok
	next
	return ""

# the user name of a session, or "" when the cookie is missing or unknown
func userOf oRequest
	cToken = tokenOf(oRequest)
	if cToken = ""
		return ""
	ok
	for aSession in aSessions
		if aSession[1] = cToken
			return aSession[2]
		ok
	next
	return ""

# ---------------------------------------------------------------- passwords and tokens (see the tutorial "Hashing and encryption")

func randomHex nBytes
	return lower(new Convert().ToHexString(new RandomNumberGenerator().GetBytes(nBytes)))

func hashPassword cPassword, cSalt
	oDerive = dnNew("Rfc2898DeriveBytes",[ :password = cPassword, :salt = cSalt, :iterations = 10000, :hashAlgorithm = new HashAlgorithmName().SHA256 ])
	return lower(new Convert().ToHexString(oDerive.GetBytes(32)))

# ---------------------------------------------------------------- the test client

# send a request (with the cookie when there is one); returns [status, body, the cookie that the server sent, if any]
func visit cMethod, cPath, cForm, cCookie
	oMessage = new HttpRequestMessage().New_([ :method = new HttpMethod(cMethod), :requestUri = cUrl + cPath ])
	if cForm != ""
		oContent = dnNew("StringContent",[ :content = cForm, :encoding = new Encoding().UTF8, :mediaType = "application/x-www-form-urlencoded" ])
		oMessage.Content = oContent
	ok
	if cCookie != ""
		oMessage.Headers.Add("Cookie",cCookie)
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
	# the cookie: the "Set-Cookie" header of the response, up to the first ";"
	cNewCookie = ""
	aFound = oResponse.Headers.TryGetValues("Set-Cookie")
	if aFound[1]
		cValue = aFound[2].toList()[1]
		cNewCookie = trim(str2list(substr(cValue,";",nl))[1])
	ok
	return [oResponse.StatusCode,oBody.Result,cNewCookie]
