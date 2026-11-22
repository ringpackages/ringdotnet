# DotLiquid: templates with variables, filters, loops and conditions; the data is a Hash (a dictionary)
load "pkg.ring"
pkgUse("dotliquid",[["DotLiquid","2.2.692"]],[["DotLiquid.dll",["DotLiquid"]]])
pkgImport("dotliquid","DotLiquid.dll","DotLiquid")
dnImport("System.Collections.Generic")

oHash = new Hash()
oHash.SetItem("name","ring")
oHash.SetItem("n",3)

oTemplate = dnStatic("DotLiquid.Template","Parse",["Hello {{ name | upcase }}!"])
dnAssert("a variable and a filter",oTemplate.Render(oHash),"Hello RING!")

oIf = dnStatic("DotLiquid.Template","Parse",["{% if n > 2 %}big{% else %}small{% endif %}"])
dnAssert("a condition",oIf.Render(oHash),"big")

oFor = dnStatic("DotLiquid.Template","Parse",["{% for i in (1..3) %}{{ i }},{% endfor %}"])
dnAssert("a loop over a range",oFor.Render(new Hash()),"1,2,3,")

oMath = dnStatic("DotLiquid.Template","Parse",["{{ n | times: 4 | plus: 1 }}"])
dnAssert("filters in a chain",oMath.Render(oHash),"13")

oMissing = dnStatic("DotLiquid.Template","Parse",["[{{ nothing }}]"])
dnAssert("a missing variable is empty",oMissing.Render(new Hash()),"[]")

cError = ""
try
	dnStatic("DotLiquid.Template","Parse",["{% if %"])
catch
	cError = cCatchError
done
dnAssert("a broken template raises an error",len(cError) > 0,1)

dnTestSummary()
