# JSON as a tree you can change - JsonNode, JsonObject and JsonArray (System.Text.Json.Nodes)
load "dotnet.ring"

using {
	"System"
	"System.Text.Json"
	"System.Text.Json.Nodes"
}

C_CONFIG = '{"name":"shop","port":8080,"debug":false,"tags":["web","sql"],"database":{"host":"localhost","pool":5}}'

func main

	# 1. Parse text into a tree. A JsonNode is an object, an array or a value; AsObject() and AsArray() give the specific class.
	oRoot = new JsonNode().Parse(C_CONFIG).AsObject()
	? "1. name = " + oRoot.Item("name").ToString() + ", port + 1 = " + (number(oRoot.Item("port").ToString()) + 1)

	# 2. Walk down: Item("key") for an object, Item(index) for an array (the first item is index 0)
	? nl + "2. database.host = " + oRoot.Item("database").Item("host").ToString()
	oTags = oRoot.Item("tags").AsArray()
	? "   " + oTags.Count + " tags, the first is " + oTags.Item(0).ToString()
	? "   path of the first tag: " + oTags.Item(0).GetPath()

	# 3. Change the tree: set a value, add a key, add an array item, remove a key
	oRoot.SetItem("port",9090)
	oRoot.Add([ :propertyName = "owner", :value = "Ann" ])
	oTags.Add("json")
	oRoot.Remove("debug")
	? nl + "3. after the changes:"
	? pretty(oRoot)

	# 4. Check what is there before you read it: ContainsKey, and a missing key is the .NET null
	? nl + "4. has 'owner': " + yesNo(oRoot.ContainsKey("owner")) + ", has 'debug': " + yesNo(oRoot.ContainsKey("debug"))
	oMissing = oRoot.Item("nothing")
	? "   reading a missing key gives null: " + yesNo(oMissing.isNull())
	? "   the kind of 'port': " + oRoot.Item("port").GetValueKind() + ", of 'tags': " + oRoot.Item("tags").GetValueKind()

	# 5. Build a new document from Ring values. Ring numbers and texts convert by themselves;
	#    a Ring True is the number 1, so write a real JSON true by parsing it.
	oNew = new JsonObject()
	oNew.Add([ :propertyName = "id", :value = 7 ])
	oNew.Add([ :propertyName = "title", :value = "Report" ])
	oNew.Add([ :propertyName = "final", :value = new JsonNode().Parse("true") ])
	oItems = new JsonArray()
	for nLine = 1 to 3
		oLine = new JsonObject()
		oLine.Add([ :propertyName = "line", :value = nLine ])
		oLine.Add([ :propertyName = "amount", :value = nLine * 10.5 ])
		oItems.Add(oLine)
	next
	oNew.Add([ :propertyName = "items", :value = oItems ])
	? nl + "5. a new document: " + oNew.ToJsonString(NULL)

	# 6. Merge: settings with defaults. Values of the second document win; objects are merged, so nothing else is lost.
	oDefaults = new JsonNode().Parse('{"port":80,"debug":true,"database":{"host":"db","pool":2,"timeout":30}}').AsObject()
	merge(oDefaults,oRoot)
	? nl + "6. defaults merged with our settings:"
	? pretty(oDefaults)

	# 7. DeepClone copies a whole tree; changes to the copy leave the original alone. DeepEquals compares trees by content.
	oCopy = oRoot.DeepClone().AsObject()
	oCopy.SetItem("port",1)
	? nl + "7. the clone has port " + oCopy.Item("port").ToString() + ", the original still " + oRoot.Item("port").ToString()
	? "   trees equal: " + yesNo(new JsonNode().DeepEquals(oRoot,oCopy)) + " (different ports), after copying again: " + yesNo(new JsonNode().DeepEquals(oRoot,oRoot.DeepClone()))

# the tree as indented text
func pretty oNode

	oOptions = new JsonSerializerOptions() {
		WriteIndented = True
	}
	return "   " + substr(oNode.ToJsonString(oOptions),char(10),nl + "   ")

# copy the keys of oSource into oTarget; where both are objects, merge them
func merge oTarget, oSource

	aSourceKeys = keysOf(oSource)
	for cKey in aSourceKeys
		oValue = oSource.Item(cKey)
		if oTarget.ContainsKey(cKey) and oTarget.Item(cKey).GetValueKind() = "Object" and oValue.GetValueKind() = "Object"
			merge(oTarget.Item(cKey).AsObject(),oValue.AsObject())
		else
			oTarget.SetItem(cKey,oValue.DeepClone())
		ok
	next

# the keys of a JsonObject: its text form is parsed again with JsonDocument and its properties listed
func keysOf oObject

	oDocument = new JsonDocument().Parse(oObject.ToJsonString(NULL))
	aKeys = []
	oEnumerator = oDocument.RootElement.EnumerateObject()
	aProperties = oEnumerator.toList()
	for oProperty in aProperties
		aKeys + oProperty.Name
	next
	oDocument.Dispose()
	return aKeys

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"
