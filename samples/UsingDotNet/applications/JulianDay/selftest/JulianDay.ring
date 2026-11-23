# the checks of JulianDay.ring: run with  ring JulianDay.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	dnAssert("Julian day of 2000-01-01",julianDay(2000,1,1),2451545)
	dnAssert("Julian day of 1970-01-01",julianDay(1970,1,1),2440588)
	aDate = calendarDate(2451545)
	dnAssert("back to the date",aDate[1] * 10000 + aDate[2] * 100 + aDate[3],20000101)
	dnAssert("leap day",calendarDate(julianDay(2024,2,29))[3],29)
	oDate = new DateTime(2024,12,25)
	oPicker.Value = oDate
	dnAssert("picker converts the date",oJulian.Text,"2460670")
	dnAssert("weekday shown",left(oInfo.Text,9),"Wednesday")
	oJulian.Text = "2451545"
	fromJulian()
	dnAssert("julian to the picker",oPicker.Value.Year,2000)
	dnAssert("the picker event updated the text",oJulian.Text,"2451545")
