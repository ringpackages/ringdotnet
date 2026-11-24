# a project: mail merge - a template with {fields}, rows of data, Regex.Replace with a callback, formats, missing fields and the letters
load "dotnet.ring"

using {
	"System"
	"System.Globalization"
	"System.Text.RegularExpressions"
}

aFields = []                     # the data of the row that is being merged (the callback reads it)
aMissing = []                    # the names of the fields that a row did not have

func main

	# A MAIL MERGE makes many letters from one template and a table of data. The template has FIELDS in braces: {name} is replaced by the
	# value of the column name, and {amount:N2} is replaced by the value written with a format (the tutorial about formatting).
	cTemplate = "Dear {name}," + nl + "Your order {order} of {amount:N2} is ready." + nl + "It will be sent to {city} on {date:d MMMM yyyy}." + nl + "Thank you, {shop}"

	# The data is a CSV text: the first line has the names of the columns, and each other line is one letter. (A real program reads a file;
	# this text is the same as the content of such a file.)
	cCsv = "name,order,amount,city,date" + nl + "Ann,A-101,1234.5,Cairo,2030-03-09" + nl + "Bob,A-102,80,Oslo,2030-03-10" + nl + "Cy,A-103,19.99,,2030-03-11"
	aRows = readCsv(cCsv)

	? "1. the template has these fields: " + joinList(fieldNames(cTemplate))
	? "   the data has " + len(aRows) + " rows and the columns: " + joinList(columnNames(cCsv))

	# 2. One letter: Regex.Replace finds each {field} and asks a function (a CALLBACK) for the text that replaces it
	? nl + "2. the first letter:"
	? indent(merge(cTemplate,aRows[1]))

	# 3. All the letters
	? nl + "3. all the letters, the first line of each:"
	for i = 1 to len(aRows)
		cLetter = merge(cTemplate,aRows[i])
		? "   " + i + ". " + first(cLetter)
	next

	# 4. Missing data. The third row has no city, and the template has {shop}, which is not a column. A letter with a hole must not be
	#    sent, so the program collects the problems and reports them before any letter is written.
	? nl + "4. check before sending:"
	for i = 1 to len(aRows)
		aMissing = []
		merge(cTemplate,aRows[i])
		if len(aMissing) > 0
			? "   row " + i + " (" + aRows[i][:name] + "): missing " + joinList(aMissing)
		ok
	next

	# 5. Add the column shop to every row and give Cy a city: now every letter is complete
	aRows[3][:city] = "Giza"
	? nl + "5. after the repair:"
	nProblems = 0
	for i = 1 to len(aRows)
		aRows[i] + [ "shop","The Tea House" ]                # a new column: a new pair
		aMissing = []
		merge(cTemplate,aRows[i])
		nProblems += len(aMissing)
	next
	? "   problems: " + nProblems
	? indent(merge(cTemplate,aRows[3]))

# the names of the fields in a template: the first part of each {name} or {name:format}
func fieldNames cTemplate

	aNames = []
	aMatches = dnStatic("System.Text.RegularExpressions.Regex","Matches",[ cTemplate, cPattern() ]).toList()
	for oMatch in aMatches
		aNames + oMatch.Groups.Item(1).Value
	next
	return aNames

# the pattern of a field: { a name, and then perhaps a colon and a format } . The name is in group 1 and the format in group 2.
func cPattern

	return "\{(\w+)(?::([^}]+))?\}"

# the letter of one row: every field is replaced by what the callback returns
func merge cTemplate,aRow

	aFields = aRow
	return dnStatic("System.Text.RegularExpressions.Regex","Replace",[ cTemplate, cPattern(), dnCallback("replaceField") ])

# The callback. A callback that is the NAME of a function gets the arguments as a list: aArgs[1] is the Match. Group 1 is the name of the
# field and group 2 the format (empty when there is none). The text that the function RETURNS replaces the field in the letter.
func replaceField aArgs

	oMatch = aArgs[1]
	cName = oMatch.Groups.Item(1).Value
	cFormat = oMatch.Groups.Item(2).Value
	if find(aFields,cName,1) = 0 or trim(aFields[cName]) = ""
		aMissing + cName
		return "[" + cName + "?]"                           # a visible mark in the letter
	ok
	cValue = aFields[cName]
	if cFormat != ""
		return formatValue(cValue,cFormat)
	ok
	return cValue

# a value with a format: a number with N2, a date with d MMMM yyyy (the invariant culture: the same text on every computer)
func formatValue cValue,cFormat

	oInvariant = new CultureInfo("en-US").InvariantCulture
	if isDate(cValue)
		oDate = dnStatic("System.DateTime","Parse",[ cValue, oInvariant ])
		return oDate.Format([ :format = cFormat, :provider = oInvariant ])
	ok
	return new String().Format([ :provider = oInvariant, :format = "{0:" + cFormat + "}", :arg0 = 0 + cValue ])

func isDate cText

	return len(cText) = 10 and substr(cText,5,1) = "-" and substr(cText,8,1) = "-"

# a CSV text as a list of rows; each row is a list of [name, value] pairs, found by the name of the column
func readCsv cCsv

	aLines = str2list(substr(cCsv,char(13),""))
	aNames = splitKeep(aLines[1])
	aRows = []
	for i = 2 to len(aLines)
		if trim(aLines[i]) = ""
			loop
		ok
		aValues = splitKeep(aLines[i])
		aRow = []
		for j = 1 to len(aNames)
			aRow + [ aNames[j], aValues[j] ]
		next
		aRows + aRow
	next
	return aRows

# split a line at the commas and keep the empty values
func splitKeep cLine

	aParts = []
	cPart = ""
	for i = 1 to len(cLine)
		if substr(cLine,i,1) = ","
			aParts + cPart
			cPart = ""
		else
			cPart += substr(cLine,i,1)
		ok
	next
	aParts + cPart
	return aParts

func columnNames cCsv

	return splitKeep(str2list(substr(cCsv,char(13),""))[1])

func first cLetter

	return str2list(cLetter)[1]

func indent cText

	cOut = ""
	aTextLines = str2list(cText)
	for cLine in aTextLines
		cOut += "   | " + cLine + nl
	next
	return left(cOut,len(cOut) - 1)

func joinList aList

	cText = ""
	for item in aList
		if cText != ""
			cText += ", "
		ok
		cText += "" + item
	next
	return cText
