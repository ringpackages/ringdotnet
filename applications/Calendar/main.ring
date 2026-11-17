# Calendar with date facts - MonthCalendar and the .NET date classes (a port of ring/applications/calendar)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System"
	"System.Globalization"
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Calendar",470,260)
oForm.FormBorderStyle = "FixedDialog"
oForm.MaximizeBox = 0
oCalendar = new MonthCalendar()
oCalendar.Location = new Point(10,10)
oCalendar.MaxSelectionCount = 1
oCalendar.setDateChangedEvent("showFacts()")
oForm.Controls.Add(oCalendar)
oFacts = uiLabel(oForm,"",250,12,210,230)
oFacts.Font = uiFont("Segoe UI",10,false)
showFacts()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func factsOf oDate
	oCulture = new CultureInfo("en-US")
	nYear = oDate.Year
	oEndOfYear = new DateTime(nYear,12,31)
	cText = oDate.ToString_2("dddd, MMMM d, yyyy",oCulture) + nl + nl
	cText += "Day of the year: " + oDate.DayOfYear + nl
	cText += "ISO week: " + new ISOWeek().GetWeekOfYear(oDate) + nl
	cText += "Days left in the year: " + floor(oEndOfYear.Subtract(oDate).TotalDays) + nl
	if dnStatic("System.DateTime","IsLeapYear",[nYear])
		cText += "Leap year: yes" + nl
	else
		cText += "Leap year: no" + nl
	ok
	cText += "Days in the month: " + dnStatic("System.DateTime","DaysInMonth",[nYear,oDate.Month]) + nl
	cText += "Quarter: " + (floor((oDate.Month - 1) / 3) + 1)
	return cText

func showFacts
	oFacts.Text = factsOf(oCalendar.SelectionStart)

func selfTest
	oCalendar.SetDate(new DateTime(2024,2,29))
	dnAssert("selected year",oCalendar.SelectionStart.Year,2024)
	dnAssert("event updated the facts",substr(oFacts.Text,"Thursday, February 29, 2024") > 0,1)
	dnAssert("day of year",substr(oFacts.Text,"Day of the year: 60") > 0,1)
	dnAssert("leap year",substr(oFacts.Text,"Leap year: yes") > 0,1)
	dnAssert("days in month",substr(oFacts.Text,"Days in the month: 29") > 0,1)
	dnAssert("days left",substr(oFacts.Text,"Days left in the year: 306") > 0,1)
	oCalendar.SetDate(new DateTime(2023,7,4))
	dnAssert("not a leap year",substr(oFacts.Text,"Leap year: no") > 0,1)
	dnAssert("quarter 3",substr(oFacts.Text,"Quarter: 3") > 0,1)
	dnAssert("weekday",substr(oFacts.Text,"Tuesday") > 0,1)
