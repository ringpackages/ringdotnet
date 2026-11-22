# Fluid: Liquid templates; a parser object, a template context with values, filters, loops, and the errors of parsing
load "pkg.ring"
pkgUse("fluid",[["Fluid.Core","3.0.0"]],[["Fluid.dll",["Fluid","Fluid.Values"]]])
pkgImport("fluid","Fluid.dll","Fluid")
pkgImport("fluid","Fluid.dll","Fluid.Values")

oParser = new FluidParser()
oTemplate = oParser.Parse("Hello {{ name | upcase }}! {% if n > 2 %}many{% else %}few{% endif %}")
oContext = new TemplateContext()
oContext.SetValue("name","ring")
oContext.SetValue("n",3)
dnAssert("a filter and a condition",oTemplate.Render(oContext),"Hello RING! many")
oContext.SetValue("n",1)
dnAssert("the other branch",oTemplate.Render(oContext),"Hello RING! few")

# a loop over a list of texts
oLoop = oParser.Parse("{% for item in items %}{{ item }},{% endfor %}")
oLoopContext = new TemplateContext()
oLoopContext.SetValue("items",["a","b","c"])
dnAssert("a loop over a list",oLoop.Render(oLoopContext),"a,b,c,")

# the filters of Liquid
oFilters = oParser.Parse("{{ 'hello world' | capitalize }} {{ 'a,b,c' | split: ',' | size }} {{ 5 | plus: 3 }} {{ 'abc' | append: 'def' }}")
dnAssert("filters",oFilters.Render(new TemplateContext()),"Hello world 3 8 abcdef")

# a template with an error
aGood = oParser.TryParse("{{ ok }}")          # the out parameters come back in a list: [result, template, error]
dnAssert("a good template is valid",aGood[1],1)
aBad = oParser.TryParse("{% if %}")
dnAssert("a bad template is not",aBad[1],0)
dnAssert("and the error says why",len(aBad[3]) > 0,1)

dnTestSummary()
