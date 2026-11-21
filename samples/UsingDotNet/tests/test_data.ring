# Batch: System.Xml, System.Xml.Linq, System.Text.Json, System.Data
load "dotnet.ring"
dnImport("System")
dnImport("System.IO")
dnImport("System.Xml")
dnImport("System.Xml.Linq")
dnImport("System.Text.Json")
dnImport("System.Text.Json.Nodes")
dnImport("System.Data")

# XmlDocument + XPath
oDoc = new XmlDocument()
oDoc.LoadXml("<library><book id='1'><title>Ring</title></book><book id='2'><title>.NET</title></book></library>")
dnAssert("DocumentElement.Name",oDoc.DocumentElement.Name,"library")
oBooks = oDoc.SelectNodes("//book")
dnAssert("SelectNodes count",oBooks.Count,2)
dnAssert("SelectSingleNode",oDoc.SelectSingleNode("//book[@id='2']/title").InnerText,".NET")
oNew = oDoc.CreateElement("book")
oNew.SetAttribute([ :name = "id", :value = "3" ])
oNew.InnerText = "Lua"
oDoc.DocumentElement.AppendChild(oNew)
dnAssert("AppendChild",oDoc.SelectNodes("//book").Count,3)
dnAssert("OuterXml has new node",substr(oDoc.OuterXml,"<book id=" + '"3"' + ">Lua</book>") > 0,1)

# XmlWriter into a StringWriter
oText = new StringWriter()
oSettings = new XmlWriterSettings()
oSettings.OmitXmlDeclaration = 1
oWriter = new XmlWriter().Create([ :output = oText, :settings = oSettings ])
oWriter.WriteStartElement("root")
oWriter.WriteAttributeString([ :localName = "v", :value = "1" ])
oWriter.WriteString("hi")
oWriter.WriteEndElement()
oWriter.Close()
dnAssert("XmlWriter",oText.ToString(),'<root v="1">hi</root>')

# LINQ to XML (strings convert to XName)
oX = new XDocument().Parse("<a><b>1</b><b>2</b><c x='9'/></a>")
dnAssert("XDocument root",oX.Root.Name.LocalName,"a")
dnAssert("XElement.Element",oX.Root.Element("c").Attribute("x").Value,"9")
dnAssert("XElement.Elements",len(oX.Root.Elements("b").toList()),2)
oElem = new XElement("item","text")
oElem.SetAttributeValue("id","7")
dnAssert("new XElement",oElem.ToString(),'<item id="7">text</item>')

# System.Text.Json
oJson = new JsonSerializer()
dnAssert("Serialize list",oJson.Serialize([1,2,3]),"[1,2,3]")
dnAssert("Serialize string",oJson.Serialize("hi"),'"hi"')
# a generic method whose type argument only the result shows: the type arguments are given by name
oTags = oJson.Deserialize([ :typeArguments = ["System.Collections.Generic.List`1[[System.String]]"], :json = '["a","b"]' ])
dnAssert("Deserialize<List<string>>",oTags.Count,2)
oParsed = new JsonDocument().Parse('{"name":"Ring","tags":["a","b"],"n":42}')
oRoot = oParsed.RootElement
dnAssert("JsonElement.GetProperty",oRoot.GetProperty("name").GetString(),"Ring")
dnAssert("JsonElement.GetInt32",oRoot.GetProperty("n").GetInt32(),42)
dnAssert("JsonElement array length",oRoot.GetProperty("tags").GetArrayLength(),2)
oNode = new JsonNode().Parse('{"a":{"b":5}}')
dnAssert("JsonNode indexer",oNode.Item("a").Item("b").ToJsonString(NULL),"5")
oObject = new JsonObject()
oObject.SetItem("x",new JsonValue().Create("y"))
dnAssert("JsonObject.ToJsonString",oObject.ToJsonString(NULL),'{"x":"y"}')

# DataTable
oTable = new DataTable()
oTable.TableName = "people"
oTable.Columns.Add([ :columnName = "Name", :type = "System.String" ])
oTable.Columns.Add([ :columnName = "Age", :type = "System.Int32" ])
oTable.Rows.Add(["Ann",31])
oTable.Rows.Add(["Bob",17])
oTable.Rows.Add(["Cy",45])
dnAssert("DataTable rows",oTable.Rows.Count,3)
dnAssert("DataTable.Select",len(oTable.Select("Age >= 18").toList()),2)
dnAssert("DataTable.Compute",oTable.Compute("SUM(Age)",""),93)
dnAssert("DataRow indexer",oTable.Rows.Item(1).Item("Name"),"Bob")
oView = oTable.DefaultView
oView.Sort = "Age DESC"
dnAssert("DataView sort",oView.Item(0).Item("Name"),"Cy")

nFail = dnTestSummary()
