# the checks of ImageViewer.ring: run with  ring ImageViewer.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	# make a small picture: red on the left half, blue on the right half
	oSample = new Bitmap(40,20)
	for nY = 0 to 19
		for nX = 0 to 39
			if nX < 20
				oSample.SetPixel(nX,nY,uiColor("Red"))
			else
				oSample.SetPixel(nX,nY,uiColor("Blue"))
			ok
		next
	next
	cFile = new Path().Combine([new Path().GetTempPath(),"imageviewer_selftest.png"])
	oSample.Save([ :filename = cFile, :format = new ImageFormat().Png ])
	loadFile(cFile)
	dnAssert("loaded size",oInfoText.Text,"40 x 20   zoom 100%")
	dnAssert("title",oForm.Text,"imageviewer_selftest.png - Image viewer")
	dnAssert("left is red",oImage.GetPixel(5,5).Name,"ffff0000")
	flip()
	dnAssert("flipped: left is blue",oImage.GetPixel(5,5).Name,"ff0000ff")
	rotate()
	dnAssert("rotated size",oInfoText.Text,"20 x 40   zoom 100%")
	grayscale()
	oGray = oImage.GetPixel(5,5)
	dnAssert("gray has equal channels",oGray.R = oGray.G and oGray.G = oGray.B,True)
	zoomBy(50)
	dnAssert("zoom",nZoom,150)
	zoomBy(-500)
	dnAssert("zoom has a minimum",nZoom,25)
	cOut = new Path().Combine([new Path().GetTempPath(),"imageviewer_saved.png"])
	saveTo(cOut)
	dnAssert("saved",new File().Exists(cOut),True)
	oBox.Image = dnNull()
	oImage.Dispose()
	new File().Delete(cFile)
	new File().Delete(cOut)
