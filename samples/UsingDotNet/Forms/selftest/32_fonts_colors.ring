# the checks of 32_fonts_colors.ring: run with  ring 32_fonts_colors.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("font name",oForm.Controls.Item(1).Font.Name,"Consolas")
	dnAssert("bold",oBold.Font.Bold,1)
	dnAssert("color",oBold.ForeColor.Name,"DarkRed")
