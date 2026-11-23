# the checks of Calendar.ring: run with  ring Calendar.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oCalendar.SetDate(new DateTime(2024,2,29))
	dnAssert("selected year",oCalendar.SelectionStart.Year,2024)
	dnAssert("event updated the facts",substr(oFacts.Text,"Thursday, February 29, 2024") > 0,True)
	dnAssert("day of year",substr(oFacts.Text,"Day of the year: 60") > 0,True)
	dnAssert("leap year",substr(oFacts.Text,"Leap year: yes") > 0,True)
	dnAssert("days in month",substr(oFacts.Text,"Days in the month: 29") > 0,True)
	dnAssert("days left",substr(oFacts.Text,"Days left in the year: 306") > 0,True)
	oCalendar.SetDate(new DateTime(2023,7,4))
	dnAssert("not a leap year",substr(oFacts.Text,"Leap year: no") > 0,True)
	dnAssert("quarter 3",substr(oFacts.Text,"Quarter: 3") > 0,True)
	dnAssert("weekday",substr(oFacts.Text,"Tuesday") > 0,True)
