# Classes of namespaces of the ASP.NET Core runtime that are not web servers: data protection, file globbing, rate limiting, route templates, and the header types of ASP.NET Core
load "dotnet.ring"

using {
	"System"
	"RingDotNet.Web"
	"Microsoft.AspNetCore.DataProtection"
	"Microsoft.AspNetCore.Routing.Template"
	"Microsoft.Extensions.FileSystemGlobbing"
	"Microsoft.Net.Http.Headers"
	"System.Threading.RateLimiting"
}

func main

	# ---- file globbing: a Matcher with include and exclude rules, and extension methods as methods of the object
	oMatcher = new Matcher()
	oMatcher.AddInclude("**/*.ring")
	oMatcher.AddExclude("tests/**")
	oResult = oMatcher.Match([ :rootDir = ".", :files = ["a.ring","src/b.ring","tests/c.ring","d.txt"] ])
	dnAssert("the files that the rules match",oResult.Files.Count,2)
	dnAssert("a match is found",oResult.HasMatches,True)
	oStrict = (new Matcher).@New([ :comparisonType = "Ordinal" ])
	oStrict.AddInclude("*.RING")
	dnAssert("Ordinal: the case counts",oStrict.Match([ :rootDir = ".", :files = ["a.ring","b.RING"] ]).Files.Count,1)

	# ---- data protection: a provider with keys in memory, the protect and unprotect of the extension class, and a purpose
	oProvider = new EphemeralDataProtectionProvider
	oProtector = oProvider.CreateProtector("test.cookies")
	cToken = (new DataProtectionCommonExtensions).Protect(oProtector,"user=ann;role=admin")
	dnAssert("a token of the Data Protection API",left(cToken,5),"CfDJ8")
	dnAssert("the text comes back",(new DataProtectionCommonExtensions).Unprotect(oProtector,cToken),"user=ann;role=admin")
	oOther = oProvider.CreateProtector("other.purpose")
	lRefused = False
	try
		(new DataProtectionCommonExtensions).Unprotect(oOther,cToken)
	catch
		lRefused = True
	done
	dnAssert("another purpose can not open the token",lRefused,True)
	oLimited = oProtector.ToTimeLimitedDataProtector()
	cShort = (new DataProtectionAdvancedExtensions).Protect(oLimited,"reset:42",new TimeSpan().FromMilliseconds(5000))
	dnAssert("a time limited token is a token too",left(cShort,5),"CfDJ8")

	# ---- rate limiting: a concurrency limiter gives leases
	oOptions = new ConcurrencyLimiterOptions
	oOptions.PermitLimit = 1
	oOptions.QueueLimit = 0
	oLimiter = new ConcurrencyLimiter(oOptions)
	oFirst = oLimiter.AttemptAcquire(1)
	dnAssert("the first request gets a lease",oFirst.IsAcquired,True)
	dnAssert("the second is refused",oLimiter.AttemptAcquire(1).IsAcquired,False)
	oFirst.Dispose()
	dnAssert("a lease that is given back frees the place",oLimiter.AttemptAcquire(1).IsAcquired,True)

	# ---- route templates
	oTemplate = (new TemplateParser).Parse("/users/{id}/orders/{orderId?}")
	dnAssert("a template has parameters",oTemplate.Parameters.Count,2)
	dnAssert("the first parameter is id",oTemplate.Parameters.Item(0).Name,"id")

	# ---- the header types of ASP.NET Core (the classes have the prefix Asp: System.Net.Http.Headers has the same names)
	oType = (new AspMediaTypeHeaderValue).Parse("application/json; charset=utf-8; q=0.9")
	dnAssert("the media type",oType.MediaType.Value,"application/json")
	dnAssert("the charset",oType.Charset.Value,"utf-8")

	dnTestSummary()
