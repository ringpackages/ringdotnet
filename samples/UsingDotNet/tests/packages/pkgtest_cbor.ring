# PeterO.Cbor: CBOR objects; encoded to bytes (binary text) and decoded again; known encodings from the CBOR specification
load "pkg.ring"
pkgUse("cbor",[["PeterO.Cbor","4.5.5"]],[["Cbor.dll",["PeterO.Cbor"]]])
pkgImport("cbor","Cbor.dll","PeterO.Cbor")

oNumber = dnStatic("PeterO.Cbor.CBORObject","FromObject",[500])
dnAssert("500 is 19 01f4",hexs(oNumber.EncodeToBytes(NULL)),"1901f4")
oText = dnStatic("PeterO.Cbor.CBORObject","FromObject",["ring"])
dnAssert("a text is 64 72696e67",hexs(oText.EncodeToBytes(NULL)),"6472696e67")
dnAssert("true is f5",hexs(dnStatic("PeterO.Cbor.CBORObject","True",[]).EncodeToBytes(NULL)),"f5")

oMap = dnStatic("PeterO.Cbor.CBORObject","NewMap",[])
oMap.callMethod("Add",["name","Ann"])
oMap.callMethod("Add",["age",30])
cBytes = oMap.EncodeToBytes(NULL)
dnAssert("a map has the bytes",len(cBytes) > 10,1)

oBack = dnStatic("PeterO.Cbor.CBORObject","DecodeFromBytes",[cBytes])
dnAssert("a text key reads back",oBack.Item("name").AsString(),"Ann")
dnAssert("a number reads back",oBack.Item("age").AsInt32(),30)
dnAssert("two keys",oBack.Count,2)

dnAssert("JSON from a CBOR object",substr(oBack.ToJSONString(NULL),'"name"') > 0,1)
oFromJson = dnStatic("PeterO.Cbor.CBORObject","FromJSONString",['{"a":[1,2,3]}'])
dnAssert("an array from JSON",oFromJson.Item("a").Count,3)

dnTestSummary()

func hexs cBytes

	cOut = ""
	for i = 1 to len(cBytes)
		cOut += right("0" + hex(ascii(cBytes[i])),2)
	next
	return lower(cOut)
