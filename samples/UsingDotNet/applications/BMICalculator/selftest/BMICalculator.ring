# the checks of BMICalculator.ring: run with  ring BMICalculator.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	dnAssert("category underweight",category(17),"Underweight")
	dnAssert("category normal",category(22),"Normal weight")
	dnAssert("category overweight",category(27),"Overweight")
	dnAssert("category obese",category(35),"Obese")
	oWeight.Text = "70"
	oHeight.Text = "175"
	calculate()
	dnAssert("metric BMI",oBmi.Text,"BMI 22.9")
	dnAssert("metric category",oCategory.Text,"Normal weight")
	oUnits.SelectedIndex = 1
	dnAssert("labels follow the units",oWeightLabel.Text,"Weight (lb)")
	oWeight.Text = "220"
	oHeight.Text = "70"
	calculate()
	dnAssert("imperial BMI",oBmi.Text,"BMI 31.6")
	dnAssert("imperial category",oCategory.Text,"Obese")
	dnAssert("history",oHistory.Items.Count,2)
	oWeight.Text = ""
	calculate()
	dnAssert("empty input",oBmi.Text,"Enter a weight and a height")
