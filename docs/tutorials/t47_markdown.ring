# Tutorial 47: a project - a small Markdown to HTML converter (regular expressions, StringBuilder, files)
load "../../libraries/dotnetlib/dotnetlib.ring"
using {
	"System"
	"System.IO"
	"System.Text"
	"System.Text.RegularExpressions"
}

func main
	cMarkdown = "# Shopping" + nl +
		"" + nl +
		"Things to buy **today** for the *party*, see [the list](http://example.com/list)." + nl +
		"" + nl +
		"## Food" + nl +
		"- bread" + nl +
		"- cheese & `olives`" + nl +
		"- <fresh> fruit" + nl +
		"" + nl +
		"Thank you!"

	? "---- Markdown ----"
	? cMarkdown
	cHtml = markdownToHtml(cMarkdown)
	? nl + "---- HTML ----"
	? cHtml

	# save it as a complete page
	cFile = new Path().Combine(new Path().GetTempPath(),"tutorial47.html")
	new File().WriteAllText(cFile,"<html><body>" + nl + cHtml + nl + "</body></html>")
	? nl + "Saved a page of " + len(new File().ReadAllText(cFile)) + " characters"
	new File().Delete(cFile)

# The converter reads the text line by line and keeps a little state: are we inside a list?
func markdownToHtml cMarkdown
	oHtml = new StringBuilder("")
	lInList = False
	for cLine in str2list(cMarkdown)
		cLine = trim(cLine)
		# an empty line ends a list and a paragraph
		if cLine = ""
			if lInList
				oHtml.AppendLine("</ul>")
				lInList = False
			ok
			loop
		ok
		# a list item starts with "- "
		if left(cLine,2) = "- "
			if not lInList
				oHtml.AppendLine("<ul>")
				lInList = True
			ok
			oHtml.AppendLine("<li>" + inlineHtml(substr(cLine,3)) + "</li>")
			loop
		ok
		if lInList
			oHtml.AppendLine("</ul>")
			lInList = False
		ok
		# headings: the number of # is the level
		if left(cLine,3) = "###"
			oHtml.AppendLine("<h3>" + inlineHtml(trim(substr(cLine,4))) + "</h3>")
		but left(cLine,2) = "##"
			oHtml.AppendLine("<h2>" + inlineHtml(trim(substr(cLine,3))) + "</h2>")
		but left(cLine,1) = "#"
			oHtml.AppendLine("<h1>" + inlineHtml(trim(substr(cLine,2))) + "</h1>")
		else
			oHtml.AppendLine("<p>" + inlineHtml(cLine) + "</p>")
		ok
	next
	if lInList
		oHtml.AppendLine("</ul>")
	ok
	return trim(oHtml.ToString())

# the formatting inside a line: FIRST make the text safe, THEN add our own tags
func inlineHtml cText
	# 1. escape: text typed by people must not become HTML (see tutorial 26)
	cSafe = substr(cText,"&","&amp;")
	cSafe = substr(cSafe,"<","&lt;")
	cSafe = substr(cSafe,">","&gt;")
	# Each step below writes its result to a NEW variable. (x = new Regex(...).Replace(x,...) with the same variable on both
	# sides does not work in Ring: it assigns the new Regex object to x first.)
	# 2. code `x`
	cCode = new Regex("`([^`]+)`").Replace(cSafe,"<code>$1</code>")
	# 3. bold **x** (before italic: it also uses the star)
	cBold = new Regex("\*\*(.+?)\*\*").Replace(cCode,"<strong>$1</strong>")
	# 4. italic *x*
	cItalic = new Regex("\*(.+?)\*").Replace(cBold,"<em>$1</em>")
	# 5. links [text](address)
	cLinks = new Regex("\[([^\]]+)\]\(([^)]+)\)").Replace(cItalic,"<a href='$2'>$1</a>")
	return cLinks
