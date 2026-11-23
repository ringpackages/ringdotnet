# the checks of EpochTime.ring: run with  ring EpochTime.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oEpoch.Text = "0"
	epochToDate()
	dnAssert("epoch 0",oUtc.Text,"1970-01-01 00:00:00")
	oEpoch.Text = "1700000000"
	epochToDate()
	dnAssert("known epoch",oUtc.Text,"2023-11-14 22:13:20")
	dnAssert("local time is filled",len(oLocal.Text),19)
	oUtc.Text = "2000-01-01 00:00:00"
	dateToEpoch()
	dnAssert("date to epoch",oEpoch.Text,"946684800")
	oUtc.Text = "not a date"
	dateToEpoch()
	dnAssert("invalid date message",left(oMessage.Text,12),"Invalid date")
	oEpoch.Text = "abc"
	epochToDate()
	dnAssert("invalid epoch message",oMessage.Text,"Invalid epoch value")
	showNow()
	dnAssert("now is after 2024",number(oEpoch.Text) > 1704067200,True)
