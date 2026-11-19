# the checks of main.ring: run with  ring main.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	# a stroke from (50,50) to (150,50), then a red dot
	mouseDown(50,50)
	mouseMove(100,50)
	mouseMove(150,50)
	lDrawing = false
	dnAssert("black line in the middle",oCanvas.pixel(100,50),"ff000000")
	dnAssert("white outside the line",oCanvas.pixel(100,90),"ffffffff")
	cColor = "Red"
	nPenSize = 10
	mouseDown(300,200)
	lDrawing = false
	dnAssert("red dot",oCanvas.pixel(300,200),"ffff0000")
	# buttons change the color: the 2nd swatch is red, the 3rd green
	oForm.Controls.Item(3).PerformClick()
	dnAssert("swatch sets the color",cColor,"Green")
	oSize.Value = 12
	dnAssert("pen size from the track bar value",oSize.Value,12)
	cFile = new Path().Combine([new Path().GetTempPath(),"paint_selftest.png"])
	saveTo(cFile)
	dnAssert("picture saved",new File().Exists(cFile),True)
	dnAssert("PNG signature",substr(new File().ReadAllBytes(cFile),"PNG") > 0,True)
	new File().Delete(cFile)
	clearCanvas()
	dnAssert("cleared",oCanvas.pixel(100,50),"ffffffff")
