# URLs and encodings - taking an address apart, building a query string safely, Base64 and percent-encoding
load "dotnet.ring"

using {
	"System"
	"System.Net"
	"System.Text"
}

func main

	# 1. A URL has parts. The Uri class splits them: no searching for ":" and "/" yourself.
	oUri = new Uri("https://shop.example.com:8443/products/shoes?color=red&size=42#reviews")
	? "1. scheme   : " + oUri.Scheme
	? "   host     : " + oUri.Host
	? "   port     : " + oUri.Port
	? "   path     : " + oUri.AbsolutePath
	? "   query    : " + oUri.Query
	? "   fragment : " + oUri.Fragment

	# 2. Default ports: no port in the text gives the port of the scheme
	? nl + "2. http port: " + new Uri("http://example.com/").Port + ", https port: " + new Uri("https://example.com/").Port

	# 3. Special characters in a query must be encoded: a space, &, = and ? would change the meaning of the address
	oWeb = new WebUtility()
	cSearch = "rock & roll: 50% off?"
	cEncoded = oWeb.UrlEncode(cSearch)
	? nl + "3. text   : " + cSearch
	? "   encoded: " + cEncoded
	? "   decoded back: " + oWeb.UrlDecode(cEncoded)

	# 4. Build a URL from a list of values: encode each value, never the separators
	aParameters = [["q","rock & roll"],["page",2],["lang","ar"],["note","a b+c"]]
	? nl + "4. " + buildUrl("https://example.com/search",aParameters)

	# 5. Read a query string: split on & and =, then decode each part
	cQuery = "q=rock+%26+roll&page=2&lang=ar"
	? nl + "5. the parameters of " + cQuery + ":"
	aPairs = parseQuery(cQuery)
	for aPair in aPairs
		? "   " + aPair[1] + " = " + aPair[2]
	next

	# 6. Combining an address with a relative path
	oBase = new Uri("https://example.com/docs/guide/index.html")
	oUri = (new Uri).@New([ :baseUri = oBase, :relativeUri = "../images/logo.png" ])
	? nl + "6. ../images/logo.png from the guide page: " + oUri.ToString()

	# 7. Base64: bytes as safe text (e-mails, JSON, data URLs). It is NOT encryption: anybody can decode it.
	oConvert = new Convert()
	oUtf8 = new Encoding().UTF8
	cBase = oConvert.ToBase64String(oUtf8.GetBytes("Hello, Ring! é"))
	? nl + "7. Base64: " + cBase
	? "   decoded: " + oUtf8.GetString(oConvert.FromBase64String(cBase))

	# 8. An address that is not valid
	? nl + "8. is 'not a url' valid? " + yesNo(oUri.IsWellFormedUriString("not a url","Absolute"))
	? "   is 'https://example.com' valid? " + yesNo(oUri.IsWellFormedUriString("https://example.com","Absolute"))

func buildUrl cBase, aParameters

	cQuery = ""
	for aPair in aParameters
		if cQuery != ""
			cQuery += "&"
		ok
		cQuery += aPair[1] + "=" + new WebUtility().UrlEncode("" + aPair[2])
	next
	return cBase + "?" + cQuery

# "a=1&b=2" -> [["a","1"],["b","2"]], each value decoded
func parseQuery cQuery

	aList = []
	aParts = str2list(substr(cQuery,"&",nl))
	for cPart in aParts
		nPos = substr(cPart,"=")
		aList + [left(cPart,nPos - 1),new WebUtility().UrlDecode(substr(cPart,nPos + 1))]
	next
	return aList

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"
