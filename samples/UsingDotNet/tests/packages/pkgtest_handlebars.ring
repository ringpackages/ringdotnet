# Handlebars.Net: templates with values, each, if and a block; the compiled template is a delegate that Ring calls with Invoke and a dictionary as the data
load "pkg.ring"
pkgUse("handlebars",[["Handlebars.Net","2.4.3"]],[["Handlebars.dll",["HandlebarsDotNet"]]])
pkgImport("handlebars","Handlebars.dll","HandlebarsDotNet")
dnImport("System.Collections.Generic")

# a template with a value
oTemplate = dnStatic("HandlebarsDotNet.Handlebars","Compile",["Hello {{name}}!"])
oData = new ObjectDictionary()
oData.SetItem("name","Ring")
dnAssert("a value in a template",oTemplate.callMethod("Invoke",[oData]),"Hello Ring!")

# the template is compiled once and runs with other data
oOther = new ObjectDictionary()
oOther.SetItem("name","Cairo")
dnAssert("another value",oTemplate.callMethod("Invoke",[oOther]),"Hello Cairo!")

# {{#if}} and {{else}}
oConditional = dnStatic("HandlebarsDotNet.Handlebars","Compile",["{{#if admin}}admin{{else}}user{{/if}}"])
oAdmin = new ObjectDictionary()
oAdmin.SetItem("admin",1)
dnAssert("the if branch",oConditional.callMethod("Invoke",[oAdmin]),"admin")
oUser = new ObjectDictionary()
oUser.SetItem("admin",0)
dnAssert("the else branch",oConditional.callMethod("Invoke",[oUser]),"user")

# {{#each}} over a list of texts
oEach = dnStatic("HandlebarsDotNet.Handlebars","Compile",["{{#each items}}[{{this}}]{{/each}}"])
oList = new ObjectDictionary()
oItems = new ObjectList()
oItems.Add("a")
oItems.Add("b")
oItems.Add("c")
oList.SetItem("items",oItems)
dnAssert("each over a list",oEach.callMethod("Invoke",[oList]),"[a][b][c]")

# html is escaped, triple braces are not
oEscape = dnStatic("HandlebarsDotNet.Handlebars","Compile",["{{text}} {{{text}}}"])
oHtml = new ObjectDictionary()
oHtml.SetItem("text","<b>")
dnAssert("double braces escape, triple braces do not",oEscape.callMethod("Invoke",[oHtml]),"&lt;b&gt; <b>")

# a missing value is empty
dnAssert("a missing value is empty",oTemplate.callMethod("Invoke",[new ObjectDictionary()]),"Hello !")

dnTestSummary()
