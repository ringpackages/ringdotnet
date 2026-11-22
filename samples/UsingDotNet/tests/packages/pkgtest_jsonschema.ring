# JsonSchema.Net: a JSON Schema from text, instances parsed by System.Text.Json (a JsonElement, a struct) checked against it, and the results of the evaluation
load "pkg.ring"
pkgUse("jsonschema",[["JsonSchema.Net","9.7.0"]],[["JsonSchema.Net.dll",["Json.Schema"]],["Json.More.dll",[]],["JsonPointer.Net.dll",[]]])
pkgImport("jsonschema","JsonSchema.Net.dll","Json.Schema")
dnImport("System.Text.Json")

cSchema = '{"type":"object","properties":{"name":{"type":"string","minLength":2},"age":{"type":"integer","minimum":0,"maximum":150},"tags":{"type":"array","items":{"type":"string"},"maxItems":3}},"required":["name","age"]}'
oSchema = dnStatic("Json.Schema.JsonSchema","FromText",[cSchema])
dnAssert("a schema from text",classname(oSchema),"jsonschema")

# an instance that is valid
oGood = parseJson('{"name":"Ann","age":31,"tags":["a","b"]}')
oResult = oSchema.Evaluate(oGood)
dnAssert("a valid instance",oResult.IsValid,1)

# instances that are not
oNoName = parseJson('{"age":31}')
dnAssert("a missing required property",oSchema.Evaluate(oNoName).IsValid,0)
oShort = parseJson('{"name":"A","age":31}')
dnAssert("a text that is too short",oSchema.Evaluate(oShort).IsValid,0)
oOld = parseJson('{"name":"Bo","age":200}')
dnAssert("a number that is too big",oSchema.Evaluate(oOld).IsValid,0)
oWrong = parseJson('{"name":"Bo","age":"old"}')
dnAssert("a value of another type",oSchema.Evaluate(oWrong).IsValid,0)
oMany = parseJson('{"name":"Bo","age":3,"tags":["a","b","c","d"]}')
dnAssert("too many items",oSchema.Evaluate(oMany).IsValid,0)

# a schema with a pattern
oPattern = dnStatic("Json.Schema.JsonSchema","FromText",['{"type":"string","pattern":"^[A-Z]{2}[0-9]{3}$"}'])
dnAssert("a text that matches the pattern",oPattern.Evaluate(parseJson('"AB123"')).IsValid,1)
dnAssert("a text that does not",oPattern.Evaluate(parseJson('"abc"')).IsValid,0)

dnTestSummary()

func parseJson cJson
	return dnStatic("System.Text.Json.JsonDocument","Parse",[cJson]).RootElement
