# MockHttp: a fake HTTP server inside the program (MockHttpMessageHandler): the HttpClient it makes answers what the test says, and the test counts the requests
load "pkg.ring"
pkgUse("mockhttp",[["RichardSzalay.MockHttp","7.1.0"]],[["RichardSzalay.MockHttp.dll",["RichardSzalay.MockHttp"]]])
pkgImport("mockhttp","RichardSzalay.MockHttp.dll","RichardSzalay.MockHttp")

using {
	"System.Net.Http"
}

# Respond and WithQueryString are extension methods of the static class MockedRequestExtensions: the request is the first argument (:source)
oExtensions = new MockedRequestExtensions()
oHandler = new MockHttpMessageHandler()
oItems = oHandler.When("http://api.test/items")
oExtensions.Respond([ :source = oItems, :mediaType = "application/json", :content = '{"count":3}' ])
oHello = oHandler.When("http://api.test/hello")
oExtensions.Respond([ :source = oHello, :mediaType = "text/plain", :content = "hello from the mock" ])

oClient = oHandler.ToHttpClient()
cJson = oClient.GetStringAsync([ :requestUri = "http://api.test/items" ]).Result
dnAssert("a mocked JSON answer",cJson,'{"count":3}')
dnAssert("another route",oClient.GetStringAsync([ :requestUri = "http://api.test/hello" ]).Result,"hello from the mock")
dnAssert("the number of requests that a route had",oHandler.GetMatchCount(oItems),1)
oClient.GetStringAsync([ :requestUri = "http://api.test/items" ]).Result
dnAssert("a second request is counted",oHandler.GetMatchCount(oItems),2)

# a route with a query string
oSearch = oHandler.When("http://api.test/search")
oExtensions.WithQueryString([ :source = oSearch, :name = "q", :value = "ring" ])
oExtensions.Respond([ :source = oSearch, :mediaType = "text/plain", :content = "found ring" ])
dnAssert("a query string matches",oClient.GetStringAsync([ :requestUri = "http://api.test/search?q=ring" ]).Result,"found ring")

# a status code
oGone = oHandler.When("http://api.test/gone")
oExtensions.Respond([ :source = oGone, :statusCode = "NotFound" ])
oResponse = oClient.GetAsync([ :requestUri = "http://api.test/gone" ]).Result
dnAssert("a status code",oResponse.StatusCode,"NotFound")
dnAssert("the response is not a success",oResponse.IsSuccessStatusCode,0)

# a request that no route knows is an error
lError = 0
try
	oClient.GetStringAsync([ :requestUri = "http://api.test/unknown" ]).Result
catch
	lError = 1
done
dnAssert("an unknown request raises an error",lError,1)

# an expectation: the test says what must be asked
oStrict = new MockHttpMessageHandler()
oExpected = oStrict.Expect("http://api.test/once")
oExtensions.Respond([ :source = oExpected, :mediaType = "text/plain", :content = "ok" ])
oStrictClient = oStrict.ToHttpClient()
oStrictClient.GetStringAsync([ :requestUri = "http://api.test/once" ]).Result
oStrict.VerifyNoOutstandingExpectation()
dnAssert("the expected request was made",oStrict.GetMatchCount(oExpected),1)

dnTestSummary()
