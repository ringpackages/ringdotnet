# Fizzler: CSS selectors over HtmlAgilityPack nodes (extension methods on HtmlNode from a second package)
load "pkg.ring"
pkgUse("fizzler",[["Fizzler.Systems.HtmlAgilityPack","1.2.1"]],[["HtmlAgilityPack.dll",["HtmlAgilityPack"]],["Fizzler.Systems.HtmlAgilityPack.dll",["Fizzler.Systems.HtmlAgilityPack"]],["Fizzler.dll",[]]])
pkgImport("fizzler","HtmlAgilityPack.dll","HtmlAgilityPack")
pkgImport("fizzler","Fizzler.Systems.HtmlAgilityPack.dll","Fizzler.Systems.HtmlAgilityPack")

oDoc = new HtmlDocument()
oDoc.LoadHtml('<div id="main"><ul class="list"><li class="a">one</li><li class="b">two</li><li class="a b">three</li></ul><p>text</p></div>')
oRoot = oDoc.DocumentNode

dnAssert("by tag",len(oRoot.callMethod("QuerySelectorAll",["li"]).toList()),3)
dnAssert("by class",len(oRoot.callMethod("QuerySelectorAll",["li.a"]).toList()),2)
dnAssert("by two classes",len(oRoot.callMethod("QuerySelectorAll",["li.a.b"]).toList()),1)
dnAssert("by id and a child",oRoot.callMethod("QuerySelector",["#main > p"]).InnerText,"text")
dnAssert("the first of a type",oRoot.callMethod("QuerySelector",["li:first-child"]).InnerText,"one")
dnAssert("the last of a type",oRoot.callMethod("QuerySelector",["li:last-child"]).InnerText,"three")
dnAssert("a selector that matches nothing",len(oRoot.callMethod("QuerySelectorAll",["table"]).toList()),0)
dnAssert("a missing node is the null",dnIsNull(oRoot.callMethod("QuerySelector",["table"])),1)
dnAssert("and a node is not",dnIsNull(oRoot.callMethod("QuerySelector",["li"])),0)

dnTestSummary()
