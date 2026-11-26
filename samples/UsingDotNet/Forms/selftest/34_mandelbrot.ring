# the checks of 34_mandelbrot.ring: run with  ring 34_mandelbrot.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	# the steps of a few points: c = 0 never leaves the circle, c = 1 leaves after 3 steps, c = 2 after 2, c = -2 is on the border and stays
	dnAssert("the point 0 is in the set",escapeSteps(0,0),nMaxSteps)
	dnAssert("the point -1 is in the set (it goes back and forth between -1 and 0)",escapeSteps(-1,0),nMaxSteps)
	dnAssert("the point -2 stays on the real axis between -2 and 2: it is in the set",escapeSteps(-2,0),nMaxSteps)
	dnAssert("the point 1 leaves after 3 steps",escapeSteps(1,0),3)
	dnAssert("the point 2 leaves after 2 steps",escapeSteps(2,0),2)
	dnAssert("the point 0.5 + 0.5i leaves after 5 steps",escapeSteps(0.5,0.5),5)
	dnAssert("the point -0.75 + 0.1i is near the neck of the set: many steps",escapeSteps(-0.75,0.1) > 20,1)

	# before the click nothing is computed
	dnAssert("no color is computed before the click",len(cPixels),0)
	dnAssert("the palette has a color for each number of steps",len(aPalette),nMaxSteps)
	dnAssert("a color of the palette is 3 bytes",len(aPalette[1]),3)

	oButton.PerformClick()
	dnAssert("the colors of the pixels are computed: 3 bytes for each pixel",len(cPixels),nWidth * nHeight * 3)
	dnAssert("the status gives both times",left(oStatus.Text,12),"Computed in ")
	dnAssert("the button offers another drawing",oButton.Text,"Draw again")
	dnAssert("the button is ready again",oButton.Enabled,1)

	# the set is black: the middle of the main cardioid (c = 0, the pixel for x = 0 is at 2.2 / 3.2 of the width) and the picture has the colors outside of it
	nCenterColumn = floor(nWidth * 2.2 / 3.2)
	nCenterRow = floor(nHeight / 2)
	dnAssert("the middle of the main cardioid is black",oCanvas.pixel(nCenterColumn,nCenterRow),"ff000000")
	dnAssert("the left of the picture (c = -2.2) is outside of the set: not black",oCanvas.pixel(0,nCenterRow) != "ff000000",1)
	dnAssert("the top left corner is outside of the set: not black",oCanvas.pixel(0,0) != "ff000000",1)

	# the picture is symmetric about the real axis (the middle row): a pixel and its mirror have the same color
	lSymmetric = 1
	for nColumn = 0 to nWidth - 1 step 7
		for nRow = 0 to nHeight / 2 - 1 step 5
			if oCanvas.pixel(nColumn,nRow) != oCanvas.pixel(nColumn,nHeight - 1 - nRow)
				lSymmetric = 0
			ok
		next
	next
	dnAssert("the picture is symmetric about the real axis",lSymmetric,1)

	# the set covers about a fifth of this view (the area of the set is 1.5066, the view is 3.2 x 2.4)
	nShare = nInside / (nWidth * nHeight)
	dnAssert("the set covers about 20 percent of the picture",nShare > 0.17 and nShare < 0.24,1)

	# the bytes of the drawn picture are the computed colors: the pixel of the first row and column
	dnAssert("the first pixel drawn is the first computed color",oCanvas.pixel(0,0),"ff" + twoDigits(cPixels[1]) + twoDigits(cPixels[2]) + twoDigits(cPixels[3]))

# a byte as two hexadecimal digits in lower case
func twoDigits cByte

	return lower(right("0" + hex(ascii(cByte)),2))
