# working days - adding business days, skipping weekends and holidays, week numbers, quarters, month ends and an age
load "dotnet.ring"
using {
	"System"
	"System.Globalization"
}

# the holidays of this example (fixed dates written as year-month-day)
aHolidays = [ "2030-01-01", "2030-12-25", "2030-12-26" ]

func main
	# 1. The day of the week. DayOfWeek is a text: "Monday" ... "Sunday". Many countries have another weekend (Friday and Saturday), so the
	#    weekend is a list in one place.
	oDate = makeDate(2030,3,9)
	? "1. " + oDate.Format("yyyy-MM-dd") + " is a " + oDate.DayOfWeek + ", weekend: " + yesNo(isWeekend(oDate))
	? "   the days of the week of 11-17 March 2030:"
	cLine = ""
	for i = 11 to 17
		cLine += makeDate(2030,3,i).Format("ddd d") + "  "
	next
	? "   " + cLine

	# 2. Adding days is simple (AddDays), and adding WORKING days is a loop that skips the weekend and the holidays
	oStart = makeDate(2030,3,7)                         # a Thursday
	? nl + "2. from Thursday " + oStart.Format("yyyy-MM-dd") + ":"
	? "   + 1 calendar day:  " + oStart.AddDays(1).Format("ddd yyyy-MM-dd")
	for nDays in [ 1, 2, 5, 10 ]
		? "   + " + padRight("" + nDays,2) + " working days: " + addWorkdays(oStart,nDays).Format("ddd yyyy-MM-dd")
	next

	# 3. Holidays move the result. 2030-12-24 is a Tuesday; the 25th and 26th are holidays, and the 28th and 29th the weekend.
	oEve = makeDate(2030,12,24)
	? nl + "3. holidays: 3 working days after " + oEve.Format("yyyy-MM-dd") + " is " + addWorkdays(oEve,3).Format("ddd yyyy-MM-dd") + " (the 25th, 26th, 28th and 29th do not count)"

	# 4. Counting the working days between two dates (the first day is included, the last is not)
	? nl + "4. working days from 2030-03-01 to 2030-04-01: " + countWorkdays(makeDate(2030,3,1),makeDate(2030,4,1))
	? "   working days in the year 2030: " + countWorkdays(makeDate(2030,1,1),makeDate(2031,1,1))

	# 5. Week numbers. The ISO week starts on Monday, and week 1 is the week with the first Thursday of the year: so the first days of
	#    January can belong to the last week of the year before, and the last days of December to week 1 of the next year.
	? nl + "5. ISO weeks:"
	for aItem in [ [2030,1,1], [2030,3,9], [2030,12,30], [2027,1,1] ]
		oD = makeDate(aItem[1],aItem[2],aItem[3])
		? "   " + oD.Format("yyyy-MM-dd ddd") + "  week " + isoWeek(oD) + " of " + isoYear(oD)
	next

	# 6. Quarters and the end of a month. DaysInMonth knows the leap years.
	? nl + "6. quarters and month ends:"
	for nMonth = 1 to 12 step 4
		? "   month " + padRight("" + nMonth,3) + "quarter " + (floor((nMonth - 1) / 3) + 1) + ", the month has " + daysInMonth(2030,nMonth) + " days"
	next
	? "   February has " + daysInMonth(2030,2) + " days in 2030 and " + daysInMonth(2032,2) + " in 2032"
	? "   the last day of February 2032 is " + makeDate(2032,2,daysInMonth(2032,2)).Format("yyyy-MM-dd ddd")

	# 7. An age: the years between a birth date and a day, one less when the birthday of this year did not come yet
	? nl + "7. ages on 2030-03-09:"
	for aItem in [ [2000,3,9], [2000,3,10], [1990,12,31], [2030,3,9] ]
		? "   born " + padRight(makeDate(aItem[1],aItem[2],aItem[3]).Format("yyyy-MM-dd"),11) + "age " + ageOn(makeDate(aItem[1],aItem[2],aItem[3]),makeDate(2030,3,9))
	next

func makeDate nYear,nMonth,nDay
	return dnNew("DateTime",[ :year = nYear, :month = nMonth, :day = nDay ])

# the weekend in one place (Saturday and Sunday here; use ["Friday","Saturday"] for the countries with that weekend)
func isWeekend oDate
	cDay = "" + oDate.DayOfWeek
	return cDay = "Saturday" or cDay = "Sunday"

func isHoliday oDate
	return find(aHolidays,oDate.Format("yyyy-MM-dd")) > 0

func isWorkday oDate
	return not isWeekend(oDate) and not isHoliday(oDate)

# n working days after a date (the date itself does not count)
func addWorkdays oDate,nDays
	oCurrent = oDate
	nLeft = nDays
	while nLeft > 0
		oCurrent = oCurrent.AddDays(1)
		if isWorkday(oCurrent)
			nLeft--
		ok
	end
	return oCurrent

func countWorkdays oFrom,oTo
	nCount = 0
	oCurrent = oFrom
	while oCurrent.CompareTo(oTo) < 0
		if isWorkday(oCurrent)
			nCount++
		ok
		oCurrent = oCurrent.AddDays(1)
	end
	return nCount

func isoWeek oDate
	return dnStatic("System.Globalization.ISOWeek","GetWeekOfYear",[ oDate ])

func isoYear oDate
	return dnStatic("System.Globalization.ISOWeek","GetYear",[ oDate ])

func daysInMonth nYear,nMonth
	return dnStatic("System.DateTime","DaysInMonth",[ nYear, nMonth ])

# the years between two dates, minus one when the birthday of that year has not come yet
func ageOn oBirth,oDay
	nAge = oDay.Year - oBirth.Year
	if oDay.Month < oBirth.Month or (oDay.Month = oBirth.Month and oDay.Day < oBirth.Day)
		nAge--
	ok
	return nAge

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"

func padRight cText,nWidth
	return cText + copy(" ",nWidth - len(cText))
