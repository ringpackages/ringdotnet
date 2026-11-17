load "../../libraries/dotnetlib/dotnetlib.ring"
using {
	"System.Xml"
	"System.Text.Json"
	"System.Data"
}

# XML with XPath
oDoc = new XmlDocument()
oDoc.LoadXml("<shop><item price='3.5'>apple</item><item price='1.2'>fig</item><item price='9'>melon</item></shop>")
oItems = oDoc.SelectNodes("//item[@price > 2]")
? "Items over 2    : " + oItems.Count
for nLoop = 0 to oItems.Count - 1
	oItem = oItems.Item(nLoop)
	? "  " + oItem.InnerText + " costs " + oItem.GetAttribute("price")
next

# JSON: serialize Ring lists, read documents
oJson = new JsonSerializer()
? "Serialize       : " + oJson.Serialize([1,"two",[3,4]])
oDocument = new JsonDocument().Parse('{"user":"ring","langs":["ring","c","lua"],"stars":123}')
oRoot = oDocument.RootElement
? "user / stars    : " + oRoot.GetProperty("user").GetString() + " / " + oRoot.GetProperty("stars").GetInt32()
? "languages       : " + oRoot.GetProperty("langs").GetArrayLength()

# DataTable with SQL-like filtering and sorting
oTable = new DataTable()
oTable.Columns.Add([ :columnName = "Product", :type = "System.String" ])
oTable.Columns.Add([ :columnName = "Qty", :type = "System.Int32" ])
oTable {
	Rows.Add(["pens",120])
	Rows.Add(["paper",15])
	Rows.Add(["ink",60])
}
? "Total quantity  : " + oTable.Compute("SUM(Qty)","")
oView = oTable.DefaultView
oView.Sort = "Qty DESC"
? "Biggest stock   : " + oView.Item(0).Item("Product")
? "Low stock rows  : " + len(oTable.Select([ :filterExpression = "Qty < 100" ]).toList())
