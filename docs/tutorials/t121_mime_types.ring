# Tutorial 121: MIME types - file extensions to content types, reading a Content-Type header, and choosing what to send for an Accept header
load "dotnet.ring"
using {
	"System"
	"System.Net.Mime"
	"RingDotNet.Web"                  # the content type classes of ASP.NET Core are part of its runtime: this line starts it
}

cHeaders = "Microsoft.Net.Http.Headers."

func main
	# A MIME type (media type, content type) names the KIND of a piece of data: text/html, image/png, application/json. A server sends it in
	# the Content-Type header so that the browser knows what to do with the bytes, and a client sends Accept to say what it understands.

	# 1. From a file name to a type. The provider knows the common extensions.
	oProvider = dnNew("Microsoft.AspNetCore.StaticFiles.FileExtensionContentTypeProvider",[])
	? "1. file name -> content type:"
	for cFile in ["index.html","logo.png","photo.JPG","data.json","report.pdf","archive.zip","notes.txt","song.mp3","movie.mp4","style.css","app.js","unknown.xyz123"]
		? "   " + padRight(cFile,16) + contentTypeOf(oProvider,cFile)
	next

	# 2. The mapping can be extended: a type of your own for your own extension
	oProvider.getProp("Mappings").callMethod("Add",[".ring","text/x-ring"])
	? nl + "2. after adding .ring: " + contentTypeOf(oProvider,"program.ring")
	? "   (a file with an unknown type is sent as application/octet-stream: 'some bytes, download them')"

	# 3. Reading a Content-Type header: the type, the subtype and the parameters (the charset says how text is encoded)
	oContentType = dnNew("ContentType",["text/html; charset=utf-8"])
	? nl + "3. text/html; charset=utf-8  ->  media type: " + oContentType.MediaType + ", charset: " + oContentType.CharSet
	oSplit = dnStatic(cHeaders + "MediaTypeHeaderValue","Parse",["application/json; charset=utf-8; q=0.9"])
	? "   with the headers library: type " + oSplit.getProp("Type").toString() + ", subtype " + oSplit.getProp("SubType").toString() + ", quality " + oSplit.getProp("Quality")

	# 4. The Accept header lists what the client understands, with a QUALITY (q) from 0 to 1 for each: the higher, the better. */* means
	#    "anything"; text/* means "any text type". The default quality is 1.
	cAccept = "text/html, application/json;q=0.9, text/*;q=0.5, */*;q=0.1"
	? nl + "4. the client sends: Accept: " + cAccept
	aClient = parseAccept(cAccept)
	for aItem in aClient
		? "   " + padRight(aItem[1],20) + "quality " + aItem[2]
	next

	# 5. Content negotiation: the server offers some types and sends the one that the client likes best
	? nl + "5. what the server sends:"
	for aOffer in [ ["application/json","text/csv"], ["text/csv","text/plain"], ["image/png"], ["text/html","application/json"] ]
		? "   offers " + padRight(joinList(aOffer),28) + "-> " + negotiate(aClient,aOffer)
	next

	# 6. A client that wants a JSON answer: Accept: application/json only. If the server has no JSON, the right answer is the status
	#    406 Not Acceptable, not a guess.
	aStrict = parseAccept("application/json")
	? nl + "6. Accept: application/json, the server offers text/csv: " + negotiate(aStrict,["text/csv"])

func contentTypeOf oProvider,cFile
	aResult = oProvider.callMethod("TryGetContentType",[cFile])
	if aResult[1]
		return aResult[2]
	ok
	return "application/octet-stream  (not known)"

# the Accept header as a list of [type, quality], the best first (the sort is stable: types with the same quality keep their order)
func parseAccept cAccept
	aItems = []
	for cPart in str2list(substr(cAccept,",",nl))
		oValue = dnStatic(cHeaders + "MediaTypeHeaderValue","Parse",[trim(cPart)])
		nQuality = oValue.getProp("Quality")
		if isObject(nQuality)
			nQuality = 1                                        # no q parameter: quality 1
		ok
		aItems + [ oValue.getProp("MediaType").toString(), nQuality ]
	next
	nCount = len(aItems)
	for i = 1 to nCount - 1
		for j = 1 to nCount - i
			if aItems[j][2] < aItems[j + 1][2]
				aTemp = aItems[j]
				aItems[j] = aItems[j + 1]
				aItems[j + 1] = aTemp
			ok
		next
	next
	return aItems

# does the pattern of the Accept header (text/html, text/*, */*) cover the type?
func covers cPattern,cType
	if cPattern = "*/*" or cPattern = cType
		return True
	ok
	nSlash = substr(cPattern,"/")
	return right(cPattern,2) = "/*" and left(cType,nSlash) = left(cPattern,nSlash)

# the offered type that the client likes best, or 406
func negotiate aClient,aOffers
	for aItem in aClient
		if aItem[2] > 0
			for cOffer in aOffers
				if covers(aItem[1],cOffer)
					return cOffer + "  (matched " + aItem[1] + ", quality " + aItem[2] + ")"
				ok
			next
		ok
	next
	return "406 Not Acceptable"

func joinList aList
	cText = ""
	for item in aList
		if cText != ""
			cText += ", "
		ok
		cText += "" + item
	next
	return cText

func padRight cText,nWidth
	return cText + copy(" ",nWidth - len(cText))
