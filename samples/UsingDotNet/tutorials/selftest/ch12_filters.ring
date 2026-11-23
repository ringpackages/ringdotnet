# the checks of ch12_filters.ring: run with  ring ch12_filters.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	applyFilter("Gray")
	lGray = True
	for aRow in aResult
		for aPixel in aRow
			if aPixel[1] != aPixel[2] or aPixel[2] != aPixel[3]
				lGray = False
			ok
		next
	next
	dnAssert("gray: red, green and blue are equal",lGray,True)
	applyFilter("Invert")
	dnAssert("invert: the sky red channel",aResult[1][1][1],255 - aSource[1][1][1])
	applyFilter("Brighter")
	dnAssert("brighter never goes over 255",clamp(250 + 40),255)
	dnAssert("the white sun cannot get brighter",aResult[1][1][3] <= 255,True)
	applyFilter("Blur")
	dnAssert("blur keeps the size",len(aResult) = C_HEIGHT and len(aResult[1]) = C_WIDTH,True)
	applyFilter("Edges")
	dnAssert("a flat area has no edge",aResult[85][5][1],0)
	dnAssert("the house wall has an edge",aResult[60][20][1] > 0 or aResult[60][19][1] > 0,True)
	applyFilter("Original")
	dnAssert("original is unchanged",aResult[1][1][1],aSource[1][1][1])
	dnAssert("the picture box shows a bitmap of the right size",oAfter.Image.Width = C_WIDTH and oAfter.Image.Height = C_HEIGHT,True)
	oColor = oAfter.Image.GetPixel(94,22)
	dnAssert("the sun was written to the file correctly (red)",oColor.R,255)
	dnAssert("the sun was written to the file correctly (blue)",oColor.B,0)
