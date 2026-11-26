# regular expressions in depth - patterns, groups, replace, split, validation
load "dotnet.ring"

using {
	"System"
	"System.Text.RegularExpressions"
}

func main

	cText = "Ann: 555-0101, Bob: 555-0199, Cy: 555-0123 (call after 18:30 on 2024-05-17)"

	# 1. Literal text matches itself
	? "1. 'Bob' found?            : " + new Regex("Bob").IsMatch(cText)

	# 2. Character classes: \d a digit, \w a letter/digit/underscore, \s a space, [abc] one of these, . any character
	? "2. First number            : " + new Regex("\d+").Match(cText).Value

	# 3. Quantifiers: + one or more, * zero or more, ? zero or one, {3} exactly three, {2,4} two to four
	oPhone = new Regex("\d{3}-\d{4}")
	oMatches = oPhone.Matches(cText)
	? "3. Phone numbers           : " + oMatches.Count + ", the first is " + oMatches.Item(0).Value

	# 4. Anchors: ^ start, $ end, \b the edge of a word
	? "4. Starts with 'Ann'?      : " + new Regex("^Ann").IsMatch(cText) + ", ends with ')'? " + new Regex("\)$").IsMatch(cText)

	# 5. Groups: parentheses capture parts. Named groups: (?<name>...)
	oDate = new Regex("(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})").Match(cText)
	? "5. Date parts              : year " + oDate.Groups.Item("year").Value + ", month " + oDate.Groups.Item("month").Value + ", day " + oDate.Groups.Item("day").Value

	# 6. Alternation: | means "or"
	oNames = new Regex("Ann|Cy").Matches(cText)
	? "6. Ann or Cy found         : " + oNames.Count + " times"

	# 7. Replace, also with the captured groups ($1, $2...) - here the date is turned around
	? "7. Date turned around      : " + new Regex("(\d{4})-(\d{2})-(\d{2})").Replace([ :input = cText, :replacement = "$3/$2/$1" ])

	# 8. Split on a pattern: here on a comma and spaces
	aParts = new Regex(",\s*").Split("one,two,   three,four").toList()
	? "8. Split into              : " + len(aParts) + " parts, the third is '" + aParts[3] + "'"

	# 9. Greedy and lazy: .* takes as much as it can, .*? as little
	cHtml = "<b>bold</b> and <i>italic</i>"
	? "9. Greedy                  : " + new Regex("<.*>").Match(cHtml).Value
	? "   Lazy                    : " + new Regex("<.*?>").Match(cHtml).Value

	# 10. Options: ignore the case of the letters
	? "10. 'BOB' ignoring case    : " + (new Regex).@New([ :pattern = "BOB", :options = "IgnoreCase" ]).IsMatch(cText)

	# 11. Validation: the whole text must match. ^ and $ make it all or nothing
	? nl + "11. Is it a valid time (HH:MM)?"
	for cTry in ["18:30","7:5","23:59","24:00"]
		? "    " + cTry + " -> " + new Regex("^([01]\d|2[0-3]):[0-5]\d$").IsMatch(cTry)
	next

	# 12. Special characters in your own text must be escaped
	cUser = "a.b*c"
	? nl + "12. Escaped text          : " + new Regex("x").Escape(cUser)
	? "    Matches itself           : " + new Regex(new Regex("x").Escape(cUser)).IsMatch("xx a.b*c yy")
