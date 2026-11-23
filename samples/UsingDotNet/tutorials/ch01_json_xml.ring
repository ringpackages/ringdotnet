# JSON and XML - reading, writing and searching structured data
load "dotnet.ring"

using {
	"System.Text.Json"
	"System.Xml"
}

func main

	# JSON: turn Ring data into text
	oJson = new JsonSerializer()
	? "A Ring list as JSON : " + oJson.Serialize([1,"two",[3,4]])

	# JSON: read a document you received
	cJson = '{"name":"Ring","year":2016,"tags":["fast","small"],"author":{"first":"Ann","country":"Egypt"}}'
	oDocument = new JsonDocument().Parse(cJson)
	oRoot = oDocument.RootElement
	? "The name            : " + oRoot.GetProperty("name").GetString()
	? "The year            : " + oRoot.GetProperty("year").GetInt32()
	? "Number of tags      : " + oRoot.GetProperty("tags").GetArrayLength()
	? "First tag           : " + oRoot.GetProperty("tags").Item(0).GetString()
	? "Nested property     : " + oRoot.GetProperty("author").GetProperty("first").GetString()
	oDocument.Dispose()

	# XML: a document of elements and attributes
	cXml = "<library>"
	cXml += "<book id='1' year='1999'><title>Learn Ring</title><price>25.5</price></book>"
	cXml += "<book id='2' year='2010'><title>Dot Net Basics</title><price>12</price></book>"
	cXml += "<book id='3' year='2022'><title>Ring and .NET</title><price>30</price></book>"
	cXml += "</library>"
	oDoc = new XmlDocument()
	oDoc.LoadXml(cXml)
	oBooks = oDoc.SelectNodes("//book")
	? nl + "Books in the library: " + oBooks.Count
	for nIndex = 0 to oBooks.Count - 1
		oBook = oBooks.Item(nIndex)
		? "  #" + oBook.GetAttribute("id") + " " + oBook.SelectSingleNode("title").InnerText + " (" + oBook.GetAttribute("year") + ")"
	next

	# XPath: ask questions about the document
	? "Books after 2000   : " + oDoc.SelectNodes("//book[@year > 2000]").Count
	? "Price of book 2    : " + oDoc.SelectSingleNode("//book[@id='2']/price").InnerText

	# Changing XML and saving it as text
	oNew = oDoc.CreateElement("book")
	oNew.SetAttribute([ :name = "id", :value = "4" ])
	oNew.InnerText = "A new book"
	oDoc.DocumentElement.AppendChild(oNew)
	? "After adding one   : " + oDoc.SelectNodes("//book").Count + " books"
	? "The XML now        : " + left(oDoc.OuterXml,60) + "..."
