# HtmlAgilityPack: parse HTML (even bad HTML), XPath, attributes, text, and change the document
load "pkg.ring"
pkgUse("htmlagilitypack",[["HtmlAgilityPack","1.13.1"]],[["HtmlAgilityPack.dll",["HtmlAgilityPack"]]])
pkgImport("htmlagilitypack","HtmlAgilityPack.dll","HtmlAgilityPack")

cHtml = "<html><body><h1 id='top'>Title</h1><ul><li class='a'>one<li class='b'>two<li class='a'>three</ul><p>Some <b>bold</b> text<br>and a <a href='http://x.org/page'>link</a></body></html>"
oDoc = new HtmlDocument()
oDoc.LoadHtml(cHtml)

oTitle = oDoc.GetElementbyId("top")
dnAssert("an element by id",oTitle.InnerText,"Title")
dnAssert("the name of a tag",oTitle.Name,"h1")

oItems = oDoc.DocumentNode.SelectNodes("//li")
dnAssert("XPath finds the items of unclosed list tags",oItems.Count,3)
dnAssert("an item",oItems.Item(1).InnerText,"two")
oClassA = oDoc.DocumentNode.SelectNodes("//li[@class='a']")
dnAssert("XPath with an attribute",oClassA.Count,2)

oLink = oDoc.DocumentNode.SelectSingleNode("//a")
dnAssert("the value of an attribute",oLink.GetAttributeValue([ :name = "href", :def = "" ]),"http://x.org/page")
dnAssert("a missing attribute gives the default",oLink.GetAttributeValue([ :name = "target", :def = "none" ]),"none")
dnAssert("text of a mixed element",oDoc.DocumentNode.SelectSingleNode("//p").InnerText,"Some bold textand a link")
dnAssert("no node gives null",oDoc.DocumentNode.SelectSingleNode("//table").isNull(),1)

# change the document
oLink.SetAttributeValue("href","https://example.org")
oTitle.InnerHtml = "New <i>title</i>"
cOut = oDoc.DocumentNode.OuterHtml
dnAssert("an attribute was set",substr(cOut,"https://example.org") > 0 and substr(cOut,"http://x.org") = 0,1)
dnAssert("the inner HTML was set",substr(cOut,"New <i>title</i>") > 0,1)
oItems.Item(0).Remove()
dnAssert("a node was removed",oDoc.DocumentNode.SelectNodes("//li").Count,2)

dnTestSummary()
