# Scriban: a template engine; a Ring list and values are the model; loops, conditions, functions and parse errors
load "pkg.ring"
pkgUse("scriban",[["Scriban","7.6.1"]],[["Scriban.dll",["Scriban","Scriban.Runtime"]]])
pkgImport("scriban","Scriban.dll","Scriban")
pkgImport("scriban","Scriban.dll","Scriban.Runtime")

# a template with a value
oTemplate = dnStatic("Scriban.Template","Parse",["Hello {{ name }}!"])
dnAssert("the template has no errors",oTemplate.HasErrors,0)
oModel = new ScriptObject()
oModel.SetValue("name","Ring",1)
dnAssert("a value in a template",oTemplate.Render(oModel),"Hello Ring!")

# a loop over a list, a condition and a function of the language
oLoop = dnStatic("Scriban.Template","Parse",["{{ for item in items }}[{{ item | string.upcase }}]{{ end }}{{ if count > 2 }} many{{ else }} few{{ end }}"])
oModel2 = new ScriptObject()
oModel2.SetValue("items",["a","b","c"],1)
oModel2.SetValue("count",3,1)
dnAssert("a loop, a function and a condition",oLoop.Render(oModel2),"[A][B][C] many")
oModel2.SetValue("count",1,1)
dnAssert("the other branch",oLoop.Render(oModel2),"[A][B][C] few")

# arithmetic and a list of lists in the template itself
oMath = dnStatic("Scriban.Template","Parse",["{{ 6 * 7 }} {{ [1, 2, 3] | array.size }}"])
dnAssert("expressions in a template",oMath.Render(NULL),"42 3")

# the template is parsed once and rendered many times
oRow = dnStatic("Scriban.Template","Parse",["{{ n }}x{{ n }}={{ n * n }}"])
cJoined = ""
for n = 1 to 3
	oM = new ScriptObject()
	oM.SetValue("n",n,1)
	cJoined += oRow.Render(oM) + ";"
next
dnAssert("one template, three models",cJoined,"1x1=1;2x2=4;3x3=9;")

# a template with an error
oBad = dnStatic("Scriban.Template","Parse",["{{ if }}"])
dnAssert("a bad template has errors",oBad.HasErrors,1)
dnAssert("the messages of the errors are there",oBad.Messages.Count > 0,1)

dnTestSummary()
