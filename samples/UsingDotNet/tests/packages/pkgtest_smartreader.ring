# SmartReader: the article of a web page (title, author, text) extracted from HTML text, without a network
load "pkg.ring"
pkgUse("smartreader",[["SmartReader","0.11.1"]],[["SmartReader.dll",["SmartReader"]]])
pkgImport("smartreader","SmartReader.dll","SmartReader")

cHtml = '<html><head><title>Ring and .NET</title><meta name="author" content="Ann"></head><body>' +
	'<nav>menu menu menu</nav><article><h1>Ring and .NET</h1>' +
	'<p>' + copy("Ring is a small language and .NET is a large platform. Together they let a short program use a large library. ",8) + '</p>' +
	'<p>' + copy("A second paragraph with more words about the bridge between the two worlds. ",8) + '</p></article>' +
	'<footer>copyright</footer></body></html>'

oReader = dnNew("SmartReader.Reader",[ :uri = "https://example.com/post", :text = cHtml ])
oArticle = oReader.GetArticle()
dnAssert("the article was read",oArticle.IsReadable,1)
dnAssert("the title",oArticle.Title,"Ring and .NET")
dnAssert("the text has the words of the paragraphs",substr(oArticle.TextContent,"bridge between the two worlds") > 0,1)
dnAssert("the menu is not in the text",substr(oArticle.TextContent,"menu menu"),0)
dnAssert("a length",oArticle.Length > 300,1)

dnTestSummary()
