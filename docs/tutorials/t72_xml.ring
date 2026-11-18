# Tutorial 72: XML in depth - reading with XDocument, searching with XPath, building and changing a document
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Xml"
	"System.Xml.Linq"
}

func main
	cXml = '<library><book id="1" year="1937"><title>The Hobbit</title><price>9.5</price></book><book id="2" year="1965"><title>Dune</title><price>12</price></book><book id="3" year="1984"><title>Neuromancer</title><price>8.25</price></book></library>'

	# 1. XDocument (LINQ to XML) reads a text into a tree of elements. The root is the outer element.
	oDocument = new XDocument().Parse(cXml)
	? "1. the root element is <" + oDocument.Root.Name.ToString() + ">"

	# 2. Walk the children. Elements(NULL) gives all the child elements; Attribute("x").Value and Element("y").Value read the details.
	aBooks = oDocument.Root.Elements(NULL).toList()
	? nl + "2. " + len(aBooks) + " books:"
	nTotal = 0
	for oBook in aBooks
		nPrice = number(oBook.Element("price").Value)
		nTotal += nPrice
		? "   #" + oBook.Attribute("id").Value + " " + oBook.Element("title").Value + " (" + oBook.Attribute("year").Value + ") costs " + nPrice
	next
	? "   the total price: " + nTotal

	# 3. XPath is a small language to find nodes: /library/book[@year>1950] means "the books with a year above 1950"
	oXml = new XmlDocument()
	oXml.LoadXml(cXml)
	oFound = oXml.SelectNodes("/library/book[@year>1950]")
	? nl + "3. XPath /library/book[@year>1950] finds " + oFound.Count + " books:"
	for nIndex = 0 to oFound.Count - 1
		? "   " + oFound.Item(nIndex).SelectSingleNode("title").InnerText
	next
	? "   the title of book 3: " + oXml.SelectSingleNode("//book[@id='3']/title").InnerText

	# 4. Build a new document from scratch. An element is made with a name and, if you like, content.
	oNew = dnNew("XElement",[ :name = "book" ])
	oNew.SetAttributeValue("id","4")
	oNew.SetAttributeValue("year","1951")
	oNew.Add(dnNew("XElement",[ :name = "title", :content = "Foundation" ]))
	oNew.Add(dnNew("XElement",[ :name = "price", :content = "7.75" ]))
	oDocument.Root.Add(oNew)
	? nl + "4. after adding a book there are " + len(oDocument.Root.Elements(NULL).toList()) + " books; the new one:"
	? oNew.ToString()

	# 5. Change and remove
	oSecond = oDocument.Root.Elements(NULL).toList()[2]
	oSecond.Element("price").Value = "14"
	oDocument.Root.Elements(NULL).toList()[1].Remove()
	? nl + "5. book 2 now costs " + oDocument.Root.Elements(NULL).toList()[1].Element("price").Value + " and the first book is " + oDocument.Root.Elements(NULL).toList()[1].Element("title").Value

	# 6. Save the text and read it back: the structure survives
	cFile = new Path().Combine([new Path().GetTempPath(),"tutorial72.xml"])
	new File().WriteAllText([ :path = cFile, :contents = oDocument.ToString() ])
	oAgain = new XDocument().Parse(new File().ReadAllText(cFile))
	? nl + "6. the saved file has " + len(oAgain.Root.Elements(NULL).toList()) + " books"
	new File().Delete(cFile)

	# 7. Bad XML raises an error: tags that are not closed
	try
		new XDocument().Parse("<library><book></library>")
	catch
		? nl + "7. bad XML: " + substr(left(cCatchError,70),nl," ")
	done
