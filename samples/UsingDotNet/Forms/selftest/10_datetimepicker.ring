# the checks of 10_datetimepicker.ring: run with  ring 10_datetimepicker.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oDate = new DateTime(2024,12,25)
	oPicker.Value = oDate
	dnAssert("weekday",oDay.Text,"Wednesday, day 360 of the year")
