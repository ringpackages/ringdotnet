# Apache.Avro: schemas parsed from JSON text into objects (records, fields, types) and written back as text
load "pkg.ring"
pkgUse("avro",[["Apache.Avro","1.12.0"]],[["Avro.dll",["Avro"]]])
pkgImport("avro","Avro.dll","Avro")

cSchema = '{"type":"record","name":"Person","namespace":"demo","fields":[{"name":"name","type":"string"},{"name":"age","type":"int"},{"name":"tags","type":{"type":"array","items":"string"}}]}'
oSchema = dnStatic("Avro.Schema","Parse",[cSchema])
dnAssert("the record name",oSchema.Name,"Person")
dnAssert("the full name",oSchema.Fullname,"demo.Person")
dnAssert("the namespace",oSchema.Namespace,"demo")
dnAssert("three fields",oSchema.Fields.Count,3)

oAge = oSchema.Fields.Item(1)
dnAssert("a field name",oAge.Name,"age")
dnAssert("a field type",oAge.Schema.Name,"int")
dnAssert("the position of a field",oAge.Pos,1)

oTags = oSchema.Fields.Item(2)
dnAssert("an array type",oTags.Schema.Name,"array")
dnAssert("the item type of the array",oTags.Schema.ItemSchema.Name,"string")

dnAssert("the schema as text",substr(oSchema.ToString(),'"name":"Person"') > 0,1)
dnAssert("a primitive schema",dnStatic("Avro.Schema","Parse",['"long"']).Name,"long")

cError = ""
try
	dnStatic("Avro.Schema","Parse",['{"type":"record","fields":[]}'])
catch
	cError = cCatchError
done
dnAssert("a bad schema raises an error",len(cError) > 0,1)

dnTestSummary()
