# Calendar with date facts - MonthCalendar and the .NET date classes (a port of ring/applications/calendar)

load "dotnet.ring"

using {
	"System"
	"System.Globalization"
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Calendar",470,260)
oForm {
	FormBorderStyle = "FixedDialog"
	MaximizeBox = False
}
oCalendar = new MonthCalendar() {
	Location = new Point(10,10)
	MaxSelectionCount = 1
	setDateChangedEvent("showFacts()")
}
oForm.Controls.Add(oCalendar)
oFacts = uiLabel(oForm,"",250,12,210,230)
oFacts.Font = uiFont("Segoe UI",10,false)
showFacts()

uiRun(oForm)

# --------------------------------------------------------------------------

func factsOf oDate

	oCulture = new CultureInfo("en-US")
	nYear = oDate.Year
	oEndOfYear = new DateTime(nYear,12,31)
	cText = oDate.Format([ :format = "dddd, MMMM d, yyyy", :provider = oCulture ]) + nl + nl
	cText += "Day of the year: " + oDate.DayOfYear + nl
	cText += "ISO week: " + new ISOWeek().GetWeekOfYear(oDate) + nl
	cText += "Days left in the year: " + floor(oEndOfYear.Subtract(oDate).TotalDays) + nl
	if new DateTime(2000,1,1).IsLeapYear(nYear)
		cText += "Leap year: yes" + nl
	else
		cText += "Leap year: no" + nl
	ok
	cText += "Days in the month: " + new DateTime(2000,1,1).DaysInMonth(nYear,oDate.Month) + nl
	cText += "Quarter: " + (floor((oDate.Month - 1) / 3) + 1)
	return cText

func showFacts

	oFacts.Text = factsOf(oCalendar.SelectionStart)
