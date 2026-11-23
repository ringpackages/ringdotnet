# an image filter lab - pixels as numbers, filters as small functions, a BMP file written by hand, before and after side by side
load "dotnet.ring"

using {
	"System.IO"
	"System.Drawing"
	"System.Windows.Forms"
}

C_WIDTH = 120
C_HEIGHT = 90

oForm = ""
oBefore = ""
oAfter = ""
oInfo = ""
aSource = []              # the pixels of the original: aSource[y][x] = [red, green, blue]
aResult = []
cFolder = ""
nFile = 0

func main

	oForm = uiForm("Filter lab",C_WIDTH * 2 + 60,C_HEIGHT + 190)
	oBefore = uiPictureBox(oForm,10,10,C_WIDTH,C_HEIGHT)
	oAfter = uiPictureBox(oForm,C_WIDTH + 40,10,C_WIDTH,C_HEIGHT)
	uiLabel(oForm,"Original",10,C_HEIGHT + 14,100,20)
	uiLabel(oForm,"Result",C_WIDTH + 40,C_HEIGHT + 14,100,20)
	aNames = ["Gray","Invert","Brighter","Darker","Sepia","Blur","Edges","Original"]
	for nIndex = 1 to len(aNames)
		nColumn = (nIndex - 1) % 4
		nRow = floor((nIndex - 1) / 4)
		uiButton(oForm,aNames[nIndex],10 + nColumn * 62,C_HEIGHT + 44 + nRow * 32,58,28,"applyFilter('" + aNames[nIndex] + "')")
	next
	oInfo = uiLabel(oForm,"",10,C_HEIGHT + 112,C_WIDTH * 2 + 30,22)
	cFolder = new Path().Combine([new Path().GetTempPath(),"ringdotnet_filters"])
	new Directory().CreateDirectory(cFolder)
	makeSource()
	applyFilter("Original")
	uiRun(oForm)
	try
		new Directory().Delete([ :path = cFolder, :recursive = True ])     # the pictures were only needed while the window was open
	catch
	done

# ---------------------------------------------------------------- pixels <-> Ring lists

# A picture to work on, made of numbers: a sky that gets lighter near the horizon, a sun, a hill and a house
func makeSource

	aSource = []
	for nY = 1 to C_HEIGHT
		aRow = []
		for nX = 1 to C_WIDTH
			aRow + pictureColor(nX,nY)
		next
		aSource + aRow
	next

func pictureColor nX, nY

	aColor = [110,170,255 - floor(nY * 90 / C_HEIGHT)]                                    # sky
	if (nX - 94) * (nX - 94) + (nY - 22) * (nY - 22) <= 196                              # sun: a circle of radius 14
		aColor = [255,215,0]
	ok
	if nY >= 62                                                                           # grass
		aColor = [34,139,34]
	ok
	if nX >= 20 and nX < 60 and nY >= 40 and nY < 72                                      # house wall
		aColor = [178,34,34]
	ok
	if nY >= 18 and nY < 40 and fabs(nX - 40) <= (nY - 18) * 24 / 22                    # roof: a triangle with its top at (40, 18)
		aColor = [47,79,79]
	ok
	if nX >= 34 and nX < 46 and nY >= 52 and nY < 72                                      # door
		aColor = [139,69,19]
	ok
	return aColor

# A BMP file is simple: a 54 byte header, then the pixels row by row, from the bottom row up, each pixel as blue, green, red.
# (A row must be a multiple of 4 bytes long: 120 pixels * 3 = 360 is.) .NET reads it with Bitmap.
func saveBmp aPixels, cFile

	nSize = 54 + C_WIDTH * C_HEIGHT * 3
	cData = "BM" + le32(nSize) + le32(0) + le32(54)                                        # file header: 14 bytes
	cData += le32(40) + le32(C_WIDTH) + le32(C_HEIGHT) + le16(1) + le16(24) + le32(0)     # picture header: 40 bytes
	cData += le32(C_WIDTH * C_HEIGHT * 3) + le32(2835) + le32(2835) + le32(0) + le32(0)
	for nY = C_HEIGHT to 1 step -1
		for aPixel in aPixels[nY]
			cData += char(aPixel[3]) + char(aPixel[2]) + char(aPixel[1])
		next
	next
	write(cFile,cData)

# numbers as little-endian bytes (the least significant byte first)
func le32 nValue

	return char(nValue % 256) + char(floor(nValue / 256) % 256) + char(floor(nValue / 65536) % 256) + char(floor(nValue / 16777216) % 256)

func le16 nValue

	return char(nValue % 256) + char(floor(nValue / 256) % 256)

# ---------------------------------------------------------------- the filters: each one makes a new list of rows from the old one

# a value kept between 0 and 255 (a color channel cannot be outside)
func clamp nValue

	if nValue < 0
		return 0
	but nValue > 255
		return 255
	ok
	return floor(nValue)

# apply cFunction to every pixel: the function gets [r,g,b] and returns [r,g,b]
func mapPixels aPixels, cFunction

	aRows = []
	for aRow in aPixels
		aNew = []
		for aPixel in aRow
			aNew + call cFunction(aPixel)
		next
		aRows + aNew
	next
	return aRows

func grayPixel aPixel

	nGray = floor(aPixel[1] * 0.299 + aPixel[2] * 0.587 + aPixel[3] * 0.114)      # the eye sees green brighter than blue
	return [nGray,nGray,nGray]

func invertPixel aPixel

	return [255 - aPixel[1],255 - aPixel[2],255 - aPixel[3]]

func brighterPixel aPixel

	return [clamp(aPixel[1] + 40),clamp(aPixel[2] + 40),clamp(aPixel[3] + 40)]

func darkerPixel aPixel

	return [clamp(aPixel[1] - 40),clamp(aPixel[2] - 40),clamp(aPixel[3] - 40)]

func sepiaPixel aPixel

	nRed = aPixel[1]
	nGreen = aPixel[2]
	nBlue = aPixel[3]
	return [clamp(nRed * 0.393 + nGreen * 0.769 + nBlue * 0.189),clamp(nRed * 0.349 + nGreen * 0.686 + nBlue * 0.168),clamp(nRed * 0.272 + nGreen * 0.534 + nBlue * 0.131)]

# blur: every pixel becomes the average of itself and its 8 neighbors (at the border: only the neighbors that exist)
func blur aPixels

	aRows = []
	for nY = 1 to C_HEIGHT
		aNew = []
		for nX = 1 to C_WIDTH
			nRed = 0
			nGreen = 0
			nBlue = 0
			nCount = 0
			for nDY = -1 to 1
				for nDX = -1 to 1
					nNY = nY + nDY
					nNX = nX + nDX
					if nNY >= 1 and nNY <= C_HEIGHT and nNX >= 1 and nNX <= C_WIDTH
						nRed += aPixels[nNY][nNX][1]
						nGreen += aPixels[nNY][nNX][2]
						nBlue += aPixels[nNY][nNX][3]
						nCount++
					ok
				next
			next
			aNew + [floor(nRed / nCount),floor(nGreen / nCount),floor(nBlue / nCount)]
		next
		aRows + aNew
	next
	return aRows

# edges: the difference between a pixel and its right and lower neighbor; flat areas become black, borders light
func edges aPixels

	aGray = mapPixels(aPixels,"grayPixel")
	aRows = []
	for nY = 1 to C_HEIGHT
		aNew = []
		for nX = 1 to C_WIDTH
			nRight = aGray[nY][min(nX + 1,C_WIDTH)][1]
			nDown = aGray[min(nY + 1,C_HEIGHT)][nX][1]
			nHere = aGray[nY][nX][1]
			nEdge = clamp(fabs(nHere - nRight) * 4 + fabs(nHere - nDown) * 4)
			aNew + [nEdge,nEdge,nEdge]
		next
		aRows + aNew
	next
	return aRows

# ---------------------------------------------------------------- the window

func applyFilter cName

	switch cName
	on "Gray"
		aResult = mapPixels(aSource,"grayPixel")
	on "Invert"
		aResult = mapPixels(aSource,"invertPixel")
	on "Brighter"
		aResult = mapPixels(aSource,"brighterPixel")
	on "Darker"
		aResult = mapPixels(aSource,"darkerPixel")
	on "Sepia"
		aResult = mapPixels(aSource,"sepiaPixel")
	on "Blur"
		aResult = blur(aSource)
	on "Edges"
		aResult = edges(aSource)
	other
		aResult = aSource
	off
	showPixels(oBefore,aSource)
	showPixels(oAfter,aResult)
	oInfo.Text = "Filter: " + cName

# save the pixels as a BMP file (a new name each time: a file that is shown is locked) and give the picture box that image
func showPixels oPicture, aPixels

	nFile++
	cFile = new Path().Combine([cFolder,"image" + nFile + ".bmp"])
	saveBmp(aPixels,cFile)
	oPicture.Image = dnNew("Bitmap",[ :filename = cFile ])
