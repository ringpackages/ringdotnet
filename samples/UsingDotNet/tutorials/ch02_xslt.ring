# XSLT - turn XML into text, CSV and HTML with a stylesheet (System.Xml.Xsl)
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Xml.Xsl"
}

C_XML = '<library><book year="1937" genre="fantasy"><title>The Hobbit</title><price>9.5</price></book><book year="1965" genre="scifi"><title>Dune</title><price>12</price></book><book year="1984" genre="scifi"><title>Neuromancer</title><price>8.25</price></book></library>'

# A stylesheet is XML too: a template says what to write for a part of the input. xsl:output chooses the kind of result.
C_TEXT = '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:output method="text"/>'
C_TEXT += '<xsl:template match="/library"><xsl:for-each select="book"><xsl:sort select="@year" data-type="number" order="descending"/>'
C_TEXT += '<xsl:value-of select="title"/> (<xsl:value-of select="@year"/>)<xsl:text>&#10;</xsl:text></xsl:for-each>'
C_TEXT += 'Total: <xsl:value-of select="sum(book/price)"/></xsl:template></xsl:stylesheet>'

C_CSV = '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:output method="text"/>'
C_CSV += '<xsl:template match="/library">title,year,price<xsl:text>&#10;</xsl:text><xsl:for-each select="book[price &lt; 10]">'
C_CSV += '<xsl:value-of select="title"/>,<xsl:value-of select="@year"/>,<xsl:value-of select="price"/><xsl:text>&#10;</xsl:text></xsl:for-each></xsl:template></xsl:stylesheet>'

C_HTML = '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:output method="html" indent="yes"/>'
C_HTML += '<xsl:template match="/library"><table><xsl:for-each select="book"><tr class="{@genre}"><td><xsl:value-of select="title"/></td><td><xsl:value-of select="price"/></td></tr></xsl:for-each></table></xsl:template></xsl:stylesheet>'

func main
	cFolder = new Path().Combine([new Path().GetTempPath(),"ringdotnet_xslt"])
	new Directory().CreateDirectory(cFolder)
	cInput = new Path().Combine([cFolder,"library.xml"])
	new File().WriteAllText([ :path = cInput, :contents = C_XML ])

	# 1. XSLT turns an input document into another document. XslCompiledTransform compiles the stylesheet once; Transform runs it.
	? "1. a text report, newest book first, with the total price:"
	? indent(transform(cFolder,cInput,C_TEXT,"report.txt"))

	# 2. The same data as CSV, only the books cheaper than 10 (a filter inside the select)
	? nl + "2. CSV of the cheap books:"
	? indent(transform(cFolder,cInput,C_CSV,"cheap.csv"))

	# 3. HTML: the result is a document that a browser can show. {@genre} puts the attribute into the class of the row.
	cHtml = transform(cFolder,cInput,C_HTML,"table.html")
	? nl + "3. an HTML table (" + len(cHtml) + " characters) with " + countOf(cHtml,"<tr") + " rows; the genres became classes: " + yesNo(substr(cHtml,'class="scifi"') > 0)

	# 4. The HTML that the third stylesheet wrote
	? nl + "4. the HTML:"
	? indent(cHtml)

	new Directory().Delete([ :path = cFolder, :recursive = True ])

# compile the stylesheet text, run it over the input file, return the text of the output file
func transform cFolder, cInput, cStylesheet, cOutputName
	cSheet = new Path().Combine([cFolder,cOutputName + ".xsl"])
	cOutput = new Path().Combine([cFolder,cOutputName])
	new File().WriteAllText([ :path = cSheet, :contents = cStylesheet ])
	oTransform = new XslCompiledTransform()
	oTransform.@Load(cSheet)
	oTransform.Transform([ :inputUri = cInput, :resultsFile = cOutput ])
	return new File().ReadAllText(cOutput)

func indent cText
	cText = substr(cText,char(13),"")
	while right(cText,1) = char(10)
		cText = left(cText,len(cText) - 1)
	end
	return "   " + substr(cText,char(10),nl + "   ")

func countOf cText, cPart
	nCount = 0
	nPos = 1
	while true
		nFound = substr(substr(cText,nPos,len(cText)),cPart)
		if nFound = 0
			exit
		ok
		nCount++
		nPos += nFound + len(cPart) - 1
		if nPos > len(cText)
			exit
		ok
	end
	return nCount

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
