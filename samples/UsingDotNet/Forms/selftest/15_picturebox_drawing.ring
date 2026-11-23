# the checks of 15_picturebox_drawing.ring: run with  ring 15_picturebox_drawing.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	dnAssert("rectangle",oCanvas.pixel(60,50),"ff4682b4")
	dnAssert("circle",oCanvas.pixel(200,70),"ffffa500")
	dnAssert("background",oCanvas.pixel(5,5),"ffffffff")
