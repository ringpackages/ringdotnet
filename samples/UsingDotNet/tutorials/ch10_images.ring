# images - create, draw, read pixels, resize, convert to gray and save (no window needed)
#   ring ch10_images.ring [output folder]
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Drawing.Imaging"
}

func main

	cFolder = new Path().GetTempPath()
	if len(sysargv) >= 3 and left(sysargv[3],2) != "--"           # an option such as --selftest is not a folder
		cFolder = sysargv[3]
		new Directory().CreateDirectory(cFolder)
	ok

	# STEP 1. A bitmap is a rectangle of pixels. Graphics draws on it.
	oBitmap = new Bitmap(240,160)
	oGraphics = new Graphics().FromImage(oBitmap)
	oGraphics.Clear(new Color().White)

	# STEP 2. Draw: brushes fill, pens draw lines
	oBlue = new SolidBrush(new Color().SteelBlue)
	oOrange = new SolidBrush(new Color().Orange)
	oGraphics.FillRectangle([ :brush = oBlue, :rect = new Rectangle(10,10,100,60) ])
	oGraphics.FillEllipse([ :brush = oOrange, :rect = new Rectangle(130,20,90,90) ])
	oPen = new Pen(new Color().Black) {
		Width = 3
	}
	oGraphics.DrawLine([ :pen = oPen, :pt1 = new Point(10,130), :pt2 = new Point(230,90) ])
	oFont = new Font("Segoe UI",14)
	oGraphics.DrawString([ :s = "Hello, image", :font = oFont, :brush = new SolidBrush(new Color().Black), :point = new PointF(12,112) ])
	oGraphics.Dispose()
	? "STEP 2: drew a rectangle, a circle, a line and a text on a " + oBitmap.Width + " x " + oBitmap.Height + " bitmap"

	# STEP 3. Read pixels: GetPixel gives a color
	oPixel = oBitmap.GetPixel(50,40)
	? "STEP 3: pixel (50,40) is R=" + oPixel.R + " G=" + oPixel.G + " B=" + oPixel.B + " (steel blue)"
	? "        pixel (5,5) is  " + oBitmap.GetPixel(5,5).Name + " (white, with alpha ff in front)"

	# STEP 4. Save: the file type is chosen by the format
	cPng = new Path().Combine([cFolder,"ringdotnet_images.png"])
	oBitmap.Save([ :filename = cPng, :format = new ImageFormat().Png ])
	? "STEP 4: saved " + new Path().GetFileName(cPng) + ", " + (new FileInfo(cPng).Length > 0) + " (the file has data)"

	# STEP 5. Load it again and make a gray copy: gray = the average of red, green and blue
	oLoaded = (new Bitmap).@New([ :filename = cPng ])  # a constructor chosen by the name of its parameter
	oGray = new Bitmap(oLoaded.Width,oLoaded.Height)
	for nY = 0 to oLoaded.Height - 1
		for nX = 0 to oLoaded.Width - 1
			oColor = oLoaded.GetPixel(nX,nY)
			nGray = floor((oColor.R + oColor.G + oColor.B) / 3)
			oGray.SetPixel(nX,nY,new Color().FromArgb([ :red = nGray, :green = nGray, :blue = nGray ]))
		next
	next
	cGray = new Path().Combine([cFolder,"ringdotnet_images-gray.png"])
	oGray.Save([ :filename = cGray, :format = new ImageFormat().Png ])
	? "STEP 5: gray copy made, pixel (50,40) is now " + oGray.GetPixel(50,40).R + " in all three channels"

	# STEP 6. Resize: draw the image smaller on a new bitmap
	oSmall = new Bitmap(120,80)
	oSmallGraphics = new Graphics().FromImage(oSmall)
	oSmallGraphics.DrawImage([ :image = oLoaded, :rect = new Rectangle(0,0,120,80) ])
	oSmallGraphics.Dispose()
	cSmall = new Path().Combine([cFolder,"ringdotnet_images-small.png"])
	oSmall.Save([ :filename = cSmall, :format = new ImageFormat().Png ])
	? "STEP 6: resized copy is " + oSmall.Width + " x " + oSmall.Height

	# release the files, remove the temporary ones
	oBitmap.Dispose()
	oLoaded.Dispose()
	oGray.Dispose()
	oSmall.Dispose()
	if not (len(sysargv) >= 3 and left(sysargv[3],2) != "--")      # no output folder was given: remove the files
		new File().Delete(cPng)
		new File().Delete(cGray)
		new File().Delete(cSmall)
	ok
