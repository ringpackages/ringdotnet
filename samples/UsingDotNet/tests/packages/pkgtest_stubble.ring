# Stubble: Mustache templates; sections, inverted sections, escaping, partials; the data is a dictionary
load "pkg.ring"
pkgUse("stubble",[["Stubble.Core","1.10.8"]],[["Stubble.Core.dll",["Stubble.Core.Builders","Stubble.Core","Stubble.Core.Interfaces"]]])
pkgImport("stubble","Stubble.Core.dll","Stubble.Core.Builders")
pkgImport("stubble","Stubble.Core.dll","Stubble.Core")
pkgImport("stubble","Stubble.Core.dll","Stubble.Core.Interfaces")
dnImport("System.Collections.Generic")

oRenderer = new StubbleBuilder().Build()
oData = dnNew("System.Collections.Generic.Dictionary`2[[System.String],[System.Object]]",[])
oData.SetItem("name","Ring")
oData.SetItem("html","<b>")
oData.SetItem("show",1)

dnAssert("a variable",rend("Hello {{name}}"),"Hello Ring")
dnAssert("a value is escaped",rend("{{html}}"),"&lt;b&gt;")
dnAssert("triple braces are not",rend("{{{html}}}"),"<b>")
dnAssert("a section that shows",rend("{{#show}}yes{{/show}}"),"yes")
dnAssert("an inverted section hidden",rend("{{^show}}no{{/show}}"),"")
dnAssert("an inverted section of a missing value",rend("{{^missing}}none{{/missing}}"),"none")
dnAssert("a comment",rend("a{{! hidden }}b"),"ab")

dnTestSummary()

func rend cTemplate

	return oRenderer.Render([ :template = cTemplate, :view = oData ])
