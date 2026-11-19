# escaping - the right encoding for the right place (HTML, URL, JavaScript, JSON, XML, regular expressions and SQL)
load "dotnet.ring"
using {
	"System"
	"System.Net"
	"System.Text.Encodings.Web"
	"System.Text.Json"
	"System.Text.RegularExpressions"
	"System.Xml.Linq"
	"RingDotNet.Data"
}

func main
	# A text from a user can contain characters that mean something in the place where you put it. The rule: ENCODE FOR THE PLACE.
	cText = "<script>alert('x & y')</script>"

	# 1. HTML: < > & and quotes become entities, so the browser shows the text and does not run it. WebUtility is the quick tool;
	#    HtmlEncoder (System.Text.Encodings.Web) is the stricter one used by ASP.NET.
	? "1. text    : " + cText
	? "   WebUtility.HtmlEncode : " + new WebUtility().HtmlEncode(cText)
	? "   HtmlEncoder           : " + new HtmlEncoder().Default.Encode(cText)
	? "   and back (HtmlDecode) : " + new WebUtility().HtmlDecode("&lt;b&gt; &amp; &quot;q&quot; &#233;")

	# 2. A page made with and without encoding: the first one lets the visitor run a script
	cName = "Ann<img src=x onerror=alert(1)>"
	? nl + "2. unsafe page: <h1>Hello " + cName + "</h1>"
	? "   safe page  : <h1>Hello " + new WebUtility().HtmlEncode(cName) + "</h1>"

	# 3. URL: spaces, &, =, / and non-ASCII letters become %XX. Encode each VALUE of a query string, never the whole address.
	? nl + "3. a query value: q=" + new UrlEncoder().Default.Encode("rock & roll/é")

	# 4. JavaScript: a text inside a script string: quotes and < become \uXXXX, so "</script>" can not end the script early
	? nl + "4. JavaScript string: '" + new JavaScriptEncoder().Default.Encode('say "hi" <b>') + "'"

	# 5. JSON: quotes, new lines and tabs get a backslash. JsonEncodedText does it; better, let a JSON class write the whole document.
	cJsonText = 'line one' + nl + 'tab' + char(9) + 'a "quote"'
	? nl + "5. JSON string: " + new JsonEncodedText().Encode(cJsonText).ToString()

	# 6. XML: XElement escapes for you. Never build XML by adding strings.
	oNote = new XElement("note",cText)
	? nl + "6. XML element: " + oNote.ToString()

	# 7. Regular expressions: characters like + . * ( ) have a meaning. Regex.Escape makes a text that matches ITSELF.
	cLiteral = "1+1=2 (a.b)*"
	cPattern = new Regex("x").Escape(cLiteral)
	? nl + "7. the pattern for the literal text: " + cPattern + "; it matches the text: " + yesNo(new Regex(cPattern).IsMatch("so 1+1=2 (a.b)* is true"))

	# 8. SQL: NEVER join user text into a SQL statement. A parameter is sent separately from the SQL, so it can never become SQL.
	aSchema = [["People",[["Id","int",1],["Name","string",0]]]]
	oDb = new RingDatabase("Data Source=:memory:",aSchema)
	oDb.insert("People",[["Name","Ann"]])
	oDb.insert("People",[["Name","Bob"]])
	cAttack = "x' OR '1'='1"
	aWithParameter = oDb.where("People","Name = {0}",[cAttack])
	? nl + "8. the attack text '" + cAttack + "' as a parameter finds " + len(aWithParameter) + " rows (it is only a name that nobody has)"
	? "   the same text joined into the SQL would be: SELECT ... WHERE Name = '" + cAttack + "'  -> every row"
	oDb.close()

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
