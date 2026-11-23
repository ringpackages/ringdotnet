# the checks of WpfColorMixer.ring: run with  ring WpfColorMixer.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	aSliders[1].Value = 255
	aSliders[2].Value = 0
	aSliders[3].Value = 0
	dnAssert("red code",oCode.Content,"#FF0000")
	dnAssert("value label",aValues[1].Content,"255")
	aSliders[1].Value = 0
	aSliders[2].Value = 128
	aSliders[3].Value = 255
	dnAssert("mixed code",oCode.Content,"#0080FF")
	dnAssert("the swatch brush",oSwatch.Fill.Color.ToString(),"#FF0080FF")
	dnAssert("the swatch is rendered with the color",wpfPixel(oSwatch,100,80,50,40),"ff0080ff")
