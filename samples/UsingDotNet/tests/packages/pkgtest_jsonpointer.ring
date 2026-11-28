# JsonPointer.Net: RFC 6901 JSON pointers: parse them, read the parts of a JSON document, build, combine and compare them, and handle pointers that are not valid
load "pkg.ring"
pkgUse("jsonpointer",[["JsonPointer.Net","7.1.0"]],[["JsonPointer.Net.dll",["Json.Pointer"]]])
pkgImport("jsonpointer","JsonPointer.Net.dll","Json.Pointer")
dnImport("System.Text.Json")

oJson = dnStatic("System.Text.Json.JsonDocument","Parse",['{ "name": "Ring", "versions": [1.0, 1.1, 1.28], "meta": { "year": 2016, "a/b": "slash", "m~n": "tilde" } }'])
oDocument = oJson.RootElement

oPointer = (new JsonPointer).Parse("/versions/2")
dnAssert("the text of a pointer",oPointer.ToString(),"/versions/2")
dnAssert("the number of segments",oPointer.SegmentCount,2)
dnAssert("an array item",oPointer.Evaluate(oDocument).ToString(),"1.28")
dnAssert("a property",(new JsonPointer).Parse("/name").Evaluate(oDocument).ToString(),"Ring")
dnAssert("a nested property",(new JsonPointer).Parse("/meta/year").Evaluate(oDocument).ToString(),"2016")

# the special characters are written as ~1 for / and ~0 for ~
dnAssert("a name with a slash",(new JsonPointer).Parse("/meta/a~1b").Evaluate(oDocument).ToString(),"slash")
dnAssert("a name with a tilde",(new JsonPointer).Parse("/meta/m~0n").Evaluate(oDocument).ToString(),"tilde")

# the whole document is the empty pointer
oRoot = (new JsonPointer).Parse("")
dnAssert("the empty pointer is the root",oRoot.SegmentCount,0)
dnAssert("the root pointer is the document",oRoot.Evaluate(oDocument).ToString() = oDocument.ToString(),True)

# a pointer to a part that is not there
dnAssert("a missing part is null",(new JsonPointer).Parse("/nothing").Evaluate(oDocument).isNull(),True)

# the parent and the combination of pointers
oParent = oPointer.GetParent([ :levels = 1 ])
dnAssert("the parent pointer",oParent.ToString(),"/versions")
oBase = (new JsonPointer).Parse("/meta")
oChild = (new JsonPointer).Parse("/year")
dnAssert("a combined pointer",oBase.Combine(oChild).ToString(),"/meta/year")
dnAssert("a pointer starts with another",oPointer.StartsWith(oParent),True)
dnAssert("a pointer does not start with another",oBase.StartsWith(oPointer),False)

# a pointer that is not valid is an error
lError = 0
try
	(new JsonPointer).Parse("no-slash")
catch
	lError = 1
done
dnAssert("a pointer without a slash raises an error",lError,1)

dnTestSummary()
