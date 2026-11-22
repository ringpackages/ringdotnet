# ExCSS: a CSS parser; the style sheet as objects (rules, selectors, properties)
load "pkg.ring"
pkgUse("excss",[["ExCSS","4.3.0"]],[["ExCSS.dll",["ExCSS"]]])
pkgImport("excss","ExCSS.dll","ExCSS")

oParser = new StylesheetParser()
oSheet = oParser.Parse(".card { color: red; margin: 4px } #main p { font-size: 12px }")
aRules = oSheet.StyleRules.toList()
dnAssert("two style rules",len(aRules),2)
dnAssert("a selector",aRules[1].SelectorText,".card")
dnAssert("another selector",aRules[2].SelectorText,"#main p")
dnAssert("a property value",aRules[1].Style.Color,"rgb(255, 0, 0)")
dnAssert("the text of a rule",substr(aRules[1].Style.CssText,"margin") > 0,1)

oMedia = oParser.Parse("@media screen { a { color: blue } } b { top: 0 }")
dnAssert("a rule and a media rule",len(oMedia.Children.toList()),2)

dnTestSummary()
