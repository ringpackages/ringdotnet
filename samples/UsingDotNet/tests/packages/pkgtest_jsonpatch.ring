# JsonPatch.Net: RFC 6902 patches (add, replace, remove, move, test) applied to JSON values; the patch is read from its JSON text, the document is a JsonNode
load "pkg.ring"
pkgUse("jsonpatch",[["JsonPatch.Net","5.1.0"]],[["JsonPatch.Net.dll",["Json.Patch"]],["JsonPointer.Net.dll",["Json.Pointer"]],["Json.More.dll",[]]])
pkgImport("jsonpatch","JsonPatch.Net.dll","Json.Patch")
pkgImport("jsonpatch","JsonPointer.Net.dll","Json.Pointer")

oJson = dnType("System.Text.Json.JsonSerializer")
oNode = dnType("System.Text.Json.Nodes.JsonNode")
oDocument = oNode.callMethod("Parse",['{"name":"ring","tags":["a","b"],"n":1}'])
cPatchText = '[{"op":"replace","path":"/name","value":"ringdotnet"},{"op":"add","path":"/tags/-","value":"c"},{"op":"remove","path":"/n"}]'
oPatch = oJson.callGeneric("Deserialize",["Json.Patch.JsonPatch"],[cPatchText])
dnAssert("the patch has three operations",oPatch.Operations.Count,3)
oResult = oPatch.Apply(oDocument)
dnAssert("the patch was applied",oResult.IsSuccess,1)
cResult = oResult.Result.ToJsonString(NULL)
dnAssert("the result",cResult,'{"name":"ringdotnet","tags":["a","b","c"]}')

# the document that was patched is not changed (the patch works on a copy)
dnAssert("the original is unchanged",oDocument.ToJsonString(NULL),'{"name":"ring","tags":["a","b"],"n":1}')

# move and copy
oMove = oJson.callGeneric("Deserialize",["Json.Patch.JsonPatch"],['[{"op":"move","from":"/name","path":"/title"},{"op":"copy","from":"/n","path":"/m"}]'])
dnAssert("move and copy",oMove.Apply(oDocument).Result.ToJsonString(NULL),'{"tags":["a","b"],"n":1,"title":"ring","m":1}')

# a test that fails stops the patch: the result says it was not a success, with the error
oGuard = oJson.callGeneric("Deserialize",["Json.Patch.JsonPatch"],['[{"op":"test","path":"/name","value":"other"},{"op":"remove","path":"/n"}]'])
oFailed = oGuard.Apply(oDocument)
dnAssert("a failing test is not a success",oFailed.IsSuccess,0)
dnAssert("the error tells why",len(oFailed.Error) > 0,1)
oPass = oJson.callGeneric("Deserialize",["Json.Patch.JsonPatch"],['[{"op":"test","path":"/name","value":"ring"},{"op":"remove","path":"/n"}]'])
dnAssert("a passing test lets the patch go on",oPass.Apply(oDocument).IsSuccess,1)

# a patch that points at a path that does not exist
oBad = oJson.callGeneric("Deserialize",["Json.Patch.JsonPatch"],['[{"op":"remove","path":"/missing/deep"}]'])
dnAssert("a path that does not exist is not a success",oBad.Apply(oDocument).IsSuccess,0)

# the difference of two documents is a patch that turns one into the other
oOther = oNode.callMethod("Parse",['{"name":"ring","tags":["a","x"],"n":2}'])
oDiff = dnStatic("Json.Patch.PatchExtensions","CreatePatch",[oDocument,oOther])
dnAssert("the difference has operations",oDiff.Operations.Count >= 2,1)
dnAssert("applying the difference gives the other document",oDiff.Apply(oDocument).Result.ToJsonString(NULL),oOther.ToJsonString(NULL))

# pointers: Evaluate reads a JsonElement (a struct), the answer is a JsonElement or null when nothing is there
oElement = oJson.callGeneric("Deserialize",["System.Text.Json.JsonElement"],['{"name":"ring","tags":["a","b"]}'])
oPointer = dnStatic("Json.Pointer.JsonPointer","Parse",["/tags/1"])
dnAssert("the pointer has two segments",oPointer.SegmentCount,2)
dnAssert("a pointer into the document",oPointer.Evaluate(oElement).ToString(),"b")
dnAssert("the pointer as text",oPointer.ToString(),"/tags/1")
dnAssert("a pointer that finds nothing is null",dnIsNull(dnStatic("Json.Pointer.JsonPointer","Parse",["/nothing"]).Evaluate(oElement)),1)

dnTestSummary()
