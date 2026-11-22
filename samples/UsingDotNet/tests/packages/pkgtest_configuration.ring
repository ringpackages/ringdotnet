# Microsoft.Extensions.Configuration (the library has the classes of this namespace itself: the DLLs are only loaded): a configuration built from an in-memory dictionary and a JSON stream (the later source wins), sections, keys with colons, binder extension methods
load "pkg.ring"
pkgUse("configuration",[["Microsoft.Extensions.Configuration.Json","9.0.23"],["Microsoft.Extensions.Configuration.Binder","9.0.23"]],[["Microsoft.Extensions.Configuration.dll",[]],["Microsoft.Extensions.Configuration.Abstractions.dll",[]],["Microsoft.Extensions.Configuration.Json.dll",[]],["Microsoft.Extensions.Configuration.Binder.dll",[]]])
dnImport("System.Collections.Generic")
dnImport("System.IO")

oBuilder = dnNew("Microsoft.Extensions.Configuration.ConfigurationBuilder",[])          # the library has its own classes of this namespace (ASP.NET Core): the class is made by its type name
oDefaults = new StringDictionary()
oDefaults.SetItem("App:Name","Defaults")
oDefaults.SetItem("App:Port","80")
oDefaults.SetItem("App:Debug","false")
dnRequest("call",[dnType("Microsoft.Extensions.Configuration.MemoryConfigurationBuilderExtensions"),"AddInMemoryCollection",oBuilder,oDefaults])

# a JSON stream, added after: it wins
cJson = '{"App":{"Name":"Ring","Port":8080,"Tags":["a","b"]},"Db":{"Server":"localhost"}}'
oStream = new MemoryStream().@New(cJson)
dnRequest("call",[dnType("Microsoft.Extensions.Configuration.JsonConfigurationExtensions"),"AddJsonStream",oBuilder,oStream])
oConfig = oBuilder.Build()

dnAssert("a key from JSON overrides the dictionary",oConfig.Item("App:Name"),"Ring")
dnAssert("a number as text",oConfig.Item("App:Port"),"8080")
dnAssert("a key only the dictionary has",oConfig.Item("App:Debug"),"false")
dnAssert("a key only the JSON has",oConfig.Item("Db:Server"),"localhost")
dnAssert("an array item has its index in the key",oConfig.Item("App:Tags:1"),"b")
dnAssert("a missing key is the null object",oConfig.Item("Nothing:Here").isNull(),1)

# a section
oApp = oConfig.GetSection("App")
dnAssert("the path of a section",oApp.Path,"App")
dnAssert("a key of a section",oApp.Item("Name"),"Ring")
aChildren = oApp.GetChildren().toList()
dnAssert("the children of a section",len(aChildren),4)

# the binder: a generic extension method with the type that the value becomes
oBinder = dnType("Microsoft.Extensions.Configuration.ConfigurationBinder")
dnAssert("GetValue<int>",oBinder.callGeneric("GetValue",["System.Int32"],[oConfig,"App:Port"]),8080)
dnAssert("GetValue<bool>",oBinder.callGeneric("GetValue",["System.Boolean"],[oConfig,"App:Debug"]),0)
dnAssert("GetValue<string>",oBinder.callGeneric("GetValue",["System.String"],[oConfig,"Db:Server"]),"localhost")

dnTestSummary()
