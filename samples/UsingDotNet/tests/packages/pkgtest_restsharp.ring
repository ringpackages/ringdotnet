# RestSharp: requests built and a client made without sending anything: URL segments, query and header parameters, methods, a base URL
load "pkg.ring"
pkgUse("restsharp",[["RestSharp","114.1.0"]],[["RestSharp.dll",["RestSharp"]]])
pkgImport("restsharp","RestSharp.dll","RestSharp")

oRequest = new RestRequest().@New("users/{id}")
oRequest.AddUrlSegment([ :name = "id", :value = "42" ])
# AddParameter(name, value) is an extension method; RestRequest has its own AddParameter(Parameter), so the two-argument form is called with callMethod
oRequest.callMethod("AddParameter",["page","2"])
oRequest.AddHeader([ :name = "X-Test", :value = "ring" ])
dnAssert("the resource",oRequest.Resource,"users/{id}")
dnAssert("the default method",oRequest.Method,"Get")

aParameters = oRequest.Parameters.toList()
dnAssert("three parameters",len(aParameters),3)

oPost = new RestRequest().@New([ :resource = "items", :method = dnStatic("RestSharp.Method","Post",[]) ])
dnAssert("a post",oPost.Method,"Post")

oClient = new RestClient().@New("https://example.com/api/")
oUri = oClient.BuildUri(oRequest)
dnAssert("the full address",oUri.ToString(),"https://example.com/api/users/42?page=2")
oClient.Dispose()

dnTestSummary()
