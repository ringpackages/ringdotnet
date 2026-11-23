# the checks of LoanCalculator.ring: run with  ring LoanCalculator.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	calculate()
	dnAssert("known payment",oPayment.Text,"Monthly payment: 386.66")
	dnAssert("total interest",oInterest.Text,"Total interest: 3199.36")
	dnAssert("12 rows shown",oTable.Items.Count,12)
	dnAssert("first month interest",oTable.Items.Item(0).SubItems.Item(2).Text,"100")
	oRate.Text = "0"
	calculate()
	dnAssert("no interest",oPayment.Text,"Monthly payment: 333.33")
	oAmount.Text = "-5"
	calculate()
	dnAssert("invalid input",oPayment.Text,"Check the input")
	dnAssert("annuity formula",floor(monthlyPayment(1000,12,1) * 100),8884)
