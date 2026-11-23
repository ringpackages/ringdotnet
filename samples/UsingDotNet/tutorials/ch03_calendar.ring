# calendars - month tables, ages, business days and birthdays with DateTime
load "dotnet.ring"

using {
	"System"
}

func main

	# 1. A text calendar of a month: how many days it has, and on which weekday the 1st falls
	? monthCalendar(2024,2)

	# 2. How old is somebody? Years, months and days between two dates
	? "Age of a person born on 1990-03-15, on 2024-03-14: " + ageText(1990,3,15,2024,3,14)
	? "   and on 2024-03-15                                  : " + ageText(1990,3,15,2024,3,15)

	# 3. Days between dates, and business days (Monday to Friday)
	oFrom = new DateTime(2024,12,20)
	oTo = new DateTime(2025,1,6)
	? nl + "From 2024-12-20 to 2025-01-06: " + oTo.Subtract(oFrom).Days + " days, " + businessDays(oFrom,oTo) + " business days"

	# 4. The next birthday: this year's date, or next year's when it has passed
	? nl + "Days until the next birthday (3 March), counted from 2024-05-10: " + daysUntilBirthday(3,3,2024,5,10)
	? "   counted from 2024-02-01: " + daysUntilBirthday(3,3,2024,2,1)

	# 5. Adding to a date: months of different length, and the end of the month
	oStart = new DateTime(2024,1,31)
	? nl + "2024-01-31 plus one month : " + oStart.AddMonths(1).Format("yyyy-MM-dd") + " (February has no 31st: the last day is used)"
	? "   plus one year (leap day)  : " + new DateTime(2024,2,29).AddYears(1).Format("yyyy-MM-dd")
	? "   plus 100 days             : " + oStart.AddDays(100).Format("yyyy-MM-dd")

	# 6. The week number and the day of the year
	oDate = new DateTime(2024,12,25)
	? nl + "2024-12-25 is day " + oDate.DayOfYear + " of the year, a " + oDate.DayOfWeek

# A month as text: a title, the weekday names, then the days in rows of seven (the week starts on Monday)
func monthCalendar nYear, nMonth

	oFirst = new DateTime(nYear,nMonth,1)
	nDays = new DateTime(nYear,nMonth,1).DaysInMonth(nYear,nMonth)
	cText = "" + oFirst.Format("MMMM yyyy") + " (" + nDays + " days)" + nl
	cText += "   Mo Tu We Th Fr Sa Su" + nl + "   "
	# the column of the first day: Monday = 0 ... Sunday = 6
	aWeekdays = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
	nColumn = find(aWeekdays,oFirst.DayOfWeek) - 1
	cText += copies("   ",nColumn)
	for nDay = 1 to nDays
		cText += right("  " + nDay,2) + " "
		nColumn++
		if nColumn = 7 and nDay < nDays
			cText += nl + "   "
			nColumn = 0
		ok
	next
	return cText

func copies cText, nTimes

	cResult = ""
	for nIndex = 1 to nTimes
		cResult += cText
	next
	return cResult

# complete years, months and days between a birth date and a date
func ageText nBirthYear, nBirthMonth, nBirthDay, nYear, nMonth, nDay

	nYears = nYear - nBirthYear
	nMonths = nMonth - nBirthMonth
	nDays = nDay - nBirthDay
	if nDays < 0
		nMonths--
		# the days of the month before the date
		nDays += new DateTime(nYear,nMonth,1).AddMonths(-1).DaysInMonth(new DateTime(nYear,nMonth,1).AddMonths(-1).Year,new DateTime(nYear,nMonth,1).AddMonths(-1).Month)
	ok
	if nMonths < 0
		nYears--
		nMonths += 12
	ok
	return "" + nYears + " years, " + nMonths + " months, " + nDays + " days"

# the days from oFrom up to (not including) oTo that are not Saturday or Sunday
func businessDays oFrom, oTo

	nCount = 0
	oDay = oFrom
	while oDay.CompareTo(oTo) < 0
		cName = oDay.DayOfWeek
		if cName != "Saturday" and cName != "Sunday"
			nCount++
		ok
		oDay = oDay.AddDays(1)
	end
	return nCount

func daysUntilBirthday nMonth, nDay, nYear, nTodayMonth, nTodayDay

	oToday = new DateTime(nYear,nTodayMonth,nTodayDay)
	oBirthday = new DateTime(nYear,nMonth,nDay)
	if oBirthday.CompareTo(oToday) < 0
		oBirthday = oBirthday.AddYears(1)
	ok
	return oBirthday.Subtract(oToday).Days
