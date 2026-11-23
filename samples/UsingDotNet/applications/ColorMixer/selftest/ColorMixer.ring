# the checks of ColorMixer.ring: run with  ring ColorMixer.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	aBars[1].Value = 255
	aBars[2].Value = 0
	aBars[3].Value = 0
	dnAssert("red hex",oHex.Text,"#FF0000")
	dnAssert("swatch color",oSwatch.BackColor.ToArgb(),-65536)
	dnAssert("red hue",left(oHsv.Text,3),"H 0")
	aBars[1].Value = 0
	aBars[2].Value = 128
	aBars[3].Value = 255
	dnAssert("mixed hex",oHex.Text,"#0080FF")
	dnAssert("value label",aValues[2].Text,"128")
	aBars[1].Value = 10
	aBars[2].Value = 10
	aBars[3].Value = 10
	dnAssert("dark gray",oHex.Text,"#0A0A0A")
	randomColor()
	dnAssert("random color has a code",len(oHex.Text),7)
