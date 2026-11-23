# the checks of ch10_chart.ring: run with  ring ch10_chart.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	dnAssert("the biggest value",maxOf(aValues),25)
	dnAssert("round axis for 25",niceMax(25),30)
	dnAssert("round axis for 8",niceMax(8),8)
	dnAssert("round axis for 120",niceMax(120),150)
	# the chart is really drawn: the April bar (the biggest) is crimson, and the background is white
	dnAssert("white background",oCanvas.pixel(5,5),"ffffffff")
	nSlot = (C_WIDTH - 20 - 50) / 6
	nAprilX = floor(50 + 3 * nSlot + nSlot / 2)          # pixel positions are whole numbers
	dnAssert("the April bar is crimson",oCanvas.pixel(nAprilX,C_HEIGHT - 60),"ffdc143c")
	# save it
	cFile = new Path().Combine([new Path().GetTempPath(),"sales-chart-test.png"])
	oCanvas.oBitmap.Save([ :filename = cFile, :format = new ImageFormat().Png ])
	dnAssert("the file was saved",new File().Exists(cFile),True)
	new File().Delete(cFile)
