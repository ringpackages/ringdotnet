# the checks of ch10_paint.ring: run with  ring ch10_paint.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	# a new canvas is white
	dnAssert("white at the start",oBitmap.GetPixel(100,100).Name,"ffffffff")

	# a stroke from (50,100) to (150,100): the mouse goes down, moves in steps and goes up
	mouseDown(50,100)
	for nX = 60 to 150 step 10
		mouseMove(nX,100)
	next
	mouseUp()
	dnAssert("black in the middle",oBitmap.GetPixel(100,100).Name,"ff000000")
	dnAssert("white above",oBitmap.GetPixel(100,80).Name,"ffffffff")
	dnAssert("one stroke",nStrokes,1)

	# moving with the button up draws nothing
	mouseMove(200,200)
	mouseMove(250,200)
	dnAssert("no line without the button",oBitmap.GetPixel(225,200).Name,"ffffffff")

	# a click without a move leaves a dot, in another color and a thick pen
	setColor("Red")
	nPenSize = 12
	mouseDown(300,150)
	mouseUp()
	dnAssert("a red dot",oBitmap.GetPixel(300,150).Name,"ffff0000")
	dnAssert("two strokes",nStrokes,2)

	# the picture can be saved
	cFile = new Path().Combine([ new Path().GetTempPath(),"ringdotnet-paint.png" ])
	oBitmap.Save([ :filename = cFile, :format = new ImageFormat().Png ])
	dnAssert("the file has data",new FileInfo(cFile).Length > 0,True)
	new File().Delete(cFile)

	# clear: white again
	clearCanvas()
	dnAssert("white after clear",oBitmap.GetPixel(100,100).Name,"ffffffff")
	dnAssert("no strokes after clear",nStrokes,0)
