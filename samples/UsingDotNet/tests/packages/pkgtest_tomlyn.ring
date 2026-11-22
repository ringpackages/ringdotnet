# Tomlyn 2: TOML text to a model (tables, arrays, values) and back; the model is a dictionary of objects
load "pkg.ring"
pkgUse("tomlyn",[["Tomlyn","2.11.1"]],[["Tomlyn.dll",["Tomlyn","Tomlyn.Model","Tomlyn.Syntax"]]])
pkgImport("tomlyn","Tomlyn.dll","Tomlyn")
pkgImport("tomlyn","Tomlyn.dll","Tomlyn.Model")
pkgImport("tomlyn","Tomlyn.dll","Tomlyn.Syntax")

cToml = 'title = "Ring"' + nl + 'version = 3' + nl + 'ratio = 1.5' + nl + 'enabled = true' + nl + 'tags = ["a", "b", "c"]' + nl + nl + '[server]' + nl + 'host = "localhost"' + nl + 'port = 8080' + nl
oSerializer = dnType("Tomlyn.TomlSerializer")
oModel = oSerializer.callGeneric("Deserialize",["Tomlyn.Model.TomlTable"],[cToml])          # the type argument is the model that the text becomes
dnAssert("a string value",oModel.Item("title"),"Ring")
dnAssert("an integer value",oModel.Item("version"),3)
dnAssert("a float value",oModel.Item("ratio"),1.5)
dnAssert("a boolean value",oModel.Item("enabled"),1)
dnAssert("the number of keys",oModel.Count,6)

# an array and a table
oTags = oModel.Item("tags")
dnAssert("an array",oTags.Count,3)
dnAssert("an item of an array",oTags.Item(1),"b")
oServer = oModel.Item("server")
dnAssert("a table",oServer.Item("host"),"localhost")
dnAssert("a value of a table",oServer.Item("port"),8080)

# a model to text
oBack = new TomlTable()
oBack.SetItem("name","Ring")
oBack.SetItem("count",42)
cOut = oSerializer.callGeneric("Serialize",["Tomlyn.Model.TomlTable"],[oBack])
dnAssert("the key of a string",substr(cOut,'name = "Ring"') > 0,1)
dnAssert("the key of a number",substr(cOut,"count = 42") > 0,1)

# a syntax error: the diagnostics
try
	oSerializer.callGeneric("Deserialize",["Tomlyn.Model.TomlTable"],["this is = = not toml"])
	dnAssert("bad TOML is an error",1,0)
catch
	dnAssert("bad TOML is an error",substr(cCatchError,"TomlException") > 0 or substr(cCatchError,"error") > 0,1)
done

dnTestSummary()
