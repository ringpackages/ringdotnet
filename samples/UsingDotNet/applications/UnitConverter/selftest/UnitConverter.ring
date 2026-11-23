# the checks of UnitConverter.ring: run with  ring UnitConverter.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("default is meter to kilometer",oFormula.Text,"1 Meter = 0.001 Kilometer")
	oValue.Text = "5"
	oTo.SelectedIndex = 4
	dnAssert("5 m in miles",oResult.Text,"0.003107")
	oCategory.SelectedIndex = 3
	dnAssert("units follow the category",oFrom.Items.Count,3)
	oValue.Text = "100"
	oFrom.SelectedIndex = 0
	oTo.SelectedIndex = 1
	dnAssert("100 C in F",oResult.Text,"212")
	oTo.SelectedIndex = 2
	dnAssert("100 C in K",oResult.Text,"373.15")
	oCategory.SelectedIndex = 1
	oValue.Text = "2"
	oFrom.SelectedIndex = 3
	oTo.SelectedIndex = 0
	dnAssert("2 lb in kg",oResult.Text,"0.907185")
	oValue.Text = "abc"
	dnAssert("invalid input clears the result",oResult.Text,"")
