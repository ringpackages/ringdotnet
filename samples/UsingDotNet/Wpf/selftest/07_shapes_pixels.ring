# the checks of 07_shapes_pixels.ring: run with  ring 07_shapes_pixels.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("rectangle",wpfPixel(oCanvas,200,120,40,30),"ff4682b4")
