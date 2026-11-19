# Tutorial 103: dates and times - DateOnly, TimeOnly, DateTimeOffset, TimeSpan and calculations that do not break
load "dotnet.ring"
using {
	"System"
	"System.Globalization"
}

func main
	# 1. DateTime mixes a date and a time. When you only need ONE of them, DateOnly and TimeOnly say it in the type: a birthday has no
	#    time, an opening hour has no date.
	oDate = makeDate(2024,2,28)
	? "1. a date:  " + oDate.Format("yyyy-MM-dd") + ", " + oDate.DayOfWeek + ", day " + oDate.DayOfYear + " of the year"
	oNextDay = oDate.AddDays(2)
	? "   2 days later: " + oNextDay.Format("yyyy-MM-dd") + "   (2024 is a leap year: February has 29 days)"
	oTime = dnNew("TimeOnly",[ :hour = 22, :minute = 30, :second = 0 ])
	? "   a time: " + oTime.Format("HH:mm") + ", 3 hours later: " + oTime.AddHours(3).Format("HH:mm") + "   (it goes round the clock: no date to move to)"

	# 2. TimeSpan: the length of time between two moments. Subtracting two dates gives one.
	oStart = makeDateTime(2024,3,1,8,0)
	oEnd = makeDateTime(2024,3,3,17,30)
	oSpan = oEnd.Subtract(oStart)
	? nl + "2. from the start to the end: " + oSpan.Days + " days, " + oSpan.Hours + " hours, " + oSpan.Minutes + " minutes"
	? "   in total: " + oSpan.TotalHours + " hours, " + oSpan.TotalMinutes + " minutes"
	oHour = dnStatic("System.TimeSpan","FromMinutes",[135])
	? "   135 minutes is " + oHour.ToString() + " (hours:minutes:seconds)"

	# 3. DateTimeOffset: a moment WITH its distance from UTC. Two offsets, one moment: they are equal, and UtcDateTime shows it.
	oCairo = dnNew("DateTimeOffset",[ :year = 2024, :month = 6, :day = 15, :hour = 12, :minute = 0, :second = 0, :offset = dnStatic("System.TimeSpan","FromHours",[3]) ])
	oLondon = dnNew("DateTimeOffset",[ :year = 2024, :month = 6, :day = 15, :hour = 10, :minute = 0, :second = 0, :offset = dnStatic("System.TimeSpan","FromHours",[1]) ])
	? nl + "3. Cairo  " + oCairo.Format("yyyy-MM-dd HH:mm zzz")
	? "   London " + oLondon.Format("yyyy-MM-dd HH:mm zzz")
	? "   they are the same moment: " + oCairo.Equals(oLondon) + ", in UTC: " + oCairo.UtcDateTime.Format("HH:mm")

	# 4. Adding months: the end of the month does not exist in every month, so .NET moves to the last day that does
	oJan31 = new DateTime(2024,1,31)
	? nl + "4. 31 January + 1 month: " + oJan31.AddMonths(1).Format("yyyy-MM-dd") + "   (29 February)"
	? "   31 March + 1 month:   " + new DateTime(2024,3,31).AddMonths(1).Format("yyyy-MM-dd") + "   (30 April)"
	? "   29 February 2024 + 1 year: " + new DateTime(2024,2,29).AddYears(1).Format("yyyy-MM-dd")

	# 5. Counting: how many days to a date, and the age of a person on a day
	oBirthday = makeDate(1990,8,15)
	oToday = makeDate(2024,6,15)
	nAge = oToday.Year - oBirthday.Year
	oThisYear = makeDate(oToday.Year,oBirthday.Month,oBirthday.Day)
	if oThisYear.CompareTo(oToday) > 0       # the birthday of this year has not come yet
		nAge--
	ok
	? nl + "5. born 1990-08-15, on 2024-06-15 the age is " + nAge
	? "   days between the two dates: " + (oToday.DayNumber - oBirthday.DayNumber)

	# 6. Parsing a date from text with an exact format, so that 03/04/2024 can not be read as the wrong day and month
	aParsed = dnStatic("System.DateOnly","TryParseExact",["03/04/2024","dd/MM/yyyy",new CultureInfo(""),"None"])
	? nl + "6. '03/04/2024' read as day/month/year: " + aParsed[2].Format("yyyy-MM-dd") + " (the 3rd of April)"
	aParsed = dnStatic("System.DateOnly","TryParseExact",["31/04/2024","dd/MM/yyyy",new CultureInfo(""),"None"])
	? "   '31/04/2024' is a date: " + aParsed[1] + "   (April has 30 days)"

func makeDate nYear,nMonth,nDay
	return dnNew("DateOnly",[ :year = nYear, :month = nMonth, :day = nDay ])

func makeDateTime nYear,nMonth,nDay,nHour,nMinute
	return dnNew("DateTime",[ :year = nYear, :month = nMonth, :day = nDay, :hour = nHour, :minute = nMinute, :second = 0 ])
