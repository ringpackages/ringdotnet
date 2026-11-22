# ReverseMarkdown: HTML to Markdown through a converter object and its config
load "pkg.ring"
pkgUse("reversemarkdown",[["ReverseMarkdown","4.6.0"]],[["ReverseMarkdown.dll",["ReverseMarkdown"]]])
pkgImport("reversemarkdown","ReverseMarkdown.dll","ReverseMarkdown")

oConverter = new Converter()
cMarkdown = oConverter.Convert("<h1>Title</h1><p>Some <strong>bold</strong> and <em>italic</em> text.</p>")
dnAssert("a heading",substr(cMarkdown,"# Title") > 0,1)
dnAssert("bold",substr(cMarkdown,"**bold**") > 0,1)
dnAssert("italic",substr(cMarkdown,"*italic*") > 0,1)

cList = oConverter.Convert("<ul><li>one</li><li>two</li></ul>")
dnAssert("a list item",substr(cList,"- one") > 0,1)

cLink = oConverter.Convert('<a href="https://ring-lang.github.io">Ring</a>')
dnAssert("a link",substr(cLink,"[Ring](https://ring-lang.github.io)") > 0,1)

cCode = oConverter.Convert("<pre><code>x = 1</code></pre>")
dnAssert("a code block",substr(cCode,"x = 1") > 0,1)

cArabic = oConverter.Convert("<p>مرحبا <b>بالعالم</b></p>")
dnAssert("Arabic text is kept",substr(cArabic,"**بالعالم**") > 0,1)

dnTestSummary()
