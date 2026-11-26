# route templates - "users/{id}/orders/{orderId?}", optional and default values, catch-all parameters, and choosing a route
load "dotnet.ring"

using {
	"Microsoft.AspNetCore.Routing.Template"
	"Microsoft.AspNetCore.Routing"
	"System"
	"RingDotNet.Web"                  # the routing classes are part of the ASP.NET Core runtime: this line starts it
}


func main

	# A web program decides what to do from the PATH of the address: /users/42 shows user 42, /files/docs/a/b.txt shows a file. A ROUTE
	# TEMPLATE describes such a path with named parts in braces. ASP.NET Core uses them for every route; the same classes work here.
	# {id}             a required part, its value is read into "id"
	# {orderId?}       an optional part
	# {page=1}         a part with a default value
	# {*path}          the catch-all: everything that is left, with its slashes
	# {id:int}         a constraint (a router checks it: only whole numbers): the template keeps it as a name
	? "1. the templates and their parts:"
	for cRoute in ["users/{id}/orders/{orderId?}","products/{category}/{page=1}","files/{*path}","items/{id:int}"]
		oTemplate = (new TemplateParser).Parse(cRoute)
		cParts = ""
		aParts = oTemplate.Parameters.toList()
		for oPart in aParts
			cKind = "required"
			if oPart.IsOptional
				cKind = "optional"
			ok
			if oPart.IsCatchAll
				cKind = "catch-all"
			ok
			xDefault = oPart.DefaultValue          # a text, or the null object when there is no default
			if not isObject(xDefault)
				cKind = "default " + xDefault
			ok
			cParts += oPart.Name + " (" + cKind + ")  "
		next
		? "   " + padRight(cRoute,32) + cParts
	next

	# 2. Matching a path. TryMatch answers yes or no and fills a dictionary with the values of the parts.
	? nl + "2. users/{id}/orders/{orderId?} against some paths:"
	for cPath in ["/users/42/orders/7","/users/42/orders","/users/42","/users/42/orders/7/extra","/USERS/5/ORDERS/9"]
		? "   " + padRight(cPath,28) + showMatch("users/{id}/orders/{orderId?}",cPath)
	next

	# 3. Defaults and the catch-all
	? nl + "3. products/{category}/{page=1}:"
	for cPath in ["/products/shoes","/products/shoes/3"]
		? "   " + padRight(cPath,28) + showMatch("products/{category}/{page=1}",cPath)
	next
	? nl + "   files/{*path} takes the rest of the path, with its slashes:"
	for cPath in ["/files/readme.txt","/files/docs/guide/intro.md"]
		? "   " + padRight(cPath,28) + showMatch("files/{*path}",cPath)
	next

	# 4. A list of routes: the program tries them in order and uses the first that matches. Put the most specific routes first.
	aTable = [ ["users/{id}/orders/{orderId?}","show the orders of a user"], ["users/{id}","show a user"], ["files/{*path}","send a file"], ["{page}","show a page"] ]
	? nl + "4. which route handles which path:"
	for cPath in ["/users/42","/users/42/orders/7","/files/a/b.png","/about","/users"]
		? "   " + padRight(cPath,24) + chooseRoute(aTable,cPath)
	next

# the dictionary of values for a template and a path, as text; "no match" when the path does not fit the template
func showMatch cTemplate,cPath

	oValues = new RouteValueDictionary
	if not matches(cTemplate,cPath,oValues)
		return "no match"
	ok
	cText = ""
	aKeys = sort(oValues.Keys.toList())
	for cKey in aKeys
		cText += cKey + " = " + oValues.Item(cKey) + "   "
	next
	return "match   " + cText

func matches cTemplate,cPath,oValues

	oTemplate = (new TemplateParser).Parse(cTemplate)
	# the defaults of the template ({page=1}) are given to the matcher: a part with a default may be missing at the END of the path
	oDefaults = new RouteValueDictionary
	aParts = oTemplate.Parameters.toList()
	for oPart in aParts
		xDefault = oPart.DefaultValue
		if not isObject(xDefault)
			oDefaults.Add(oPart.Name,xDefault)
		ok
	next
	oMatcher = new TemplateMatcher(oTemplate,oDefaults)
	return oMatcher.TryMatch((new PathString).@New(cPath),oValues)

func chooseRoute aTable,cPath

	for aRoute in aTable
		oValues = new RouteValueDictionary
		if matches(aRoute[1],cPath,oValues)
			return aRoute[1] + "  ->  " + aRoute[2]
		ok
	next
	return "(no route: 404 not found)"

func padRight cText,nWidth

	return cText + copy(" ",nWidth - len(cText))
