# Makes one PDF of the documentation: docs/pdf/RingDotNet-documentation.pdf
#
# All the pages of docs/*.html (the pages listed in docpages.ring, in the order of the navigation) are put into one HTML file
# (docs/pdf/RingDotNet-documentation.html) and printed by headless Chrome or Edge. The links between pages become links inside the PDF,
# and the PDF has bookmarks. The class reference (docs/api/, one page per namespace) is the last part: thousands of pages in print.
# With --no-api the PDF is the manual without the class reference.
#
#     cd docs/tools
#     ring makepdf.ring [--no-api] [--html-only]
#
# Plain Ring: this tool does not use RingDotNet.

load "doclib.ring"
load "docpages.ring"

aBrowsers = [
	"C:\Program Files\Google\Chrome\Application\chrome.exe",
	"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
	"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
	"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
	"/usr/bin/google-chrome",
	"/usr/bin/chromium",
	"/usr/bin/chromium-browser",
	"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
]

func main

	cHere = programFolder()
	cDocs = parentFolder(cHere)
	cOut = cDocs + "/pdf"
	lApi = true
	lHtmlOnly = false
	for nArg = 3 to len(sysargv)
		if sysargv[nArg] = "--no-api"
			lApi = false
		but sysargv[nArg] = "--html-only"
			lHtmlOnly = true
		ok
	next
	if not direxists(cOut)
		makeFolder(cOut)
	ok
	aPages = []
	aKnown = []
	nPages = len(aDocPages)
	for nPage = 1 to nPages
		if fexists(cDocs + "/" + aDocPages[nPage][1] + ".html")
			aPages + aDocPages[nPage]
			aKnown + aDocPages[nPage][1]
		ok
	next
	aNamespaces = []
	if lApi
		aLoop18 = listNames(cDocs + "/api")
		for cFile in aLoop18
			if hasSuffix(cFile,".html")
				aNamespaces + left(cFile,len(cFile) - 5)
			ok
		next
		aNamespaces = sort(aNamespaces)
		for cNs in aNamespaces
			aKnown + ("api-" + cNs)
		next
	ok
	aParts = []
	aToc = []
	cSection = ""
	lFirst = true
	for aPage in aPages
		if aPage[3] != cSection or lFirst
			if lFirst
				aToc + ""
			else
				aToc + "</ol>"
			ok
			aToc + ("<h2>" + escQ(aPage[3]) + "</h2><ol>")
			cSection = aPage[3]
			lFirst = false
		ok
		aToc + ('<li><a href="#p-' + aPage[1] + '">' + escQ(aPage[2]) + "</a></li>")
		cBody = rewriteBody(articleOf(cDocs,aPage[1]),aPage[1],aKnown)
		aParts + ('<section class="part" id="p-' + aPage[1] + '"><article>' + cBody + "</article></section>")
	next
	aToc + "</ol>"
	if len(aNamespaces) > 0
		aToc + "<h2>Class reference: namespaces</h2><ol>"
		for cNs in aNamespaces
			aToc + ('<li><a href="#p-api-' + cNs + '">' + escQ(cNs) + "</a></li>")
			aParts + ('<section class="part apipart" id="p-api-' + cNs + '"><article>' + rewriteBody(articleOf(cDocs,"api-" + cNs),"api-" + cNs,aKnown) + "</article></section>")
		next
		aToc + "</ol>"
	ok
	cDoc = fillTemplate(readText(cHere + "/pdfdoc.template"),[["css",readText(cHere + "/pdf.css")],["cover",coverSvg(cHere)],["toc",joinList(aToc,"")],["parts",joinList(aParts,"")]])
	cPage = cOut + "/RingDotNet-documentation.html"
	writeText(cPage,cDoc)
	if lHtmlOnly
		? "the page -> " + cPage
		return
	ok
	cPdf = cOut + "/RingDotNet-documentation.pdf"
	cBrowser = ""
	for cTry in aBrowsers
		if fexists(cTry)
			cBrowser = cTry
			exit
		ok
	next
	if cBrowser = ""
		? "No Chrome or Edge found: open " + cPage + " and print it to PDF"
		return
	ok
	if fexists(cPdf)
		remove(cPdf)
	ok
	cCommand = '"' + cBrowser + '" --headless=new --disable-gpu --no-pdf-header-footer --generate-pdf-document-outline --virtual-time-budget=60000 --print-to-pdf="' + cPdf + '" "file:///' + substr(cPage,"\","/") + '"'
	if isWindows()
		system('cmd /c "' + cCommand + ' > nul 2>&1"')
	else
		system(cCommand + " > /dev/null 2>&1")
	ok
	if fexists(cPdf)
		? "the documentation -> " + cPdf + " (" + (floor(len(read(cPdf)) / 104857.6 + 0.5) / 10) + " MB)"
	else
		? "The browser did not write the PDF"
	ok

# the part of a page between <article> and </article>; a page of the manual is docs/<name>.html, a namespace of the class reference is named api-<namespace>
func articleOf cDocs,cName

	if hasPrefix(cName,"api-")
		cPath = cDocs + "/api/" + tail(cName,5) + ".html"
	else
		cPath = cDocs + "/" + cName + ".html"
	ok
	cText = readText(cPath)
	nStart = substr(cText,"<article>") + 9
	nEnd = substr(cText,"</article>")
	return part(cText,nStart,nEnd - 1)

# the cover (cover.svg) with the Ring logo (ring-logo.png) embedded
func coverSvg cHere

	cSvg = readText(cHere + "/cover.svg")
	cLogo = base64Encode(read(cHere + "/ring-logo.png"))
	cSvg = substr(cSvg,"@RINGLOGO@","data:image/png;base64," + cLogo)
	nAt = substr(cSvg,"<?xml")
	if nAt > 0
		nGt = findFrom(cSvg,">",nAt)
		if nGt > 0 and cSvg[nGt - 1] = "?"
			cSvg = left(cSvg,nAt - 1) + tail(cSvg,nGt + 1)
		ok
	ok
	return cSvg

# ids get the page name in front, links to other pages become links inside the document
func rewriteBody cBody,cName,aKnown

	cBody = prefixIds(cBody,cName)
	cBody = substr(cBody,' loading="lazy"',"")
	if substr(cBody,'<div class="cards">') > 0
		cBody = cardTables(cBody)
	ok
	if substr(cBody,'<div class="stats">') > 0
		cBody = statTables(cBody)
	ok
	cBody = rewriteLinks(cBody,cName,aKnown)
	# a link to a page that is not in the PDF: only its text stays
	cBody = dropMarkedLinks(cBody)
	# a collapsed <details> prints nothing: the source code of the samples (gallery, {{source:}}) is open in the PDF
	cBody = openDetails(cBody)
	return cBody

# \sid="([^"]+)"  ->  ' id="p-<page>-\1"'
func prefixIds cBody,cName

	if substr(cBody,'id="') = 0
		return cBody
	ok
	aPieces = splitOn(cBody,'id="')
	aOut = []
	cPending = aPieces[1]
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cPiece = aPieces[nPiece]
		nQuote = substr(cPiece,'"')
		if cPending != "" and isSpaceCh(right(cPending,1)) and nQuote > 1
			aOut + left(cPending,len(cPending) - 1)
			aOut + (' id="p-' + cName + "-" + left(cPiece,nQuote - 1) + '"')
			cPending = tail(cPiece,nQuote + 1)
		else
			cPending += 'id="' + cPiece
		ok
	next
	aOut + cPending
	return joinList(aOut,"")

# a list of cards (icon, title, text) is one table in print: the title (a link) and the text in a row
func cardTables cBody

	aPieces = splitOn(cBody,'<div class="cards">')
	aOut = [aPieces[1]]
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cPiece = aPieces[nPiece]
		nSize = len(cPiece)
		nAt = 1
		while nAt <= nSize and isSpaceCh(cPiece[nAt])
			nAt++
		end
		nFirst = nAt
		nCards = 0
		while part(cPiece,nAt,nAt + 14) = '<a class="card"'
			nGt = findFrom(cPiece,">",nAt)
			if nGt = 0
				exit
			ok
			nClose = findFrom(cPiece,"</a>",nGt)
			if nClose = 0
				exit
			ok
			nAt = nClose + 4
			while nAt <= nSize and isSpaceCh(cPiece[nAt])
				nAt++
			end
			nCards++
		end
		if nCards > 0 and part(cPiece,nAt,nAt + 5) = "</div>"
			cCards = part(cPiece,nFirst,nAt - 1)
			cTable = cardsTable(cCards)
			if cTable = ""
				aOut + ('<div class="cards">' + cPiece)
			else
				aOut + cTable
				aOut + tail(cPiece,nAt + 6)
			ok
		else
			aOut + ('<div class="cards">' + cPiece)
		ok
	next
	return joinList(aOut,"")

# the table of a list of cards, or "" when a card has no title (the list stays as it is)
func cardsTable cCards

	aRows = []
	aPieces = splitOn(cCards,'<a class="card" href="')
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cPiece = aPieces[nPiece]
		nQuote = substr(cPiece,'"')
		if nQuote = 0
			loop
		ok
		cHref = left(cPiece,nQuote - 1)
		nGt = findFrom(cPiece,">",nQuote)
		if nGt = 0
			loop
		ok
		nClose = findFrom(cPiece,"</a>",nGt)
		if nClose = 0
			loop
		ok
		cInner = part(cPiece,nGt + 1,nClose - 1)
		nB = substr(cInner,"<b>")
		nBEnd = findFrom(cInner,"</b>",nB)
		if nB = 0 or nBEnd = 0
			return ""
		ok
		cTitle = part(cInner,nB + 3,nBEnd - 1)
		cDesc = ""
		nSpan = substr(cInner,"<span>")
		if nSpan > 0
			nSpanEnd = findFrom(cInner,"</span>",nSpan)
			if nSpanEnd > 0
				cDesc = part(cInner,nSpan + 6,nSpanEnd - 1)
			ok
		ok
		aRows + ('<tr><td class="cardname"><a href="' + cHref + '">' + cTitle + "</a></td><td>" + cDesc + "</td></tr>")
	next
	return '<div class="tablewrap"><table class="cardtable"><thead><tr><th>Topic</th><th>Description</th></tr></thead><tbody>' + joinList(aRows,"") + "</tbody></table></div>"

# the row of numbers (a number and its label in a box) is one table in print
func statTables cBody

	aPieces = splitOn(cBody,'<div class="stats">')
	aOut = [aPieces[1]]
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cPiece = aPieces[nPiece]
		nAt = 1
		nStats = 0
		aHead = []
		aRow = []
		while part(cPiece,nAt,nAt + 17) = '<div class="stat">'
			nClose = findFrom(cPiece,"</div>",nAt)
			if nClose = 0
				exit
			ok
			cInner = part(cPiece,nAt + 18,nClose - 1)
			if left(cInner,3) = "<b>"
				nBEnd = findFrom(cInner,"</b><span>",1)
				if nBEnd > 0 and right(cInner,7) = "</span>"
					aRow + ("<td><b>" + part(cInner,4,nBEnd - 1) + "</b></td>")
					aHead + ("<th>" + part(cInner,nBEnd + 10,len(cInner) - 7) + "</th>")
				ok
			ok
			nAt = nClose + 6
			nStats++
		end
		if nStats > 0 and part(cPiece,nAt,nAt + 5) = "</div>" and len(aHead) > 0
			aOut + ('<div class="tablewrap"><table class="stattable"><thead><tr>' + joinList(aHead,"") + "</tr></thead><tbody><tr>" + joinList(aRow,"") + "</tr></tbody></table></div>")
			aOut + tail(cPiece,nAt + 6)
		else
			aOut + ('<div class="stats">' + cPiece)
		ok
	next
	return joinList(aOut,"")

# href="..." of a link: a link to another page of the PDF goes to the place inside the document
func rewriteLinks cBody,cName,aKnown

	if substr(cBody,'href="') = 0
		return cBody
	ok
	aPieces = splitOn(cBody,'href="')
	aOut = [aPieces[1]]
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cPiece = aPieces[nPiece]
		nQuote = substr(cPiece,'"')
		if nQuote = 0
			aOut + ('href="' + cPiece)
			loop
		ok
		aOut + linkText(left(cPiece,nQuote - 1),cName,aKnown)
		aOut + tail(cPiece,nQuote + 1)
	next
	return joinList(aOut,"")

func linkText cHref,cName,aKnown

	if hasPrefix(cHref,"http://") or hasPrefix(cHref,"https://") or hasPrefix(cHref,"mailto:")
		return 'href="' + cHref + '"'
	ok
	if hasPrefix(cHref,"#")
		return 'href="#p-' + cName + "-" + tail(cHref,2) + '"'
	ok
	cPage = cHref
	cFragment = ""
	nHash = substr(cHref,"#")
	if nHash > 0
		cPage = left(cHref,nHash - 1)
		cFragment = tail(cHref,nHash + 1)
	ok
	if hasPrefix(cPage,"api/")
		cPage = "api-" + tail(cPage,5)
	but hasPrefix(cName,"api-") and not hasPrefix(cPage,"../") and hasSuffix(cPage,".html")
		cPage = "api-" + cPage
	but hasPrefix(cPage,"../")
		cPage = tail(cPage,4)
	ok
	if hasSuffix(cPage,".html") and find(aKnown,left(cPage,len(cPage) - 5)) > 0
		cTarget = left(cPage,len(cPage) - 5)
		if cFragment != ""
			return 'href="#p-' + cTarget + "-" + cFragment + '"'
		ok
		return 'href="#p-' + cTarget + '"'
	ok
	return 'data-nolink="1"'

# <a data-nolink="1"...>text</a>  ->  text
func dropMarkedLinks cBody

	if substr(cBody,'<a data-nolink="1"') = 0
		return cBody
	ok
	aPieces = splitOn(cBody,'<a data-nolink="1"')
	aOut = [aPieces[1]]
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cPiece = aPieces[nPiece]
		nGt = substr(cPiece,">")
		nClose = 0
		if nGt > 0
			nClose = findFrom(cPiece,"</a>",nGt)
		ok
		if nGt > 0 and nClose > 0
			aOut + part(cPiece,nGt + 1,nClose - 1)
			aOut + tail(cPiece,nClose + 4)
		else
			aOut + ('<a data-nolink="1"' + cPiece)
		ok
	next
	return joinList(aOut,"")

# <details ...>  ->  <details open ...>  (when the tag has no open)
func openDetails cBody

	if substr(cBody,"<details") = 0
		return cBody
	ok
	aPieces = splitOn(cBody,"<details")
	aOut = [aPieces[1]]
	nMax = len(aPieces)
	for nPiece = 2 to nMax
		cPiece = aPieces[nPiece]
		nGt = substr(cPiece,">")
		cTag = cPiece
		if nGt > 0
			cTag = left(cPiece,nGt - 1)
		ok
		if hasOpenWord(cTag)
			aOut + ("<details" + cPiece)
		else
			aOut + ("<details open" + cPiece)
		ok
	next
	return joinList(aOut,"")

# is there the word open in the text (\bopen\b)?
func hasOpenWord cTag

	nPos = 1
	nSize = len(cTag)
	while true
		nAt = findFrom(cTag,"open",nPos)
		if nAt = 0
			return false
		ok
		lBefore = nAt = 1 or not isWordCh(cTag[nAt - 1])
		lAfter = nAt + 3 >= nSize or not isWordCh(cTag[nAt + 4])
		if lBefore and lAfter
			return true
		ok
		nPos = nAt + 1
	end
