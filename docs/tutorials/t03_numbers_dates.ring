# Tutorial 3: numbers, parsing, dates and times
load "dotnetlib.ring"
using {
	"System"
	"System.Numerics"
	"System.Globalization"
}

func main
	oMath = new Math()

	# Math: functions on numbers
	? "Round to 2 digits : " + oMath.Round([ :value = 3.14159, :digits = 2 ])
	? "Square root of 144: " + oMath.Sqrt(144)
	? "Power 2^10        : " + oMath.Pow(2,10)
	? "Absolute, floor   : " + oMath.Abs(-7.5) + ", " + oMath.Floor(7.9)
	? "Min and Max       : " + oMath.Min(4,9) + ", " + oMath.Max(4,9)

	# Converting text to numbers: TryParse never fails, it tells you whether it worked
	aResult = new Int32().TryParse("123")
	? "TryParse '123'    : worked=" + aResult[1] + " value=" + aResult[2]
	aResult = new Int32().TryParse("12x")
	? "TryParse '12x'    : worked=" + aResult[1]

	# Very big numbers: BigInteger has no limit
	oBig = new BigInteger()
	nFactorial = oBig.Parse("1")
	for nNumber = 2 to 30
		nFactorial = oBig.Multiply(nFactorial,nNumber)
	next
	? "30!               : " + nFactorial.ToString()

	# Random numbers
	oRandom = new Random(42)
	? "Random 1..6       : " + oRandom.Next_([ :minValue = 1, :maxValue = 7 ]) + " (the same every run: the seed is 42)"

	# Dates: DateTime is a struct with year, month, day, hour...
	oDate = dnNew("DateTime",[ :year = 2024, :month = 12, :day = 25, :hour = 18, :minute = 30, :second = 0 ])
	? "A date            : " + oDate.ToString_1("dddd, dd MMMM yyyy HH:mm")
	? "Year, month, day  : " + oDate.Year + ", " + oDate.Month + ", " + oDate.Day
	? "Day of the week   : " + oDate.DayOfWeek

	# Dates are immutable: methods return a new date
	oLater = oDate.AddDays(10).AddHours(-3)
	? "10 days later     : " + oLater.ToString_1("yyyy-MM-dd HH:mm")

	# TimeSpan: the difference between two dates
	oSpan = new DateTime(2025,1,1).Subtract(oDate)
	? "Until new year    : " + oSpan.Days + " days and " + oSpan.Hours + " hours"
	? "In total hours    : " + oSpan.TotalHours

	# Parsing dates from text
	oParsed = new DateTime(2000,1,1).Parse("2024-07-04")
	? "Parsed            : " + oParsed.ToString_1("d MMMM yyyy")

	# Cultures format the same date differently
	? "US style          : " + oDate.ToString_2("D",new CultureInfo("en-US"))
	? "German style      : " + oDate.ToString_2("D",new CultureInfo("de-DE"))
