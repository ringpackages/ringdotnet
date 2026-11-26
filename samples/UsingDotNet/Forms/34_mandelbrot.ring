# The Mandelbrot set drawn pixel by pixel when the button is clicked: each pixel is a point c of the complex plane, and its color is the number of steps that
# z = z * z + c takes to leave the circle of radius 2 (black for a point that never does). The colors are computed first, then the whole picture is drawn with one call.
# Run it with --draw to draw without a click.

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

nWidth = 320                   # the bitmap is nWidth x nHeight pixels
nHeight = 240
nLeft = -2.2                   # the part of the plane that the picture shows
nRight = 1.0
nTop = 1.2
nBottom = -1.2
nMaxSteps = 80                 # a point that has not left the circle after this many steps is in the set
aPalette = []                  # the 3 bytes (red, green, blue) of each number of steps
cPixels = ""                   # the computed colors of the picture: the bytes red, green, blue for each pixel, row after row
nInside = 0                    # the pixels that are in the set
nComputeTime = 0
nDrawTime = 0

oForm = uiForm("Mandelbrot",nWidth + 20,nHeight + 100)
oPicture = uiPictureBox(oForm,10,10,nWidth,nHeight)
oButton = uiButton(oForm,"Draw",10,nHeight + 20,nWidth,32,"startDraw()")
oStatus = uiLabel(oForm,"",10,nHeight + 62,nWidth,20)
oCanvas = new UiCanvas(oPicture)
oCanvas.clear("Black")
makePalette()
if find(sysargv,"--draw") > 0
	startDraw()
ok

uiRun(oForm)

# --------------------------------------------------------------------------

# The click of the button: compute the color of every pixel, then draw them
func startDraw

	oButton.Enabled = False
	nStart = clock()
	computeMandelbrot()
	nComputeTime = (clock() - nStart) / clockspersecond()
	nStart = clock()
	oCanvas.setPixels(0,0,nWidth,nHeight,cPixels)
	oCanvas.show()
	nDrawTime = (clock() - nStart) / clockspersecond()
	oForm.Text = "Mandelbrot"
	oStatus.Text = "Computed in " + (floor(nComputeTime * 100) / 100) + " s, drawn in " + (floor(nDrawTime * 1000) / 1000) + " s"
	oButton.Text = "Draw again"
	oButton.Enabled = True

# The color of every pixel, row after row
func computeMandelbrot

	cPixels = ""
	nInside = 0
	nStepX = (nRight - nLeft) / nWidth
	nStepY = (nTop - nBottom) / nHeight
	cBlack = char(0) + char(0) + char(0)
	for nRow = 1 to nHeight
		nY = nTop - (nRow - 0.5) * nStepY
		nYSquared = nY * nY
		cLine = ""
		for nCol = 1 to nWidth
			nX = nLeft + (nCol - 0.5) * nStepX
			# the main cardioid and the disc on its left are in the set: they need no steps (most of the work of the picture would be there)
			nQ = (nX - 0.25) * (nX - 0.25) + nYSquared
			if nQ * (nQ + (nX - 0.25)) < 0.25 * nYSquared or (nX + 1) * (nX + 1) + nYSquared < 0.0625
				nSteps = nMaxSteps
			else
				nSteps = escapeSteps(nX,nY)
			ok
			if nSteps >= nMaxSteps
				nInside++
				cLine += cBlack
			else
				cLine += aPalette[nSteps + 1]
			ok
		next
		cPixels += cLine
		if nRow % 20 = 0
			oForm.Text = "Computing " + floor(nRow * 100 / nHeight) + "%"
			new Application().DoEvents()          # the window stays alive while the colors are computed
		ok
	next

# The number of steps of z = z * z + c before z leaves the circle of radius 2 (nMaxSteps when it does not)
func escapeSteps nCr, nCi

	nZr = 0
	nZi = 0
	for nStep = 0 to nMaxSteps - 1
		nZr2 = nZr * nZr
		nZi2 = nZi * nZi
		if nZr2 + nZi2 > 4
			return nStep
		ok
		nZi = 2 * nZr * nZi + nCi
		nZr = nZr2 - nZi2 + nCr
	next
	return nMaxSteps

# The colors for 0 to nMaxSteps - 1 steps: the hue goes round the color wheel as the number of steps grows
func makePalette

	aPalette = []
	for nSteps = 0 to nMaxSteps - 1
		nHue = (0.6 + nSteps * 0.035) % 1
		aRGB = hsvToRgb(nHue,0.85)
		aPalette + (char(aRGB[1]) + char(aRGB[2]) + char(aRGB[3]))
	next

# The color of a hue and a saturation (0 to 1) at full brightness: [red, green, blue] from 0 to 255
func hsvToRgb nHue, nSaturation

	nSector = floor(nHue * 6)
	nFraction = nHue * 6 - nSector
	nP = floor((1 - nSaturation) * 255 + 0.5)
	nQ = floor((1 - nSaturation * nFraction) * 255 + 0.5)
	nT = floor((1 - nSaturation * (1 - nFraction)) * 255 + 0.5)
	switch nSector % 6
	on 0
		return [255,nT,nP]
	on 1
		return [nQ,255,nP]
	on 2
		return [nP,255,nT]
	on 3
		return [nP,nQ,255]
	on 4
		return [nT,nP,255]
	off
	return [255,nP,nQ]
