# A color wheel drawn pixel by pixel on a bitmap when the button is clicked: first the color of every pixel is computed, then the pixels are drawn (the RingQt sample
# ColorWheel). A call into .NET costs several microseconds, so the whole picture is drawn with one call: one text of 3 bytes for each pixel.
# Run it with --draw to draw without a click.

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

nSize = 300                    # the bitmap is nSize x nSize pixels
nRadius = nSize / 2
nPi = 3.14159265359
cPixels = ""                   # the computed colors of the picture: the bytes red, green, blue for each pixel, row after row
nComputeTime = 0
nDrawTime = 0

oForm = uiForm("Color wheel",nSize + 20,nSize + 100)
oPicture = uiPictureBox(oForm,10,10,nSize,nSize)
oButton = uiButton(oForm,"Draw",10,nSize + 20,nSize,32,"startDraw()")
oStatus = uiLabel(oForm,"",10,nSize + 62,nSize,20)
oCanvas = new UiCanvas(oPicture)
oCanvas.clear("White")
if find(sysargv,"--draw") > 0
	startDraw()
ok

uiRun(oForm)

# --------------------------------------------------------------------------

# The click of the button: clear the picture, compute the color of every pixel, then draw them
func startDraw

	oCanvas.clear("White")
	nStart = clock()
	computeWheel()
	nComputeTime = (clock() - nStart) / clockspersecond()
	nStart = clock()
	drawWheel()
	nDrawTime = (clock() - nStart) / clockspersecond()
	oStatus.Text = "Computed in " + (floor(nComputeTime * 100) / 100) + " s, drawn in " + (floor(nDrawTime * 1000) / 1000) + " s"
	oButton.Text = "Draw again"

# The color of every pixel, row after row: the hue is the angle around the center, the saturation is the distance from it. A pixel outside of the wheel is white.
func computeWheel

	cPixels = ""
	cWhite = char(255) + char(255) + char(255)
	for nRow = 1 to nSize
		nY = nRow - nRadius
		nYSquared = nY * nY
		cLine = ""
		for nCol = 1 to nSize
			nX = nCol - nRadius
			nSaturation = sqrt(nX * nX + nYSquared) / nRadius
			if nSaturation <= 1
				nHue = (atan2(nX,nY) + nPi) / (2 * nPi)
				cLine += hsvToBytes(nHue,nSaturation)
			else
				cLine += cWhite
			ok
		next
		cPixels += cLine
	next

# Draw the computed colors, all in one call, and show the picture once
func drawWheel

	oCanvas.setPixels(0,0,nSize,nSize,cPixels)
	oCanvas.show()

# The color of a hue and a saturation (0 to 1) at full brightness, as the 3 bytes red, green, blue (a text, not a list: no list is made for each pixel)
func hsvToBytes nHue, nSaturation

	nSector = floor(nHue * 6)
	nFraction = nHue * 6 - nSector
	nP = floor((1 - nSaturation) * 255 + 0.5)
	nQ = floor((1 - nSaturation * nFraction) * 255 + 0.5)
	nT = floor((1 - nSaturation * (1 - nFraction)) * 255 + 0.5)
	switch nSector % 6
	on 0
		return char(255) + char(nT) + char(nP)
	on 1
		return char(nQ) + char(255) + char(nP)
	on 2
		return char(nP) + char(255) + char(nT)
	on 3
		return char(nP) + char(nQ) + char(255)
	on 4
		return char(nT) + char(nP) + char(255)
	off
	return char(255) + char(nP) + char(nQ)
