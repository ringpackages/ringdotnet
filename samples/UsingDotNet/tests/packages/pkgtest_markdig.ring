# Markdig: Markdown to HTML (a static method, then a pipeline object), the parsed document
load "pkg.ring"
pkgUse("markdig",[["Markdig","1.6.0"]],[["Markdig.dll",["Markdig","Markdig.Syntax"]]])
pkgImport("markdig","Markdig.dll","Markdig")
pkgImport("markdig","Markdig.dll","Markdig.Syntax")

cHtml = dnStatic("Markdig.Markdown","ToHtml",["# Title" + nl + nl + "Some *emphasis* and a [link](http://x.org)." + nl + nl + "- one" + nl + "- two"])
dnAssert("a heading",substr(cHtml,"<h1>Title</h1>") > 0,1)
dnAssert("emphasis",substr(cHtml,"<em>emphasis</em>") > 0,1)
dnAssert("a link",substr(cHtml,'<a href="http://x.org">link</a>') > 0,1)
dnAssert("a list",substr(cHtml,"<li>two</li>") > 0,1)

# a pipeline with the advanced extensions: tables
oBuilder = new MarkdownPipelineBuilder()
oBuilder.UseAdvancedExtensions()
oPipeline = oBuilder.Build()
cTable = dnStatic("Markdig.Markdown","ToHtml",["| a | b |" + nl + "|---|---|" + nl + "| 1 | 2 |",oPipeline])
dnAssert("a table with the advanced pipeline",substr(cTable,"<th>a</th>") > 0 and substr(cTable,"<td>2</td>") > 0,1)
cPlain = dnStatic("Markdig.Markdown","ToHtml",["| a | b |" + nl + "|---|---|" + nl + "| 1 | 2 |"])
dnAssert("no table without the extension",substr(cPlain,"<table>"),0)

# the parsed document: blocks with their classes and lines
oDoc = dnStatic("Markdig.Markdown","Parse",["# H1" + nl + nl + "para" + nl + nl + "## H2"])
dnAssert("the document has three blocks",oDoc.Count,3)
dnAssert("the first block is a heading",classname(oDoc.Item(0)),"headingblock")
dnAssert("the second block is a paragraph",classname(oDoc.Item(1)),"paragraphblock")
dnAssert("the line of a block",oDoc.Item(2).Line,4)
dnAssert("the level of a heading",oDoc.Item(2).Level,2)
cPlainText = dnStatic("Markdig.Markdown","ToPlainText",["# Hi" + nl + nl + "**bold** text"])
dnAssert("plain text",substr(cPlainText,"Hi") > 0 and substr(cPlainText,"bold text") > 0 and substr(cPlainText,"**") = 0,1)

dnTestSummary()
