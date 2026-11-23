# the checks of TemperatureConverter.ring: run with  ring TemperatureConverter.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("20 C in F",oFahrenheit.Text,"68")
	dnAssert("20 C in K",oKelvin.Text,"293.15")
	oCelsius.Text = "100"
	dnAssert("100 C in F",oFahrenheit.Text,"212")
	oFahrenheit.Text = "32"
	dnAssert("32 F in C",oCelsius.Text,"0")
	oKelvin.Text = "0"
	dnAssert("0 K in C",oCelsius.Text,"-273.15")
	oCelsius.Text = "abc"
	dnAssert("invalid text is ignored",oFahrenheit.Text,"-459.67")
