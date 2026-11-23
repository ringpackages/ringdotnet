# the checks of ch10_registration.ring: run with  ring ch10_registration.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oForm.Controls.Item(7).PerformClick()                 # nothing typed yet
	dnAssert("name is required",oResult.Text,"Please type a name")
	oName.Text = "Ann"
	oForm.Controls.Item(7).PerformClick()
	dnAssert("country is required",oResult.Text,"Please choose a country")
	oCountry.SelectedIndex = 1
	oNewsletter.Checked = True
	oForm.Controls.Item(7).PerformClick()
	dnAssert("registered",oResult.Text,"Registered: Ann")
	dnAssert("the list",oPeople.Items.Count,1)
	dnAssert("the text",oPeople.Items.Item(0),"Ann, 30, Norway (newsletter)")
