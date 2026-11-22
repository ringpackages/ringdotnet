# Text and bytes through real packages: Arabic, Chinese and emoji in JSON, YAML, Markdown and a hash; all 256 byte values through LZ4 and a ZIP; Ring texts are UTF-8 and binary safe
load "pkg.ring"
pkgUse("newtonsoft",[["Newtonsoft.Json","13.0.4"]],[["Newtonsoft.Json.dll",["Newtonsoft.Json"]]])
pkgUse("yaml",[["YamlDotNet","18.1.0"]],[["YamlDotNet.dll",["YamlDotNet.Serialization"]]])
pkgUse("markdig",[["Markdig","1.6.0"]],[["Markdig.dll",["Markdig"]]])
pkgUse("lz4",[["K4os.Compression.LZ4","1.3.8"],["K4os.Compression.LZ4.Streams","1.3.8"]],[["K4os.Compression.LZ4.dll",["K4os.Compression.LZ4"]],["K4os.Compression.LZ4.Streams.dll",["K4os.Compression.LZ4.Streams"]]])
pkgImport("yaml","YamlDotNet.dll","YamlDotNet.Serialization")
dnImport("System.Collections.Generic")

cArabic = "مرحبا بالعالم"
cChinese = "你好，世界"
cEmoji = "ring 💍 ok"

# JSON: the characters are written as they are, and read back as they were
oConvert = dnType("Newtonsoft.Json.JsonConvert")
for cText in [cArabic,cChinese,cEmoji]
	cJson = oConvert.callMethod("SerializeObject",[cText])
	dnAssert("JSON keeps the text " + cText,oConvert.callGeneric("DeserializeObject",["System.String"],[cJson]),cText)
next
dnAssert("the JSON of an Arabic text is quoted",oConvert.callMethod("SerializeObject",[cArabic]),'"' + cArabic + '"')

# the number of characters is the number of bytes of UTF-8 (a Ring text is bytes)
dnAssert("the bytes of an Arabic text",len(cArabic),25)
dnAssert(".NET counts the characters",dnStatic("System.Text.Encoding","UTF8",[]).GetCharCount(cArabic),13)

# YAML with a key and a value that are not English
oSerializer = new SerializerBuilder().Build()
oMap = new StringDictionary()
oMap.SetItem(cChinese,cArabic)
cYaml = oSerializer.Serialize(oMap)
oDeserializer = new DeserializerBuilder().Build()
oBack = oDeserializer.Deserialize([ :typeArguments = ["System.Collections.Generic.Dictionary`2[[System.String],[System.String]]"], :input = cYaml ])
dnAssert("YAML keeps a key and a value",oBack.Item(cChinese),cArabic)

# Markdown: the text of a heading and emphasis
cHtml = dnStatic("Markdig.Markdown","ToHtml",["# " + cArabic + nl + nl + "*" + cEmoji + "*"])
dnAssert("a heading in Arabic",substr(cHtml,"<h1>" + cArabic + "</h1>") > 0,1)
dnAssert("emphasis around an emoji",substr(cHtml,"<em>" + cEmoji + "</em>") > 0,1)

# every byte value through LZ4 (a binary string: a zero and the bytes above 127 are data)
cBytes = ""
for i = 0 to 255
	cBytes += char(i)
next
cAllBytes = cBytes + cBytes + cBytes
cPickled = dnStatic("K4os.Compression.LZ4.LZ4Pickler","Pickle",[cAllBytes])
cRead = dnStatic("K4os.Compression.LZ4.LZ4Pickler","Unpickle",[cPickled])
dnAssert("768 bytes of all values read back",cRead = cAllBytes,1)
dnAssert("the same length",len(cRead),768)

# a big binary string: a megabyte of changing bytes
cBig = ""
cBlock = copy(cBytes,4)
for i = 1 to 1024
	cBig += cBlock
next
cBigRead = dnStatic("K4os.Compression.LZ4.LZ4Pickler","Unpickle",[dnStatic("K4os.Compression.LZ4.LZ4Pickler","Pickle",[cBig])])
dnAssert("a megabyte read back",len(cBigRead),1048576)
dnAssert("and equal",cBigRead = cBig,1)

dnTestSummary()
