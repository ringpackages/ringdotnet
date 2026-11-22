# Newtonsoft.Json: serialize, deserialize with the type arguments (a generic method), LINQ to JSON (JObject, JArray, SelectToken, Value<T>)
load "pkg.ring"
pkgUse("newtonsoft",[["Newtonsoft.Json","13.0.4"]],[["Newtonsoft.Json.dll",["Newtonsoft.Json","Newtonsoft.Json.Linq"]]])
pkgImport("newtonsoft","Newtonsoft.Json.dll","Newtonsoft.Json")
pkgImport("newtonsoft","Newtonsoft.Json.dll","Newtonsoft.Json.Linq")
dnImport("System.Collections.Generic")

# a dictionary and a list to text
oData = new StringDictionary()
oData.SetItem("name","Ring")
oData.SetItem("version","1.28")
cJson = dnStatic("Newtonsoft.Json.JsonConvert","SerializeObject",[oData])
dnAssert("a dictionary as JSON",cJson,'{"name":"Ring","version":"1.28"}')
oNumbers = new NumberList()
oNumbers.Add(1)
oNumbers.Add(2.5)
dnAssert("a list as JSON",dnStatic("Newtonsoft.Json.JsonConvert","SerializeObject",[oNumbers]),"[1.0,2.5]")
cIndented = dnStatic("Newtonsoft.Json.JsonConvert","SerializeObject",[oData,dnStatic("Newtonsoft.Json.Formatting","Indented",[])])
dnAssert("indented JSON has lines",substr(cIndented,nl) > 0 or substr(cIndented,char(10)) > 0,1)

# JSON to objects: the type argument only the result shows
oJsonConvert = dnType("Newtonsoft.Json.JsonConvert")
oBack = oJsonConvert.callGeneric("DeserializeObject",["System.Collections.Generic.Dictionary`2[[System.String],[System.String]]"],[cJson])
dnAssert("a dictionary read back",oBack.Count,2)
dnAssert("a value read back",oBack.Item("version"),"1.28")
oInts = oJsonConvert.callGeneric("DeserializeObject",["System.Collections.Generic.List`1[[System.Int32]]"],["[10,20,30]"])
dnAssert("a list of numbers read back",oInts.Count,3)
dnAssert("an item",oInts.Item(2),30)

# LINQ to JSON
oObject = dnStatic("Newtonsoft.Json.Linq.JObject","Parse",['{"name":"Ann","age":31,"tags":["a","b"],"address":{"city":"Cairo"}}'])
dnAssert("a property of a JObject",oObject.Item("name").ToString(),"Ann")
dnAssert("a typed value (Value<T>, the type argument in the name)",oObject.callGeneric("Value",["System.Int32"],["age"]),31)
dnAssert("SelectToken",oObject.SelectToken("address.city").ToString(),"Cairo")
dnAssert("an array in the object",oObject.Item("tags").Count,2)
dnAssert("an item of the array",oObject.Item("tags").Item(1).ToString(),"b")
oObject.SetItem("age",32)
dnAssert("a property that was set",oObject.callGeneric("Value",["System.Int32"],["age"]),32)
oObject.Remove("tags")
dnAssert("a property that was removed",oObject.ContainsKey("tags"),0)

# a parse error is a Ring error with the position
try
	dnStatic("Newtonsoft.Json.Linq.JObject","Parse",["{ not json"])
	dnAssert("bad JSON is an error",1,0)
catch
	dnAssert("bad JSON is an error",substr(cCatchError,"JsonReaderException") > 0,1)
done

dnTestSummary()
