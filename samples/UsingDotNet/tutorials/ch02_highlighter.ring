# a project: a syntax highlighter - one regular expression with named groups splits code into tokens, and each token becomes an HTML span
load "dotnet.ring"

using {
	"System"
	"System.Text.RegularExpressions"
}

func main

	# A highlighter reads code as TOKENS (comments, strings, numbers, words) and writes each kind in its own color. The idea is one
	# regular expression with an alternative for each kind of token: the first alternative that matches at a place wins. The order
	# matters: a comment must be tried before the words, so that a word inside a comment is not a keyword.
	cCode = "# count to three" + nl + 'for i = 1 to 3' + nl + '	? "Number " + i   # print it' + nl + "next" + nl + 'x = 3.14 * radius'

	# (the pattern is in single quotes because it has double quotes in it; the groups are: comment, string, number, word, any other character)
	cPattern = '(?<comment>#[^\n]*)|(?<string>"[^"\n]*")|(?<number>\b\d+(?:\.\d+)?\b)|(?<word>[A-Za-z_]\w*)|(?<other>[\s\S])'

	# 1. The tokens: Matches returns every match in order; the group that has Success is the kind of the token
	aTokens = tokens(cCode,cPattern)
	? "1. the tokens (each token with its kind), without the spaces:"
	for aToken in aTokens
		if not isBlank(aToken[2])
			? "   " + padRight(aToken[1],9) + "[" + aToken[2] + "]"
		ok
	next

	# 2. Words are names or KEYWORDS: a list of the keywords of the language decides
	aKeywords = [ "for","to","next","if","else","ok","func","return","while","end" ]
	? nl + "2. the keywords found: " + joinList(findKind(aTokens,"word",aKeywords))
	? "   the names found:    " + joinList(findNames(aTokens,aKeywords))

	# 3. The tokens as HTML. The text of each token is ESCAPED (< > &): code has these characters, and HTML would read them as tags.
	? nl + "3. the code as HTML:"
	cHtml = toHtml(aTokens,aKeywords)
	? cHtml

	# 4. The check of a highlighter: the text without the tags is exactly the code that went in. Nothing was lost or changed.
	? nl + "4. the text without the tags is the original code: " + yesNo(stripTags(cHtml) = htmlText(cCode))

	# 5. Code with the characters of HTML in it
	cTricky = 'if a < b and c > d  # a <b>tag</b> & more'
	? nl + "5. characters of HTML in code:"
	? "   " + toHtml(tokens(cTricky,cPattern),aKeywords)

	# 6. A # inside a string. The matching goes from left to right: the string alternative matches at the first quote, and the whole string
	#    (with the # in it) is one token, so the # is never looked at as the start of a comment. (What this pattern cannot do: a string that
	#    continues on the next line, or a quote inside a string; a real highlighter has more alternatives for such cases.)
	cInString = 'text = "not # a comment"'
	? nl + "6. a # inside a string:"
	? "   " + toHtml(tokens(cInString,cPattern),aKeywords)

# the tokens of a text: a list of [kind, text]
func tokens cCode,cPattern

	aList = []
	aKinds = [ "comment","string","number","word","other" ]
	aMatches = dnStatic("System.Text.RegularExpressions.Regex","Matches",[ cCode, cPattern ]).toList()
	for oMatch in aMatches
		for cKind in aKinds
			if oMatch.Groups.Item(cKind).Success
				aList + [ cKind, oMatch.Value ]
				exit
			ok
		next
	next
	return aList

# the words of a kind of list: the keywords that were used (each once)
func findKind aTokens,cKind,aKeywords

	aFound = []
	for aToken in aTokens
		if aToken[1] = "word" and find(aKeywords,aToken[2]) > 0 and find(aFound,aToken[2]) = 0
			aFound + aToken[2]
		ok
	next
	return aFound

func findNames aTokens,aKeywords

	aFound = []
	for aToken in aTokens
		if aToken[1] = "word" and find(aKeywords,aToken[2]) = 0 and find(aFound,aToken[2]) = 0
			aFound + aToken[2]
		ok
	next
	return aFound

# the HTML of a list of tokens: a span with a class for comments, strings, numbers and keywords; the rest is plain
func toHtml aTokens,aKeywords

	cHtml = ""
	for aToken in aTokens
		cKind = aToken[1]
		cText = htmlText(aToken[2])
		if cKind = "word"
			if find(aKeywords,aToken[2]) > 0
				cKind = "keyword"
			else
				cKind = "name"
			ok
		ok
		if cKind = "name" or cKind = "other"
			cHtml += cText
		else
			cHtml += '<span class="' + cKind + '">' + cText + "</span>"
		ok
	next
	return cHtml

# the three characters that HTML reads as markup. & first: otherwise the & of the other two would be changed again.
func htmlText cText

	cText = substr(cText,"&","&amp;")
	cText = substr(cText,"<","&lt;")
	return substr(cText,">","&gt;")

# the HTML without the tags (the spans that the program added): what is left must be the escaped code
func stripTags cHtml

	return dnStatic("System.Text.RegularExpressions.Regex","Replace",[ cHtml, '</?span[^>]*>', "" ])

# a token of spaces, tabs or line breaks only
func isBlank cText

	cText = substr(substr(substr(substr(cText," ",""),char(9),""),char(10),""),char(13),"")
	return cText = ""

func joinList aList

	cText = ""
	for item in aList
		if cText != ""
			cText += ", "
		ok
		cText += "" + item
	next
	return cText

func yesNo lValue

	if lValue
		return "yes"
	ok
	return "no"

func padRight cText,nWidth

	return cText + copy(" ",nWidth - len(cText))
