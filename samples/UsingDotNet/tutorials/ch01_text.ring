# working with text - Ring text functions, String helpers, StringBuilder, regular expressions, encodings
load "dotnet.ring"

using {
	"System"
	"System.Text"
	"System.Text.RegularExpressions"
	"System.Globalization"
}

func main

	# Ring already has many text functions: use them for the basics
	cSentence = "  The quick brown fox  "
	? "Ring trim/upper : [" + upper(trim(cSentence)) + "]"
	aWords = str2list(substr(trim(cSentence)," ",nl))
	? "Ring words      : " + len(aWords)

	# .NET adds more helpers. String's static methods:
	oString = new String()
	? "Join            : " + oString.Join([ :separator = "-", :value = aWords ])
	? "Format          : " + oString.Format([ :format = "{0} has {1} items", :arg0 = "The list", :arg1 = 3 ])
	? "Empty or blank? : " + oString.IsNullOrWhiteSpace("   ")
	? "Compare (a < b) : " + oString.Compare([ :strA = "apple", :strB = "banana" ])

	# Title case needs the culture of the user
	oText = new CultureInfo("en-US").TextInfo
	? "Title case      : " + oText.ToTitleCase("ring meets dot net")

	# Building a long text efficiently: StringBuilder
	oBuilder = new StringBuilder("")
	for nLine = 1 to 3
		oBuilder.Append("line " + nLine)
		oBuilder.AppendLine(NULL)
	next
	? "StringBuilder   : " + len(oBuilder.ToString()) + " characters"

	# Numbers in other bases, and Base64
	? "255 in hex      : " + new Convert().Format([ :value = 255, :toBase = 16 ])
	? "Base64          : " + new Convert().ToBase64String("Ring")

	# Regular expressions: patterns for text
	oEmail = new Regex("[a-z]+@[a-z]+\.com")
	cMail = "write to ann@example.com or bob@test.com today"
	oMatches = oEmail.Matches(cMail)
	? "E-mails found   : " + oMatches.Count
	for nIndex = 0 to oMatches.Count - 1
		? "  " + oMatches.Item(nIndex).Value
	next
	? "Replaced        : " + oEmail.Replace([ :input = cMail, :replacement = "<hidden>" ])
	? "Is it a number? : " + new Regex("^[0-9]+$").IsMatch("12345") + " " + new Regex("^[0-9]+$").IsMatch("12x45")

	# Encodings: text <-> bytes
	oUtf8 = new Encoding().UTF8
	? "UTF-8 bytes     : " + len(oUtf8.GetBytes("Ring")) + " for Ring, " + len(oUtf8.GetBytes("Ring é")) + " with an accent"
