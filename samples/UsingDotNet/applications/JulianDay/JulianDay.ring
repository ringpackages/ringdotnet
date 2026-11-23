# Julian day converter - dates and Julian day numbers in both directions (a port of ring/applications/juliandaycalendar)

load "dotnet.ring"
using {
	"System"
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Julian day",400,230)
oForm {
	FormBorderStyle = "FixedDialog"
	MaximizeBox = False
}
uiLabel(oForm,"Date",15,22,60,22)
oPicker = new DateTimePicker() {
	Location = new Point(85,19)
	Size = new Size(150,26)
	Format = "Short"
}
oForm.Controls.Add(oPicker)
uiLabel(oForm,"Julian day",15,72,70,22)
oJulian = uiTextBox(oForm,85,69,150,26)
uiButton(oForm,"To date",245,67,100,30,"fromJulian()")
oInfo = uiLabel(oForm,"",15,115,370,80)
oPicker.setValueChangedEvent("fromDate()")
fromDate()

uiRun(oForm)

# --------------------------------------------------------------------------

# Julian day number of a calendar date (at noon)
func julianDay nYear, nMonth, nDay
	nA = floor((14 - nMonth) / 12)
	nY = nYear + 4800 - nA
	nM = nMonth + 12 * nA - 3
	return nDay + floor((153 * nM + 2) / 5) + 365 * nY + floor(nY / 4) - floor(nY / 100) + floor(nY / 400) - 32045

# the calendar date of a Julian day number: [year, month, day]
func calendarDate nJulian
	nA = nJulian + 32044
	nB = floor((4 * nA + 3) / 146097)
	nC = nA - floor(146097 * nB / 4)
	nD = floor((4 * nC + 3) / 1461)
	nE = nC - floor(1461 * nD / 4)
	nM = floor((5 * nE + 2) / 153)
	nDay = nE - floor((153 * nM + 2) / 5) + 1
	nMonth = nM + 3 - 12 * floor(nM / 10)
	nYear = 100 * nB + nD - 4800 + floor(nM / 10)
	return [nYear,nMonth,nDay]

func fromDate
	oDate = oPicker.Value
	nJulian = julianDay(oDate.Year,oDate.Month,oDate.Day)
	oJulian.Text = "" + nJulian
	oInfo.Text = oDate.DayOfWeek + nl + "Modified Julian day: " + (nJulian - 2400001) + nl + "Day of the year: " + oDate.DayOfYear

func fromJulian
	nJulian = floor(number(oJulian.Text))
	aDate = calendarDate(nJulian)
	oDate = new DateTime(aDate[1],aDate[2],aDate[3])
	oPicker.Value = oDate
