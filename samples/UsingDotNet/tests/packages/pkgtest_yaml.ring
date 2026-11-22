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

oDeserializer = new DeserializerBuilder().Build()
cDictionary = "System.Collections.Generic.Dictionary`2[[System.String],[System.String]]"
oBack = oDeserializer.Deserialize([ :typeArguments = [cDictionary], :input = cYaml ])
dnAssert("a dictionary read back",oBack.Count,2)
dnAssert("a value read back",oBack.Item("name"),"Ring")

oList = oDeserializer.Deserialize([ :typeArguments = ["System.Collections.Generic.List`1[[System.Int32]]"], :input = "- 1" + nl + "- 2" + nl + "- 3" ])
dnAssert("a list of numbers",oList.Count,3)
dnAssert("an item of the list",oList.Item(1),2)

dnTestSummary()
