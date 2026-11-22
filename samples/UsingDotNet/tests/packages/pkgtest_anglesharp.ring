# AngleSharp: an HTML5 parser with the DOM of a browser: CSS selectors, attributes, text, and changing the document
load "pkg.ring"
pkgUse("anglesharp",[["AngleSharp","1.10.5"]],[["AngleSharp.dll",["AngleSharp","AngleSharp.Html.Parser","AngleSharp.Html.Dom","AngleSharp.Dom"]]])
pkgImport("anglesharp","AngleSharp.dll","AngleSharp")
pkgImport("anglesharp","AngleSharp.dll","AngleSharp.Html.Parser")
pkgImport("anglesharp","AngleSharp.dll","AngleSharp.Html.Dom")
pkgImport("anglesharp","AngleSharp.dll","AngleSharp.Dom")

cHtml = "<html><head><title>Page</title></head><body><h1 id='top' class='big'>Title</h1><ul><li class='a'>one<li class='b'>two<li class='a'>three</ul><p>Some <b>bold</b> text and <a href='http://x.org/page'>a link</a></p></body></html>"
oParser = new HtmlParser()
oDoc = oParser.ParseDocument(cHtml)
dnAssert("the title of the document",oDoc.Title,"Page")

oTitle = oDoc.QuerySelector("h1")
dnAssert("a selector finds an element",oTitle.TextContent,"Title")
dnAssert("an attribute",oTitle.GetAttribute("id"),"top")
dnAssert("the tag name",oTitle.TagName,"H1")
dnAssert("a class",oTitle.ClassName,"big")

oItems = oDoc.QuerySelectorAll("li")
dnAssert("a selector finds all the items (unclosed tags are closed)",oItems.Length,3)
dnAssert("an item",oItems.Item(1).TextContent,"two")
dnAssert("a class selector",oDoc.QuerySelectorAll("li.a").Length,2)
dnAssert("a descendant selector",oDoc.QuerySelector("p b").TextContent,"bold")
dnAssert("an attribute selector",oDoc.QuerySelector("a[href]").GetAttribute("href"),"http://x.org/page")
dnAssert("no match is null",oDoc.QuerySelector("table").isNull(),1)
dnAssert("the text of an element with children",oDoc.QuerySelector("p").TextContent,"Some bold text and a link")

# changing the document
oTitle.TextContent = "New title"
oTitle.SetAttribute([ :name = "data-x", :value = "1" ])
oItems.Item(0).Remove()
cOut = oDoc.DocumentElement.OuterHtml
dnAssert("the text was set",substr(cOut,"New title") > 0,1)
dnAssert("the attribute was set",substr(cOut,'data-x="1"') > 0,1)
dnAssert("an element was removed",oDoc.QuerySelectorAll("li").Length,2)

dnTestSummary()
