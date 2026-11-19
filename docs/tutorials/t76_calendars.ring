# other calendars - Hijri (Umm al-Qura), Persian, Hebrew, Japanese and Thai Buddhist dates with System.Globalization
load "dotnet.ring"
using {
	"System"
	"System.Globalization"
}

func main
	oDate = new DateTime(2024,3,11)                   # a DateTime always holds a Gregorian date; a Calendar object reads it in its own way

	# 1. The same day in several calendars. Each calendar class has GetYear, GetMonth and GetDayOfMonth.
	? "1. the day 2024-03-11 in:"
	? "   Gregorian         : " + dateText(new GregorianCalendar(),oDate)
	? "   Hijri (Umm al-Qura): " + dateText(new UmAlQuraCalendar(),oDate)
	? "   Persian           : " + dateText(new PersianCalendar(),oDate)
	? "   Hebrew            : " + dateText(new HebrewCalendar(),oDate)
	? "   Thai Buddhist     : " + dateText(new ThaiBuddhistCalendar(),oDate)
	? "   Japanese (era year): " + new JapaneseCalendar().GetYear(oDate)

	# 2. From a Hijri date to a Gregorian date: ToDateTime. The first day of Ramadan 1445.
	oHijri = new UmAlQuraCalendar()
	oRamadan = oHijri.ToDateTime([ :year = 1445, :month = 9, :day = 1, :hour = 0, :minute = 0, :second = 0, :millisecond = 0 ])
	? nl + "2. 1 Ramadan 1445 is " + oRamadan.Format("yyyy-MM-dd") + ", a " + oRamadan.DayOfWeek

	# 3. Month lengths: a Hijri month has 29 or 30 days (Umm al-Qura follows tables of the moon)
	? nl + "3. the months of 1445:"
	for nMonth = 1 to 12
		? "   month " + padLeft("" + nMonth,2) + ": " + oHijri.GetDaysInMonth([ :year = 1445, :month = nMonth ]) + " days, starts " + oHijri.ToDateTime([ :year = 1445, :month = nMonth, :day = 1, :hour = 0, :minute = 0, :second = 0, :millisecond = 0 ]).Format("yyyy-MM-dd")
	next

	# 4. Month and day names in the language and the calendar of a culture. ar-SA uses Arabic names and the Hijri calendar.
	oArabic = new CultureInfo("ar-SA")
	oEnglish = new CultureInfo("en-US")
	? nl + "4. in ar-SA the culture's own calendar is " + oArabic.Calendar.GetType().Name
	? "   " + oDate.Format([ :format = "dddd, d MMMM yyyy", :provider = oArabic ])
	? "   " + oDate.Format([ :format = "dddd, d MMMM yyyy", :provider = oEnglish ])

	# 5. How long is a year? The Hijri year is 354 or 355 days, about 11 days shorter than the Gregorian year, so Ramadan moves back
	? nl + "5. the first day of Ramadan, year after year:"
	for nYear = 1445 to 1449
		oStart = oHijri.ToDateTime([ :year = nYear, :month = 9, :day = 1, :hour = 0, :minute = 0, :second = 0, :millisecond = 0 ])
		? "   " + nYear + ": " + oStart.Format("yyyy-MM-dd")
	next

	# 6. Leap years of the Gregorian calendar
	oGregorian = new GregorianCalendar()
	? nl + "6. 2024 is a leap year: " + yesNo(oGregorian.IsLeapYear(2024)) + ", 2100: " + yesNo(oGregorian.IsLeapYear(2100)) + ", 2000: " + yesNo(oGregorian.IsLeapYear(2000))

# "1445-9-1" for a date, read in the calendar oCalendar
func dateText oCalendar, oDate
	return string(oCalendar.GetYear(oDate)) + "-" + oCalendar.GetMonth(oDate) + "-" + oCalendar.GetDayOfMonth(oDate)

func padLeft cText, nWidth
	while len(cText) < nWidth
		cText = " " + cText
	end
	return cText

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
