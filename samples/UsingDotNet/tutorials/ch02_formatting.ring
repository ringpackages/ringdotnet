# formatting numbers and dates - format strings: fixed decimals, thousands, percent, hexadecimal, padding, alignment and custom patterns
load "dotnet.ring"

using {
	"System"
	"System.Globalization"
}

oString = new String()
oInvariant = ""

func main

	# A format string says HOW a value is written. The invariant culture is used here, so that the output is the same on every computer;
	# a program for people uses the culture of the user (the tutorial about cultures).
	oInvariant = new CultureInfo("en-US").InvariantCulture

	# 1. Standard formats for numbers: one letter, and often a number of digits after it. They are written in a placeholder {0:...} of
	#    String.Format; {0} means the first value.
	? "1. standard numeric formats for 1234.5678:"
	for cFormat in [ "F0", "F2", "N0", "N2", "E3", "P1", "C", "G" ]
		? "   {0:" + padRight(cFormat + "}",6) + one("{0:" + cFormat + "}",1234.5678)
	next
	? "   F = fixed decimals, N = with thousands separators, E = scientific, P = percent (the value is multiplied by 100),"
	? "   C = money (the invariant culture has no money symbol and shows the sign of an unknown currency; a country culture shows its own),"
	? "   G = general (the shortest form)"
	? "   {0:P1} of 0.256 = " + one("{0:P1}",0.256)

	# 2. Whole numbers. The formats D (zeros in front) and X (hexadecimal) are made for whole-number TYPES: a whole number that goes to
	#    String.Format is an Int32, so they work. Convert.ToString(number, base) writes a whole number in base 2, 8, 10 or 16 as well.
	? nl + "2. whole numbers, 255:"
	? "   base 16: " + toBase(255,16) + ", base 2: " + toBase(255,2) + ", base 8: " + toBase(255,8)
	? "   zeros in front, {0:D6}:        " + one("{0:D6}",255)
	? "   hexadecimal, {0:X} and {0:x4}:  " + one("{0:X}",255) + " and " + one("{0:x4}",255)
	? "   thousands separators:          " + one("{0:N0}",1234567)

	# 3. Custom patterns: you draw the number. 0 = a digit (a zero if there is none), # = a digit (nothing if there is none),
	#    , = thousands, . = decimals, % = percent
	? nl + "3. custom patterns:"
	for aItem in [ ["0.00",3.14159,"3.14159"], ["000.0",3.14159,"3.14159"], ["#,##0.00",1234567.891,"1234567.891"], ["#.##",0.5,"0.5"], ["#.##",12,"12"], ["0.0%",0.256,"0.256"], ["0 'kg'",72,"72"] ]
		? "   " + padRight(aItem[1],10) + one("{0:" + aItem[1] + "}",aItem[2]) + "     (for " + aItem[3] + ")"
	next

	# 4. Alignment: {0,10} gives the value 10 places, to the right; {0,-10} to the left. Columns of a table.
	? nl + "4. a table with alignment (names to the left, numbers to the right):"
	aPrices = [ ["Tea",2.5], ["Coffee",13.25], ["Orange juice",104] ]
	for aItem in aPrices
		? "   " + oString.Format([ :provider = oInvariant, :format = "|{0,-14}|{1,9:F2}|", :arg0 = aItem[1], :arg1 = aItem[2] ])
	next

	# 5. Dates: the letters mean year (yyyy), month (MM), day (dd), hour (HH), minute (mm), second (ss), month name (MMMM, MMM) and the
	#    day of the week (dddd). A standard letter is a ready-made pattern: d short date, D long date, t short time, o round trip.
	oDate = new DateTime
	oDate.@New([ :year = 2030, :month = 3, :day = 9, :hour = 14, :minute = 5, :second = 7 ])
	? nl + "5. dates (2030-03-09 14:05:07):"
	for cPattern in [ "yyyy-MM-dd", "dd/MM/yyyy", "d MMMM yyyy", "dddd", "MMM d, yyyy", "HH:mm:ss", "h:mm tt", "yyyyMMdd_HHmmss", "d", "D", "t", "o" ]
		? "   " + padRight(cPattern,18) + oDate.Format([ :format = cPattern, :provider = oInvariant ])
	next

	# 6. Time spans have their own patterns: hours, minutes and seconds of a duration
	oSpan = new TimeSpan().FromSeconds(3725)
	? nl + "6. a duration of 3725 seconds:"
	? "   hh\:mm\:ss = " + oSpan.Format([ :format = "hh\:mm\:ss", :formatProvider = oInvariant ])
	? "   h 'h' m 'min' = " + oSpan.Format([ :format = "h' h 'm' min'", :formatProvider = oInvariant ])

	# 7. A pattern that does not fit the value raises an error, which is better than a wrong text: the letter Z is not a number format
	try
		? one("{0:Z}",12)
	catch
		? nl + "7. a wrong format: " + errorKind(cCatchError)
	done

# a whole number in another base (a static method of Convert)
func toBase nNumber,nBase

	oConvert = new Convert
	return oConvert.Format([ :value = nNumber, :toBase = nBase ])

# format one value with the invariant culture
func one cFormat,value

	return oString.Format([ :provider = oInvariant, :format = cFormat, :arg0 = value ])

func padRight cText,nWidth

	return "" + cText + copy(" ",nWidth - len("" + cText))

func errorKind cMessage

	cText = trim(cMessage)
	nStart = substr(cText,"DotNet Error: ")
	if nStart > 0
		cText = substr(cText,nStart + 14)
	ok
	nEnd = substr(cText,":")
	if nEnd > 0
		cText = left(cText,nEnd - 1)
	ok
	return cText
