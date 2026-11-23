# the checks of 25_maskedtextbox.ring: run with  ring 25_maskedtextbox.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oPhone.Text = "5551234567"
	dnAssert("phone",oPhone.Text,"(555) 123-4567")
	dnAssert("complete",oPhone.MaskCompleted,1)
	dnAssert("date incomplete",oDate.MaskCompleted,0)
