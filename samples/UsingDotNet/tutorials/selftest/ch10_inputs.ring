# the checks of ch10_inputs.ring: run with  ring ch10_inputs.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	# the starting state
	dnAssert("price at the start",oPrice.Text,"3 nights, Single: 210 (a week or more: 10 percent off)")

	# a track bar and a radio button change the price
	oNights.Value = 7
	dnAssert("track bar label",oNightsLabel.Text,"7")
	dnAssert("a week is cheaper",total(),441)                  # 7 x 70 = 490, 10 percent off
	oDouble.Checked = True
	dnAssert("only one room",oSingle.Checked,False)
	dnAssert("double for a week",total(),693)

	# without a name there is an error marker, and no booking
	oBook.PerformClick()
	dnAssert("error message",oErrors.GetError(oName),"Please type a name")
	dnAssert("no booking yet",oResult.Text,"")

	# with a name the marker goes away
	oName.Text = "Ann"
	oBook.PerformClick()
	dnAssert("no error",oErrors.GetError(oName),"")
	dnAssert("booked",oResult.Text,"Booked for Ann: arrival 10 May 2030, 693")

	# the date picker keeps its limits
	oDate.Value = new DateTime(2030,12,31)
	dnAssert("the last day",oDate.Value.Format("yyyy-MM-dd"),"2030-12-31")
