# the checks of 33_color_wheel.ring: run with  ring 33_color_wheel.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	# before the click nothing is drawn
	dnAssert("no color is computed before the click",len(cPixels),0)
	dnAssert("the picture is blank: a point of the rim is white",oCanvas.pixel(285,150),"ffffffff")
	dnAssert("the button says Draw",oButton.Text,"Draw")

	# the click computes the colors and draws them
	oButton.PerformClick()
	dnAssert("the colors of the pixels are computed: 3 bytes for each of the 300 x 300 pixels",len(cPixels),270000)
	dnAssert("the time of the computing is known",nComputeTime > 0,1)
	dnAssert("the time of the drawing is known",nDrawTime > 0,1)
	dnAssert("the status gives both times",left(oStatus.Text,12),"Computed in ")
	dnAssert("the button offers another drawing",oButton.Text,"Draw again")
	dnAssert("the center is white (no saturation)",oCanvas.pixel(149,149),"ffffffff")
	dnAssert("a corner is outside of the wheel: the background",oCanvas.pixel(0,0),"ffffffff")
	cRight = oCanvas.pixel(285,150)
	cLeft = oCanvas.pixel(15,150)
	cTop = oCanvas.pixel(150,15)
	cBottom = oCanvas.pixel(150,285)
	dnAssert("a point of the rim has a color",cRight != "ffffffff",1)
	dnAssert("the left and the right of the wheel have other colors",cRight != cLeft,1)
	dnAssert("the top and the bottom have other colors",cTop != cBottom,1)
	dnAssert("the four points have four colors",len(removeDuplicates([cRight,cLeft,cTop,cBottom])),4)
	dnAssert("the hue of the right (3/4 of the way round) is violet: more blue than green",dec(substr(cRight,7,2)) > dec(substr(cRight,5,2)),1)
	dnAssert("the drawing is fast: much less than the time of one setPixel call for each pixel (70679 pixels, 12 microseconds each)",nDrawTime < 0.5,1)

	# a second click draws it again, with the same colors
	oButton.PerformClick()
	dnAssert("the second click draws the same wheel",oCanvas.pixel(285,150),cRight)

func removeDuplicates aList

	aOut = []
	for cItem in aList
		if find(aOut,cItem) = 0
			aOut + cItem
		ok
	next
	return aOut
