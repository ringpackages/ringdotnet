# Flurl: building and parsing URLs (extension methods on string, a fluent Url object), no network
load "pkg.ring"
pkgUse("flurl",[["Flurl","4.0.0"]],[["Flurl.dll",["Flurl"]]])
pkgImport("flurl","Flurl.dll","Flurl")

oUrl = new Url().@New("https://example.com/api")
oUrl.AppendPathSegment("users")
oUrl.AppendPathSegment("42")
dnAssert("path segments are joined",oUrl.ToString(),"https://example.com/api/users/42")

oUrl.SetQueryParam([ :name = "q", :value = "a b" ])
oUrl.SetQueryParam([ :name = "page", :value = 2 ])
dnAssert("a query value is encoded",substr(oUrl.ToString(),"q=a%20b") > 0,1)
dnAssert("a number as a query value",substr(oUrl.ToString(),"page=2") > 0,1)
dnAssert("read a query parameter",oUrl.QueryParams.Count,2)

oParsed = new Url().@New("https://user@example.com:8080/a/b/c?x=1&y=2#frag")
dnAssert("host",oParsed.Host,"example.com")
dnAssert("port",oParsed.Port,8080)
dnAssert("scheme",oParsed.Scheme,"https")
dnAssert("path",oParsed.Path,"/a/b/c")
dnAssert("fragment",oParsed.Fragment,"frag")
dnAssert("segments",len(oParsed.PathSegments.toList()),3)
dnAssert("the root",oParsed.Root,"https://user@example.com:8080")

oParsed.RemoveQueryParam("x")
dnAssert("a removed parameter",substr(oParsed.ToString(),"x=1"),0)
oParsed.ResetToRoot()
dnAssert("reset to the root",oParsed.ToString(),"https://user@example.com:8080")

dnAssert("combine",dnStatic("Flurl.Url","Combine",[["http://a.com","b","c"]]),"http://a.com/b/c")
dnAssert("encode",dnStatic("Flurl.Url","Encode",["a b&c"]),"a%20b%26c")
dnAssert("decode",dnStatic("Flurl.Url","Decode",["a%20b",0]),"a b")
dnAssert("is valid",dnStatic("Flurl.Url","IsValid",["https://a.com"]),1)

dnTestSummary()
