# YamlDotNet: serialize a dictionary, deserialize with the type arguments (a generic method whose type argument only the result shows)
load "pkg.ring"
pkgUse("yaml",[["YamlDotNet","18.1.0"]],[["YamlDotNet.dll",["YamlDotNet.Serialization"]]])
pkgImport("yaml","YamlDotNet.dll","YamlDotNet.Serialization")
dnImport("System.Collections.Generic")

oSerializer = new SerializerBuilder().Build()
oData = new StringDictionary()
oData.SetItem("name","Ring")
oData.SetItem("version","1.28")
cYaml = oSerializer.Serialize(oData)
dnAssert("the YAML has the keys",substr(cYaml,"name: Ring") > 0 and substr(cYaml,"version: 1.28") > 0,1)

# numbers that go to an object: a whole number is an Int32 in the YAML (5), not 5.0
oNumbers = new ObjectDictionary()
oNumbers.SetItem("count",5)
oNumbers.SetItem("ratio",0.5)
cNumbers = oSerializer.Serialize(oNumbers)
dnAssert("a whole number in YAML",substr(cNumbers,"count: 5") > 0 and substr(cNumbers,"count: 5.") = 0,1)
dnAssert("a fraction in YAML",substr(cNumbers,"ratio: 0.5") > 0,1)

oDeserializer = new DeserializerBuilder().Build()
cDictionary = "System.Collections.Generic.Dictionary`2[[System.String],[System.String]]"
oBack = oDeserializer.Deserialize([ :typeArguments = [cDictionary], :input = cYaml ])
dnAssert("a dictionary read back",oBack.Count,2)
dnAssert("a value read back",oBack.Item("name"),"Ring")

oList = oDeserializer.Deserialize([ :typeArguments = ["System.Collections.Generic.List`1[[System.Int32]]"], :input = "- 1" + nl + "- 2" + nl + "- 3" ])
dnAssert("a list of numbers",oList.Count,3)
dnAssert("an item of the list",oList.Item(1),2)

dnTestSummary()
