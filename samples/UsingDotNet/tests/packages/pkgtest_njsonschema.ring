# NJsonSchema: JSON schemas read from text (a task whose result is waited for), made from a sample document, and used to validate JSON texts
load "pkg.ring"
pkgUse("njsonschema",[["NJsonSchema","11.6.2"]],[["NJsonSchema.dll",["NJsonSchema","NJsonSchema.Validation"]],["NJsonSchema.Annotations.dll",[]],["Namotion.Reflection.dll",[]]])
pkgImport("njsonschema","NJsonSchema.dll","NJsonSchema")
pkgImport("njsonschema","NJsonSchema.dll","NJsonSchema.Validation")

cSchemaText = '{"type":"object","required":["name"],"properties":{"name":{"type":"string","minLength":2},"age":{"type":"integer","minimum":0}}}'
oSchema = dnStatic("NJsonSchema.JsonSchema","FromJsonAsync",[cSchemaText]).Result
dnAssert("the type of the schema",oSchema.Type,"Object")
dnAssert("the required property",oSchema.RequiredProperties.toList()[1],"name")
dnAssert("the properties",oSchema.Properties.Count,2)
dnAssert("the type of a property",oSchema.Properties.Item("age").Type,"Integer")
dnAssert("the minimum length of a text",oSchema.Properties.Item("name").MinLength,2)

# documents that follow the schema have no errors; the others have one error for each rule they break
dnAssert("a valid document",oSchema.callMethod("Validate",['{"name":"ann","age":31}']).Count,0)
aErrors = oSchema.callMethod("Validate",['{"age":-1}']).toList()
dnAssert("two errors: a missing property and a number below the minimum",len(aErrors),2)
cKinds = ""
for oError in aErrors
	cKinds += oError.Kind + ","
next
dnAssert("a property is required",substr(cKinds,"PropertyRequired") > 0,1)
dnAssert("a number is below the minimum",substr(cKinds,"NumberTooSmall") > 0,1)
dnAssert("a text that is too short",oSchema.callMethod("Validate",['{"name":"a"}']).toList()[1].Kind,"StringTooShort")
dnAssert("a value of the wrong type",oSchema.callMethod("Validate",['{"name":5}']).toList()[1].Kind,"StringExpected")
dnAssert("the path of an error",oSchema.callMethod("Validate",['{"name":"a"}']).toList()[1].Path,"#/name")

# a schema made from a sample document
oSample = dnStatic("NJsonSchema.JsonSchema","FromSampleJson",['{"id":7,"tags":["a"],"done":true}'])
dnAssert("the schema of a sample is an object",oSample.Type,"Object")
dnAssert("a whole number in the sample",oSample.Properties.Item("id").Type,"Integer")
dnAssert("a list in the sample",oSample.Properties.Item("tags").Type,"Array")
dnAssert("a yes/no in the sample",oSample.Properties.Item("done").Type,"Boolean")

# a schema written out again
cBack = oSchema.ToJson(NULL)
dnAssert("the schema as JSON has its rules",substr(cBack,'"minLength": 2') > 0,1)
dnTestSummary()
